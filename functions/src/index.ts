import {initializeApp} from "firebase-admin/app";
import {FieldValue, getFirestore, Timestamp} from "firebase-admin/firestore";
import {getMessaging, Message} from "firebase-admin/messaging";
import {logger} from "firebase-functions";
import {defineSecret} from "firebase-functions/params";
import {setGlobalOptions} from "firebase-functions/v2";
import {HttpsError, onCall, onRequest} from "firebase-functions/v2/https";
import {onSchedule} from "firebase-functions/v2/scheduler";
import Stripe from "stripe";

import {seoHandlers} from "./seo/handlers";

initializeApp();
const db = getFirestore();

// Matches Firestore's own location for this project (`asia-northeast1` —
// Tokyo, the userbase's actual region) rather than the `us-central1`
// default. Every one of these functions reads/writes Firestore on nearly
// every invocation, so a mismatched region would mean paying a real,
// unnecessary cross-Pacific round trip on every call.
setGlobalOptions({region: "asia-northeast1"});

// Set via `firebase functions:secrets:set STRIPE_SECRET_KEY` (and the
// webhook one below) — see docs/PAYMENTS_PLAN.md §5. Never hardcoded, never
// committed; Secret Manager is the 2nd-gen replacement for the old
// `functions:config:set`, which callable/HTTPS functions here don't use.
const stripeSecretKey = defineSecret("STRIPE_SECRET_KEY");
const stripeWebhookSecret = defineSecret("STRIPE_WEBHOOK_SECRET");

function stripeClient(): Stripe {
  return new Stripe(stripeSecretKey.value());
}

/**
 * Creates a Stripe PaymentIntent for an order the client already wrote to
 * Firestore (via the app's normal `OrderRepository.placeOrder`), and saves
 * its id back onto that order doc. The charge amount is read from the order
 * itself — never trusted from the client's request — so a tampered client
 * can't change what actually gets charged.
 */
export const createPaymentIntent = onCall(
  {secrets: [stripeSecretKey]},
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Sign in required.");
    }

    const orderId = request.data?.orderId;
    if (typeof orderId !== "string" || orderId.length === 0) {
      throw new HttpsError("invalid-argument", "orderId is required.");
    }

    const orderRef = db.collection("orders").doc(orderId);
    const orderSnap = await orderRef.get();
    if (!orderSnap.exists) {
      throw new HttpsError("not-found", "Order not found.");
    }

    const order = orderSnap.data()!;
    if (order.customerId !== request.auth.uid) {
      throw new HttpsError("permission-denied", "You do not own this order.");
    }

    const amount = order.total;
    if (typeof amount !== "number" || amount <= 0) {
      throw new HttpsError("failed-precondition", "Order has no valid total.");
    }

    // JPY is a zero-decimal currency in Stripe's API — the integer yen
    // amount is passed as-is, no ×100 conversion (matches how the app
    // already stores `total`, see PAYMENTS_PLAN.md §2).
    const paymentIntent = await stripeClient().paymentIntents.create({
      amount,
      currency: "jpy",
      metadata: {orderId},
    });

    await orderRef.update({stripePaymentIntentId: paymentIntent.id});

    return {clientSecret: paymentIntent.client_secret};
  }
);

/**
 * Stripe calls this directly (its URL is registered in the Stripe
 * dashboard, not called by the app) once a PaymentIntent resolves. This —
 * not the client's own optimistic post-payment UI — is the authoritative
 * source of truth for `orders.paymentStatus`, so a killed app or a dropped
 * connection right after payment can never leave an order stuck unpaid
 * despite a real, successful charge.
 */
