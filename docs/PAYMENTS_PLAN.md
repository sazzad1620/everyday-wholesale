# Stripe Payments — Plan & Status

Sub-plan for [PLAN.md](PLAN.md) Phase 6. Payments are a large, multi-part addition (a new Cloud Functions backend, a client SDK, a schema change, and UI on both the customer and admin side), so it gets its own doc and its own phased checklist rather than one flat bullet list in the main plan. Update **§4 (Roadmap & Status)** here as work lands, and check off Phase 6 in `PLAN.md` only once this whole doc is done.

## 1. Scope

Real online card payment for checkout, replacing the current mock "place order with a placeholder payment method" flow. Cash-on-delivery / any non-card method is out of scope — the client requirement is Stripe-only online payment (see `PLAN.md` §2.3), and the current checkout UI never offered an alternative method anyway.

## 2. Key decisions

| Decision | Choice | Why |
|---|---|---|
| Payment UI, mobile | `flutter_stripe`'s native **PaymentSheet** | Handles card entry, 3D Secure/SCA, and Apple Pay/Google Pay with almost no custom UI; the standard integration path on iOS/Android. |
| Payment UI, Web | `flutter_stripe`'s **CardField** (Stripe.js under the hood) | PaymentSheet isn't available on Flutter Web — `flutter_stripe` only exposes the lower-level card element there. Checkout branches by platform (`kIsWeb`) to pick the right widget; both funnel into the same "confirm payment" step behind one abstraction so the rest of the flow (bloc, order writing) doesn't know which UI was used. |
| Order → "paid" confirmation | **Stripe webhook → Cloud Function** | Authoritative and robust: the write to `orders.paymentStatus` happens because Stripe confirms the charge, not because the app happened to still be open. Avoids a stuck "pending" order if the app is closed/killed right after payment. Needs one public HTTPS Cloud Function endpoint and a webhook signing secret. |
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
```

Two Cloud Functions total:
- `createPaymentIntent` — callable function (`cloud_functions` package calls it directly), holds the Stripe secret key.
- `stripeWebhook` — HTTPS function, public endpoint registered in the Stripe dashboard, verifies the webhook signing secret.

## 4. Schema changes

`orders/{orderId}` gains two fields (additive, no migration needed — old orders just read as `paymentStatus: undefined`, treated as `unpaid` by the fallback):
- `paymentStatus: 'unpaid' | 'paid' | 'failed'`
- `stripePaymentIntentId: string | null`

`OrderStatus` stays as today (`pending/completed/cancelled` — that's fulfillment status); `paymentStatus` is a separate, new concern and shouldn't be conflated with it.

Firestore rules: no client-side rule change needed for the webhook write path — Cloud Functions use the Admin SDK, which bypasses security rules entirely. Rules only need a narrow addition so a client can never set `paymentStatus`/`stripePaymentIntentId` itself on create (order creation already goes through `OrderRepository`, so this is a defense-in-depth check, not a functional requirement).

## 5. Environment & secrets (your action items, not code)

- [ ] Create/access a Stripe account, get the **test mode** publishable + secret keys
- [ ] `firebase functions:config:set stripe.secret=sk_test_...` (or Secret Manager, whichever the Functions setup below lands on) — the secret key never goes in client code or git
- [ ] After the webhook function is deployed once, register its URL in the Stripe dashboard and get the webhook signing secret; set that as a second Functions secret
- [ ] Add the **publishable** key to the Flutter app config (safe to be public, but still not hardcoded inline — goes through the same config pattern as other build-time values)

## 6. Roadmap & Status

### Phase A — Cloud Functions backend ⬜
- [ ] `functions/` directory, TypeScript, Firebase Functions v2, Stripe Node SDK
- [ ] `createPaymentIntent` callable — validates the caller is signed in and owns the order, creates the PaymentIntent, writes `stripePaymentIntentId` onto the order, returns `client_secret`
- [ ] `stripeWebhook` HTTPS function — signature verification, handles `payment_intent.succeeded` and `payment_intent.payment_failed`, updates the order doc
- [ ] Deploy, register webhook URL + secret in Stripe dashboard

### Phase B — Client payment flow ⬜
- [ ] Add `flutter_stripe` + `cloud_functions` (already planned) dependencies
- [ ] `PaymentRepository`/`PaymentRemoteDatasource` (new `payment` feature or folded into `order`) wrapping the `createPaymentIntent` call and the platform-specific confirm step
- [ ] `CheckoutBloc` updated: create order → get PaymentIntent → confirm payment → listen for the order's `paymentStatus` to flip
- [ ] Replace the placeholder `PaymentMethodCard` with the real card entry UI (`PaymentSheet` trigger on mobile, `CardField` on Web)
- [ ] `OrderConfirmationPage` reflects real payment state (processing / paid / failed), not an immediate assumed success

### Phase C — Order status & history UI ⬜
- [ ] Order history (customer) and admin order list both show `paymentStatus` alongside fulfillment `status`
- [ ] Failed payment → order stays visible with a retry-payment action (re-run Phase B's flow against the same order rather than creating a duplicate)

### Phase D — Admin visibility ⬜
- [ ] Admin order card/detail shows payment status + Stripe PaymentIntent id (read-only, for support/lookup)
- [ ] No refund UI in this first pass — refunds happen in the Stripe dashboard directly for now; revisit if the client asks for in-app refunds

### Phase E — Polish & production readiness ⬜
- [ ] Switch from Stripe test keys to live keys (client's own Stripe account, live mode)
- [ ] Manual end-to-end test: real card (or Stripe test card) on Android, iOS, and Web
- [ ] `flutter analyze` / `flutter test` clean, Functions deploy verified
