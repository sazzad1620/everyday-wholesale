# Stripe Payments — Plan & Status

Sub-plan for [PLAN.md](PLAN.md) Phase 6. Payments are a large, multi-part addition (a new Cloud Functions backend, a client SDK, a schema change, and UI on both the customer and admin side), so it gets its own doc and its own phased checklist rather than one flat bullet list in the main plan. Update **§4 (Roadmap & Status)** here as work lands, and check off Phase 6 in `PLAN.md` only once this whole doc is done.

## 1. Scope

Real online card payment for checkout, replacing the current mock "place order with a placeholder payment method" flow. Cash-on-delivery / any non-card method is out of scope — the client requirement is Stripe-only online payment (see `PLAN.md` §2.3), and the current checkout UI never offered an alternative method anyway.

## 2. Key decisions

| Decision | Choice | Why |
|---|---|---|
| Payment UI, mobile | `flutter_stripe`'s native **PaymentSheet** | Handles card entry, 3D Secure/SCA, and Apple Pay/Google Pay with almost no custom UI; the standard integration path on iOS/Android. |
| Payment UI, Web | `flutter_stripe`'s **CardField** (Stripe.js under the hood) | PaymentSheet isn't available on Flutter Web — `flutter_stripe` only exposes the lower-level card element there. Checkout branches by platform (`kIsWeb`) to pick the right widget; both funnel into the same "confirm payment" step behind one abstraction so the rest of the flow (bloc, order writing) doesn't know which UI was used. |
| Order → "paid" confirmation | **Stripe webhook → Cloud Function**, plus a scheduled reconciliation sweep as a safety net | Authoritative and robust: the write to `orders.paymentStatus` happens because Stripe confirms the charge, not because the app happened to still be open. Avoids a stuck "pending" order if the app is closed/killed right after payment. Needs one public HTTPS Cloud Function endpoint and a webhook signing secret. But making the webhook the *only* path is itself a single point of failure — a bug, a misconfigured signing secret, or exhausted Stripe retries would leave an order stuck showing "processing" forever with a customer who's already been charged, and nothing in the app would ever detect or fix it. A scheduled function (`reconcilePendingPayments`) closes that gap independently of both the webhook and the client, so it still self-heals even if the customer closed the app right after paying. |
| Cloud Functions language | **Node.js / TypeScript** | Stripe's own SDK and nearly every Firebase+Stripe reference/example is Node — fastest to get right, most to reference if something breaks. This is a new `functions/` directory (none exists yet). |
| Currency handling | Integers throughout, **no ×100 conversion** | JPY is a zero-decimal currency in Stripe's API — amounts are passed as whole yen, matching how the app already stores `total` as an `int` (see `formatYen`). |

## 3. Architecture

```
Customer taps "Place Order" on Checkout
        │
        ▼
1. CheckoutBloc creates the order doc first
   status: pending, paymentStatus: unpaid
        │
        ▼
2. Client calls Cloud Function `createPaymentIntent`
   (via `cloud_functions`) with {orderId, amount}
        │
        ▼
3. Function creates a Stripe PaymentIntent (secret key
   lives only here), tags it metadata.orderId, saves
   stripePaymentIntentId back onto the order doc,
   returns the client_secret
        │
        ▼
4. Client confirms payment:
     - Mobile: flutter_stripe PaymentSheet
     - Web: flutter_stripe CardField + confirmPayment
        │
        ▼
5a. Success in-app → show order confirmation          5b. Stripe sends `payment_intent.succeeded` /
    immediately (optimistic UI only, NOT what              `.payment_failed` to the `stripeWebhook`
    flips the authoritative status)                        Cloud Function
        │                                                        │
        ▼                                                        ▼
   Order screen shows "processing" until the           Function verifies the Stripe signature, looks
   webhook-driven status arrives (Firestore             up the order by metadata.orderId, writes
   listener on the order doc, not a one-shot read)      paymentStatus: paid/failed + status accordingly
                                                                         │
                                                          (safety net, runs independently
                                                           of both the webhook and the
                                                           client — see below)
                                                                         ▼
                                                    6. reconcilePendingPayments (scheduled, every
                                                       5 min) finds any order still `unpaid` more
                                                       than 5 min after its PaymentIntent was
                                                       created, asks Stripe directly what actually
                                                       happened, and self-heals if the webhook
                                                       missed it
```