export const stripeWebhook = onRequest(
  {secrets: [stripeSecretKey, stripeWebhookSecret]},
  async (req, res) => {
    const signature = req.headers["stripe-signature"];
    if (typeof signature !== "string") {
      res.status(400).send("Missing Stripe signature.");
      return;
    }

    let event: Stripe.Event;
    try {
      event = stripeClient().webhooks.constructEvent(
        req.rawBody,
        signature,
        stripeWebhookSecret.value()
      );
    } catch (error) {
      logger.error("Stripe webhook signature verification failed", error);
      res.status(400).send("Invalid signature.");
      return;
    }

    if (
      event.type === "payment_intent.succeeded" ||
      event.type === "payment_intent.payment_failed"
    ) {
      const paymentIntent = event.data.object as Stripe.PaymentIntent;
      const orderId = paymentIntent.metadata?.orderId;

      if (orderId) {
        const succeeded = event.type === "payment_intent.succeeded";
        const orderRef = db.collection("orders").doc(orderId);
        await db.runTransaction(async (tx) => {
          const order = (await tx.get(orderRef)).data();

          if (succeeded) {
            // Fulfillment `status` is otherwise untouched by a successful
            // payment; that stays `pending` until an admin actually starts
            // processing it. The one exception: an order a *previous failed
            // attempt* auto-cancelled (see below) that the customer then paid
            // successfully in the same sheet — revive it, or it would sit
            // paid-but-cancelled and never get fulfilled. Only when the
            // cancellation came from the failed payment (`paymentStatus` is
            // still `failed`), never an order an admin cancelled by hand.
            const revive =
              order?.status === "cancelled" && order?.paymentStatus === "failed";
            tx.update(
              orderRef,
              revive ?
                {paymentStatus: "paid", status: "pending"} :
                {paymentStatus: "paid"}
            );
          } else if (order?.paymentStatus !== "paid") {
            // A failed charge means this order will never be fulfilled as
            // placed — auto-cancel it rather than leaving a phantom pending
            // order nobody will ever pay for. Skipped if the order is
            // already paid: Stripe doesn't guarantee delivery order, so a
            // late `payment_failed` from an earlier attempt must never
            // overwrite a payment that has since succeeded.
            tx.update(orderRef, {paymentStatus: "failed", status: "cancelled"});
          }
        });
      } else {
        logger.warn(
          `Stripe event ${event.id} (${event.type}) had no orderId in metadata.`
        );
      }
    }

    res.status(200).send();
  }
);

// An order sits here from the moment `createPaymentIntent` runs until the
// webhook resolves it — an order stuck at `unpaid` past this age is either
// still genuinely being paid, or the webhook missed it (bug, misconfigured
// secret, exhausted Stripe retries, transient outage). Long enough that a
// normal card confirmation never gets flagged, short enough that a real
// miss self-heals quickly instead of sitting stuck indefinitely.
const STALE_PAYMENT_THRESHOLD_MS = 5 * 60 * 1000;

/**
 * Safety net for `stripeWebhook`: the webhook is the fast path, but making
 * it the *only* path means a missed delivery leaves an order stuck showing
 * "processing" forever with a customer who may already have been charged —
 * the one outcome a payment flow can least afford. This runs independently
 * of both the webhook and the client (so it still catches a stuck order
 * even if the customer closed the app right after paying), asks Stripe
 * directly what actually happened, and reconciles.
 */
export const reconcilePendingPayments = onSchedule(
  {schedule: "every 5 minutes", secrets: [stripeSecretKey]},
  async () => {
    const snapshot = await db
      .collection("orders")
      .where("paymentStatus", "==", "unpaid")
      .get();

    if (snapshot.empty) return;

    const stripe = stripeClient();
    const now = Date.now();

    for (const doc of snapshot.docs) {
      const order = doc.data();
      const paymentIntentId = order.stripePaymentIntentId;
      // No PaymentIntent yet means the customer hasn't reached the payment
      // step at all — nothing to reconcile.
      if (typeof paymentIntentId !== "string") continue;

      const createdAtMillis = order.createdAt?.toMillis?.() ?? now;
      if (now - createdAtMillis < STALE_PAYMENT_THRESHOLD_MS) continue;

      try {
        const paymentIntent = await stripe.paymentIntents.retrieve(
          paymentIntentId
        );

        if (paymentIntent.status === "succeeded") {
          await doc.ref.update({paymentStatus: "paid"});
          logger.warn(
            `Reconciled order ${doc.id}: Stripe shows succeeded but the ` +
              "webhook never flipped it — check stripeWebhook's logs/config."
          );
        } else if (
          paymentIntent.status === "canceled" ||
          paymentIntent.status === "requires_payment_method"
        ) {
          // Stale and still unresolved this long after creation almost
          // always means the customer abandoned checkout — clean it up the
          // same way an explicit `payment_intent.payment_failed` would.
          await doc.ref.update({paymentStatus: "failed", status: "cancelled"});
        }
        // Any other status (e.g. still `processing` for a delayed payment
        // method) is genuinely unresolved — leave it for the next sweep.
      } catch (error) {
        logger.error(`Failed to reconcile order ${doc.id}`, error);
      }
    }
  }
);

