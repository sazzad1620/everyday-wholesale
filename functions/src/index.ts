import {initializeApp} from "firebase-admin/app";
import {getFirestore} from "firebase-admin/firestore";
import {logger} from "firebase-functions";
import {defineSecret} from "firebase-functions/params";
import {setGlobalOptions} from "firebase-functions/v2";
import {HttpsError, onCall, onRequest} from "firebase-functions/v2/https";
import {onSchedule} from "firebase-functions/v2/scheduler";
import Stripe from "stripe";

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
        await db
          .collection("orders")
          .doc(orderId)
          .update(
            succeeded ?
              {paymentStatus: "paid"} :
              // A failed charge means this order will never be fulfilled as
              // placed — auto-cancel it rather than leaving a phantom
              // pending order nobody will ever pay for. Fulfillment `status`
              // is otherwise untouched by a successful payment; that stays
              // `pending` until an admin actually starts processing it.
              {paymentStatus: "failed", status: "cancelled"}
          );
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