Three Cloud Functions total:
- `createPaymentIntent` — callable function (`cloud_functions` package calls it directly), holds the Stripe secret key.
- `stripeWebhook` — HTTPS function, public endpoint registered in the Stripe dashboard, verifies the webhook signing secret.
- `reconcilePendingPayments` — scheduled function (`onSchedule`, every 5 minutes), the reconciliation safety net described above. Not on the customer-facing critical path at all — it only ever matters when something else already went wrong.

## 4. Schema changes

`orders/{orderId}` gains two fields (additive, no migration needed — old orders just read as `paymentStatus: undefined`, treated as `unpaid` by the fallback):
- `paymentStatus: 'unpaid' | 'paid' | 'failed'`
- `stripePaymentIntentId: string | null`

`OrderStatus` stays as today (`pending/processing/completed/cancelled` — that's fulfillment status); `paymentStatus` is a separate, new concern and shouldn't be conflated with it.

Firestore rules: no client-side rule change needed for the webhook write path — Cloud Functions use the Admin SDK, which bypasses security rules entirely. Rules only need a narrow addition so a client can never set `paymentStatus`/`stripePaymentIntentId` itself on create (order creation already goes through `OrderRepository`, so this is a defense-in-depth check, not a functional requirement).

## 5. Environment & secrets (your action items, not code)

- [x] Create/access a Stripe account, get the **test mode** publishable + secret keys — done via Stripe's "Test mode" (not the newer "Sandboxes" — simpler, no separate environment to manage for a one-developer project)
- [x] `firebase functions:secrets:set STRIPE_SECRET_KEY` — done, set from your test secret key
- [x] Registered `https://asia-northeast1-everyday-wholesale.cloudfunctions.net/stripeWebhook` in the Stripe dashboard as an event destination ("Everyday Wholesale — order payment webhook (test)"), scoped to **Your account** (not Connected accounts — this app isn't a Stripe Connect platform), listening to `payment_intent.succeeded` and `payment_intent.payment_failed`. Ran `firebase functions:secrets:set STRIPE_WEBHOOK_SECRET` with the real `whsec_...` signing secret it produced
- [ ] Add the **publishable** key to the Flutter app config (safe to be public, but still not hardcoded inline — goes through the same config pattern as other build-time values) — this happens in Phase B, not needed yet

## 6. Roadmap & Status

### Phase A — Cloud Functions backend ✅ done
- [x] `functions/` directory, TypeScript (5.7, deliberately not the brand-new 7.x line — no need to be first movers on a payment backend's toolchain), Firebase Functions v2, Stripe Node SDK (`firebase-admin` 14, `firebase-functions` 7, `stripe` 22 — all current stable as of setup). Root `firebase.json` gained a `functions` block (source dir + `npm run build` predeploy) and `firestore`/`storage` rule-file references it didn't have before (harmless — CLI already used the standalone rules files by convention, this just makes it explicit so `firebase deploy` knows about them too); new `.firebaserc` pins the CLI to the `everyday-wholesale` project (didn't exist before — only `flutterfire configure`'s app registration existed, not a CLI project alias)
- [x] `createPaymentIntent` callable — validates the caller is signed in and owns the order (`order.customerId == request.auth.uid`), reads the charge amount from the order doc itself rather than trusting the client's request (so a tampered client can't change what gets charged), creates the PaymentIntent, writes `stripePaymentIntentId` onto the order, returns `client_secret`
- [x] `stripeWebhook` HTTPS function — signature verification via `stripe.webhooks.constructEvent` against `req.rawBody`, handles `payment_intent.succeeded` (→ `paymentStatus: paid`) and `payment_intent.payment_failed` (→ `paymentStatus: failed` **and** `status: cancelled` — a failed charge means the order as placed will never be fulfilled, so it auto-cancels rather than leaving a phantom `pending` order nobody will ever pay for; a successful payment deliberately leaves fulfillment `status` untouched — that only advances when an admin actually starts processing it)
- [x] Both secrets (`STRIPE_SECRET_KEY`, `STRIPE_WEBHOOK_SECRET`) wired via `defineSecret` (2nd-gen Secret Manager, not the deprecated `functions:config:set` — resolves the "whichever the Functions setup lands on" open question from §5)
- [x] **`reconcilePendingPayments`** — scheduled function (every 5 min) added after review flagged that a webhook-only design is a single point of failure: it queries for orders still `paymentStatus: unpaid` more than 5 minutes after their `stripePaymentIntentId` was set, asks Stripe directly (`paymentIntents.retrieve`) what actually happened, and self-heals — `succeeded` → `paymentStatus: paid` (logged as a warning, since it means the webhook missed something worth investigating); `canceled`/`requires_payment_method` this long after creation → treated as abandoned, same cleanup as an explicit failure (`paymentStatus: failed`, `status: cancelled`). Runs independently of the webhook and the client, so it still catches a stuck order even if the customer closed the app right after paying — the one scenario the webhook-as-authority design was specifically chosen to protect against, now actually covered end-to-end
- [x] `npm install` + `npm run build` (`tsc`) verified clean locally
- [x] Deployed all three functions to `everyday-wholesale` — along the way: bumped the runtime from Node 20 (flagged deprecated mid-deploy, decommissioning 2026-10-30) to Node 22; set `STRIPE_WEBHOOK_SECRET` to a throwaway placeholder value first since Secret Manager requires a secret to already exist before a function referencing it can deploy at all, and the *real* signing secret only exists after Stripe sees this deployed function's URL (resolved by the retry loop this phase always intended — deploy once now with a placeholder, deploy `stripeWebhook` again once the real secret is set); also hit and fixed a "backend discovery timeout" (`FUNCTIONS_DISCOVERY_TIMEOUT=30` env var, a documented Firebase CLI workaround)
- [x] **Region fixed: `asia-northeast1`, not the default `us-central1`** — caught before the webhook URL was ever registered anywhere, which mattered: region is part of a function's URL, so fixing it later would have meant redoing the Stripe registration. `firebase firestore:databases:get` confirmed Firestore itself already lives in `asia-northeast1` (Tokyo, matching the actual userbase); every one of these three functions reads/writes Firestore on nearly every invocation, so a mismatched region meant paying an unnecessary cross-Pacific round trip on every call. Fixed with one `setGlobalOptions({region: "asia-northeast1"})` covering all three functions rather than repeating it per-function. Redeployed with `--force`, which cleanly deleted all three `us-central1` originals as part of the same deploy (confirmed via `firebase functions:list` — nothing left in `us-central1`) and auto-configured the same 1-day image-cleanup policy for the new region
- [x] `createPaymentIntent`, `stripeWebhook`, `reconcilePendingPayments` all live in `asia-northeast1` only — deployed function URL: `https://asia-northeast1-everyday-wholesale.cloudfunctions.net/stripeWebhook`
- [x] Webhook registered in Stripe, real signing secret set, `stripeWebhook` redeployed onto it — the CLI's own "1 functions are using stale version of secret" prompt handled the redeploy; the old placeholder version didn't auto-destroy as promised, cleaned it up manually with `firebase functions:secrets:destroy STRIPE_WEBHOOK_SECRET@1 --force`. Verified end-to-end rather than just trusting the deploy log: `curl`ing the endpoint bare returns 400 "Missing Stripe signature" (function is up), and with a fake `stripe-signature` header returns 400 "Invalid signature" specifically — meaning it got past the header check and successfully read *both* secrets from Secret Manager to attempt real verification, rather than erroring on a missing/destroyed value. Phase A is fully done.

### Phase B — Client payment flow ✅ done
- [x] Scope correction before writing any code: the plan originally assumed Card would be the checkout's only payment method, but `checkout_page.dart` already had a working Cash-on-Delivery vs. Card picker (`PaymentMethodOption`/`showPaymentMethodSheet`) — confirmed with the user, kept both, only Card got wired to Stripe
- [x] Added `flutter_stripe` (14.0.0) + `cloud_functions` dependencies. Hit a real packaging bug: `flutter_stripe` 14.0.0's `pubspec.yaml` declares its web platform's `default_package` as `stripe_web`, but never actually depends on it — and `stripe_web` on pub.dev is an unrelated, abandoned, pre-null-safety package anyway. The real web implementation is `flutter_stripe_web` (8.2.0); had to add it explicitly ourselves. Without it, no web plugin implementation gets registered at all, and `Stripe.instance.applySettings()` silently hangs `main()` before `runApp()` ever runs — Flutter boots the engine (semantics scaffolding appears) but never paints a frame. Worth remembering if `flutter_stripe` ever bumps its web version again.
- [x] New `payment` feature: `PaymentRepository`/`PaymentRemoteDatasource` wrapping the `createPaymentIntent` callable, `CreatePaymentIntentUseCase`. Same bounded-timeout pattern as the COD fix (15s → `ServerException`/`ServerFailure`), applied from the start rather than retrofitted.
- [x] `OrderEntity` gained `paymentStatus`/`stripePaymentIntentId`; `OrderRepository.watchOrder` (new `WatchOrderUseCase`, the codebase's first `Stream`-returning usecase) added for the confirmation page's live status.
- [x] `CheckoutBloc` rewritten: Cash keeps its exact original behavior (place → clear cart → done). Card creates the order the same way, then calls `createPaymentIntent`, emits the client secret, and the page presents the payment UI; a `CheckoutPaymentCanceled` event resets the spinner silently (no error toast) so retrying re-uses the same order/`_order` field instead of creating a duplicate.
- [x] Real card entry UI: native `PaymentSheet` on mobile; `CardField` + `confirmPayment` in a bottom sheet (`CardPaymentSheet`) on Web, since `flutter_stripe`'s web SDK doesn't support `PaymentSheet`.
- [x] `OrderConfirmationPage` rewritten to reflect live payment state via `OrderConfirmationBloc` (`emit.forEach` over `watchOrder`) — processing/paid/failed icons and copy. Found and fixed a real bug here during verification: the page originally decided "is this a card order" from `order.stripePaymentIntentId`, but that field is only populated server-side and the client's in-memory order is never refreshed with it — so the live-watch path never actually triggered. Fixed by passing `isCardOrder` explicitly through navigation (`OrderConfirmationArgs`) instead of inferring it from a stale field.
- [x] `firestore.rules`: `orders` create now requires `paymentStatus == 'unpaid' && stripePaymentIntentId == null` — payment fields must start clean; only the webhook/reconciliation functions (Admin SDK, bypasses rules) ever advance them. **Not yet deployed** — deploying rules is a separate explicit step.
- [x] Verified end-to-end in the browser with a real test card (`4242 4242 4242 4242`, ¥2,474 JPY): PaymentIntent created, card confirmed client-side, Stripe dashboard shows the charge **Succeeded**, `stripeWebhook` processed it with no errors, and Firestore's order doc flipped to `paymentStatus: paid`.

### Phase C — Order status & history UI ✅ done
- [x] New `PaymentStatusPill` (`order/presentation/widgets/payment_status_pill.dart`) — always read-only, unlike the fulfillment-status pill, since `paymentStatus` must only ever move via the webhook/reconciliation function, never a manual UI override (admin included). Wired into customer order history + detail and admin order list + detail, everywhere `OrderStatusPill` already was.
- [x] Cash on Delivery orders get their own distinct `CodPaymentPill` rather than sharing the amber "unpaid" color with a stuck card payment — a card order sitting `unpaid` usually signals a real problem, while COD is expected to sit unpaid until delivery; conflating the two would bury real stuck-payment signals under normal COD traffic.
- [x] Admin order list gained a payment-status filter (All/Unpaid/Paid/Failed chips) — client-side over the already-fetched list, no bloc/usecase change needed. COD orders count toward "Unpaid" (they genuinely haven't been paid yet) but never toward "Paid"/"Failed", which only ever describe a real Stripe charge outcome.
- [x] Retry-payment action (`RetryPaymentButton`, `payment/presentation/widgets/`) — customer-only (retrying needs their own card, so admin never gets this), shown only when `paymentStatus == failed`, deliberately never for plain `unpaid` (which can just mean "still processing" — offering retry there would risk a double-charge race if the original charge and a retry both eventually succeed). Reuses the exact `CreatePaymentIntentUseCase` → `confirmCardPayment` flow from checkout; on success, navigates to the existing `OrderConfirmationPage` (live payment-status watch) instead of building a second live-status view.
- [x] `PaymentStatusPill` softens a fresh `unpaid` card order into a neutral "Processing" label for 5 minutes after `createdAt`, instead of the same amber "UNPAID" a genuinely stuck order gets — admin's order list is a one-time fetch, not a live listener, so without this an admin refreshing mid-checkout would see a brand-new, perfectly normal order rendered identically to an actually-stuck one. 5 minutes deliberately matches `reconcilePendingPayments`'s own stuck-order threshold, so "still amber" and "the backend would also consider this stuck" stay the same moment.

### Phase D — Admin visibility ✅ done
- [x] Admin order detail shows the Stripe PaymentIntent id as a tap-to-copy row (`OrderDetailContent`'s new `showPaymentIntentId` flag, admin-only — the customer detail page never passes it, since a raw Stripe reference means nothing to a customer). List view intentionally excludes it — a lookup aid for one order at a time, not something needed at a glance across many.
- [x] No refund UI — left entirely out of scope, as planned; refunds stay a manual Stripe-dashboard action.

### Phase E — Polish & production readiness ⬜
- [ ] Switch from Stripe test keys to live keys (client's own Stripe account, live mode)
- [ ] Manual end-to-end test: real card (or Stripe test card) on Android, iOS, and Web
- [ ] `flutter analyze` / `flutter test` clean, Functions deploy verified