interface LocalizedInput {
  en: string;
  ja: string;
}

/** Reads `{en, ja}` from untrusted callable data; `en` must be non-empty. */
function parseLocalized(raw: unknown, field: string, maxLength: number): LocalizedInput {
  const map = (raw ?? {}) as Record<string, unknown>;
  const en = typeof map.en === "string" ? map.en.trim() : "";
  const ja = typeof map.ja === "string" ? map.ja.trim() : "";
  if (en.length === 0) {
    throw new HttpsError("invalid-argument", `${field} (English) is required.`);
  }
  if (en.length > maxLength || ja.length > maxLength) {
    throw new HttpsError("invalid-argument", `${field} is too long.`);
  }
  return {en, ja};
}

/**
 * Admin-only: saves an offer to `offers/` and pushes it to every customer.
 * Devices subscribe to `all_en` or `all_ja` by app language (signed in or
 * not), so each language gets its own message; a blank Japanese text falls
 * back to English, same as the Offers page does.
 *
 * The offer is saved first and the push is best-effort — a messaging
 * outage must not lose the offer (it is still visible on the Offers page),
 * so a push failure is reported in the result instead of thrown.
 */
export const sendOffer = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Sign in required.");
  }
  const user = await db.collection("users").doc(request.auth.uid).get();
  if (user.data()?.role !== "admin") {
    throw new HttpsError("permission-denied", "Admins only.");
  }

  const title = parseLocalized(request.data?.title, "title", 100);
  const body = parseLocalized(request.data?.body, "body", 500);

  const imageUrl = request.data?.imageUrl;
  if (imageUrl != null && (typeof imageUrl !== "string" || !imageUrl.startsWith("https://"))) {
    throw new HttpsError("invalid-argument", "imageUrl must be an https URL.");
  }
  const expiresAtMillis = request.data?.expiresAtMillis;
  if (expiresAtMillis != null && typeof expiresAtMillis !== "number") {
    throw new HttpsError("invalid-argument", "expiresAtMillis must be a number.");
  }

  const offerRef = db.collection("offers").doc();
  await offerRef.set({
    title,
    body,
    createdAt: FieldValue.serverTimestamp(),
    ...(imageUrl ? {imageUrl} : {}),
    ...(expiresAtMillis ? {expiresAt: Timestamp.fromMillis(expiresAtMillis)} : {}),
  });

  const messaging = getMessaging();
  // Android gets a data-only message and the app draws the notification
  // itself (logo on the right, full text on expand, the offer's photo — if
  // any — as the expanded banner); that is the only way to get that layout,
  // since Firebase's own notification payload can only add a big picture.
  // iOS can't run app code for a closed app this way, so it gets a normal
  // alert that the system draws. An Android app build from before this
  // change ignores data-only messages, so it won't show offers.
  const messageFor = (topic: string, text: {title: string; body: string}): Message => ({
    topic,
    data: {
      type: "offer",
      offerId: offerRef.id,
      title: text.title,
      body: text.body,
      ...(imageUrl ? {imageUrl: String(imageUrl)} : {}),
    },
    android: {priority: "high", ttl: 24 * 60 * 60 * 1000},
    apns: {
      headers: {"apns-priority": "10"},
      payload: {aps: {alert: {title: text.title, body: text.body}, sound: "default"}},
    },
  });

  let pushed = true;
  try {
    await Promise.all([
      messaging.send(messageFor("all_en", {title: title.en, body: body.en})),
      messaging.send(
        messageFor("all_ja", {title: title.ja || title.en, body: body.ja || body.en})
      ),
    ]);
  } catch (error) {
    pushed = false;
    logger.error(`Offer ${offerRef.id} saved but the push failed`, error);
  }

  return {offerId: offerRef.id, pushed};
});

// Server-rendered storefront pages + sitemap for SEO and a fast first
// paint — see src/seo/render.ts and docs/WEB_PERFORMANCE.md (R3-4).
export const {ssr, sitemap} = seoHandlers(db);
