# Backend Setup Guide (Beginner-Friendly, A–Z)

Everyday Wholesale's entire backend runs on **Firebase** — Auth (email + phone login), Firestore (products, categories, orders, users), Cloud Storage (product images), and Cloud Functions (Stripe payments). One platform, one dashboard, one SDK family.

> **Revision note:** an earlier version of this guide split the backend across Firebase + Cloudinary + Netlify, specifically to avoid Firebase's paid **Blaze** plan (which needs a card). The project has since **upgraded to Blaze**, so that split is no longer needed — everything below consolidates into Firebase. See [PLAN.md §4.3](PLAN.md) for the full history of that decision.

> Companion docs: [PLAN.md](PLAN.md) (why these decisions, and §7 for what's actually built so far).

| Service | Handles | Status |
|---|---|---|
| Firebase Auth | Email/password, phone (SMS OTP), Google Sign-In | ✅ All three done — Part A (Google's iOS piece still blocked on Mac access) |
| Firestore | Products, categories, orders, users | 🚧 Database created, data models not built — Part A |
| Firebase Cloud Storage | Product images (admin-uploaded) | ⬜ Not started — Part B |
| Firebase Cloud Functions | Creating Stripe PaymentIntents securely | ⬜ Not started — Part C |

**One thing to know about Blaze:** the project's dashboard shows a **"Blaze | Free Trial, 89 days" credit** — this is a one-time Google Cloud bonus, separate from Firebase's normal ongoing free quotas (covered in the Free-tier summary at the end). Worth knowing it's temporary; normal Blaze free-quota rules apply afterward regardless.

---

## Part A — Firebase: Auth + Firestore

### Phase A0 — Before starting

- A Google account (personal or a dedicated business one — your call).
- [Node.js](https://nodejs.org/) installed (needed for the Firebase CLI).
- This repo checked out locally with Flutter working (`flutter doctor` clean).

### Phase A1 — Create the Firebase project (console)

**Status: ✅ done.**

1. [console.firebase.google.com](https://console.firebase.google.com) → **Add project** → name it → **Create project**.

### Phase A2 — Install the CLI tools (your machine, one-time)

**Status: ✅ done.**

```bash
npm install -g firebase-tools
```
```bash
firebase login
```
```bash
dart pub global activate flutterfire_cli
```

> **Windows note:** if PowerShell blocks these with a "running scripts is disabled" error, run `npm.cmd install ...` / `firebase.cmd login` instead, or fix it permanently with `Set-ExecutionPolicy -Scope CurrentUser RemoteSigned`.

### Phase A3 — Register the app platforms

**Status: ✅ done** — all three platforms registered, `lib/firebase_options.dart` generated.

```bash
flutterfire configure
```

Select **android, ios, web**. Package IDs are still the `com.example.everyday_wholesale` placeholders from `flutter create` — fine for development, just don't ship to app stores with them.

### Phase A4 — Wire Firebase into the app code (my part)

**Status: ✅ done** — `firebase_core`, `firebase_auth`, `cloud_firestore` added to `pubspec.yaml`; `Firebase.initializeApp()` wired into [lib/app/bootstrap.dart](../lib/app/bootstrap.dart); verified booting cleanly (all SDKs initialize, no console errors) on web. Android's Gradle plugin wiring was added automatically by `flutterfire configure`; iOS/Web needed no manual changes.

`firebase_storage` will be added in Part B, `cloud_functions` isn't needed client-side at all (Cloud Functions are called over plain HTTPS or the `cloud_functions` SDK — decided in Part C).

### Phase A5 — Enable Authentication (console)

**Status: ✅ done** — Email/Password enabled. Phone sign-in is now a separate step, Phase A10 below.

### Phase A6 — Create the Firestore database (console)

**Status: ✅ done** — Standard edition, production mode. Unaffected by the later Blaze upgrade — same database, no need to recreate anything.

No manual "create table" step — collections (`users`, `products`, `categories`, `orders`) appear automatically the first time code writes to them.

### Phase A7 — Security rules (written — you paste them in)

**Status: ✅ written, ⬜ not yet applied/republished — one thing left for you to do.**

Rules are in [firestore.rules](../firestore.rules) at the project root: anyone can read `products`/`categories` (public catalog); signed-in users can read/write only their own `users/{uid}` doc and their own orders; only `role: admin` can write `products`/`categories`, read/manage any order, or change anyone's role; plus a `phone_index` collection (phone → uid, public read, owner-only write) backing the "does this number already have an account" check before sending an OTP.

**If you already published an earlier version:** the file changed again to add `phone_index` — republish is required, or phone sign-up will start failing (the new existence-check write gets denied without it).

**To apply them (either way works):**
- **Console (simplest):** open [firestore.rules](../firestore.rules), copy its contents, paste into **Firestore → Rules** tab in the console, click **Publish**.
- **CLI:** `firebase deploy --only firestore:rules` (needs `firebase init firestore` run once first, to link the local file to the project).

The first admin account: sign up normally through the app, then manually flip that one user's `role` field to `admin` in **Firestore console → `users` collection → your document**. No self-service admin signup, by design.

### Phase A8 — Platform-specific notes

- **Android**: phone sign-in (Phase A10) and Google Sign-In both need a SHA-1/SHA-256 fingerprint added in console (Project settings → your Android app → Add fingerprint) — not needed for Email/Password alone.
- **iOS**: real Apple Developer account only needed for physical device/TestFlight builds.
- **Web**: `localhost` is authorized by default; add your deployed domain under Authentication → Settings → Authorized domains once hosted somewhere.

### Phase A9 — Local testing (optional)

Firebase Local Emulator Suite (`firebase init emulators` / `firebase emulators:start`) runs Auth/Firestore/Storage/Functions entirely on your machine, no real usage or cost. Worth setting up once Parts B/C are live, to test without touching real quotas.

### Phase A10 — Enable Phone Authentication (console) — needs Blaze ✅ now available

**Status: ✅ done — console step enabled by you, code wiring done by me.** Confirmed with the client: real SMS-verified OTP (not phone-as-password).

1. **Authentication → Sign-in method → Phone → Enable**. ✅
2. Android: SHA-1/SHA-256 fingerprint added (via `cd android && ./gradlew signingReport` → Project settings → your Android app → Add fingerprint). ✅
3. Web: uses an invisible reCAPTCHA check automatically, no setup needed.
4. iOS: no APNs key added yet — falls back to a reCAPTCHA challenge instead of silent verification (one extra tap for the user); real SMS still sends either way. Add the APNs key later when doing real iOS device testing, for the smoother silent-verification path.
5. Test phone numbers (optional, console → same Phone provider screen → "Phone numbers for testing") — added for you and the client, useful for trying the flow without incurring real SMS or needing the rest of the platform config finished.

**Code side:** `AuthRepository`/`AuthRemoteDatasource` gained `sendPhoneOtp`/`verifyPhoneOtp`, two new `AccountBloc` events (`AccountPhoneOtpRequested`, `AccountPhoneOtpVerifyRequested`), and `AccountState` gained `phoneVerificationId`. The existing `PhoneNumberStep`/`OtpVerificationStep` UI is now wired to them — Send Code triggers a real SMS, Verify checks the real code, Resend actually re-sends (not just resetting the local cooldown timer). First-time phone sign-in creates a `users/{uid}` doc the same way email sign-up does (`role: 'customer'`, plus a `phone` field). `flutter analyze`/`flutter test`/`flutter build web` all verified clean.

---

## Part B — Firebase Cloud Storage: Product Images

**Status: ⬜ not started.** Not urgent today — the app currently uses local placeholder images, and admin photo upload doesn't exist yet (roadmap Phase 5, see [PLAN.md](PLAN.md)).

### Phase B1 — Enable Cloud Storage (console)

1. **Build → Storage → Get started**.
2. Choose the **same region** as Firestore.
3. **Production mode** — same reasoning as Firestore, locked down by default.

This was previously blocked without Blaze; now available directly.

### Phase B2 — (Optional) Auto-resize images on upload

Cloudinary's earlier appeal was resizing one upload into thumbnail/card/detail sizes automatically. Firebase has an official equivalent: the **["Resize Images" Extension](https://extensions.dev/extensions/firebase/storage-resize-images)** — install it from **Build → Extensions** in the console, point it at the Storage bucket, and it automatically generates resized copies whenever an image is uploaded. Optional — can be added later without changing the upload code, skip for now if not needed immediately.

### Phase B3 — Storage security rules (my part, you paste them in)

Only signed-in users with `role: admin` (same Firestore-backed role check as Firestore rules) can upload; anyone can read (product photos are public). I'll write the exact rule text for **Storage → Rules**, same pattern as Phase A7.

### Phase B4 — Wire uploads into the app (my part, later)

Simpler than the old Cloudinary/Netlify plan — no signing server needed, since Firebase Storage checks the upload directly against Security Rules using the signed-in user's role:
1. Admin picks a photo (standard image picker).
2. App uploads directly to Firebase Storage using the `firebase_storage` package — Storage Rules verify the uploader is an admin.
3. The resulting download URL is saved on the product's Firestore document (`imageUrl` field).

Nothing to build yet — this is the plan for when admin product management (roadmap Phase 5) starts.

---

## Part C — Firebase Cloud Functions: Stripe Payments

**Status: ⬜ not started.** Furthest out on the roadmap (Phase 6) — customer/product/cart/checkout/orders (Phase 4) and the admin side (Phase 5) come first.

### Phase C1 — Create a Stripe account (console, you do this)

1. [stripe.com](https://stripe.com) → sign up.
2. **Test mode** is fully free, no card — the entire payment flow can be built and tested with fake card numbers before going live.
3. Note the **Publishable key** and **Secret key** (test mode: `pk_test_...` / `sk_test_...`).
4. A real bank account is only needed later, when switching to **live mode** to actually receive payments.

### Phase C2 — Enable Cloud Functions (console + CLI)

1. In the Firebase console, Cloud Functions is available now that Blaze is active — no separate "enable" click needed beyond the plan itself.
2. From the project root: `firebase init functions` sets up a `functions/` folder (I'll do this as part of Phase C3).

### Phase C3 — Build the payment function (my part, later)

1. A Cloud Function (e.g. `createPaymentIntent`) that takes an order total, calls Stripe's API using the secret key, and returns a `client_secret`.
2. The Stripe secret key is stored as a **Cloud Functions secret** (`firebase functions:secrets:set STRIPE_SECRET_KEY`) — never committed to the repo, never sent to the Flutter app.
3. The Flutter app calls this function (via the `cloud_functions` package or HTTPS) to get a `client_secret`, then hands it to the `flutter_stripe` package to complete payment on-device.
4. Optionally, a second function acts as a Stripe **webhook** endpoint, confirming payment success server-side and writing the final order/payment status to Firestore.

### Phase C4 — Costs, plainly

- **Stripe's own fee** (~2.9% + $0.30 per successful charge) is unavoidable regardless of backend — every payment processor charges this, only ever deducted from real sales, never billed upfront.
- **Cloud Functions free quota** (2M invocations/month, 400K GB-seconds, etc.) comfortably covers a low-traffic function like this — see the summary table below.

---

## Free-tier summary (Blaze plan)

Blaze removes the *activation* block on Storage/Functions/Phone Auth, but usage within the free quota still costs nothing. Realistic costs at this app's scale:

| Service | Free every month | Likely to cost anything? |
|---|---|---|
| Firebase Auth (email/password) | Unlimited | No |
| Firebase Auth (phone/SMS) | Small daily free quota, then per-SMS | **Yes, small amounts** — this is the one line item genuinely likely to show a real (small) charge once customers verify phone numbers |
| Firestore | 50,000 reads/day, 20,000 writes/day, 1 GiB stored | No, not at this scale |
| Cloud Storage | 5 GB stored, 1 GB/day download | No, not at this scale |
| Cloud Functions | 2,000,000 invocations/month | No, not at this scale |
| Stripe | No monthly fee; ~2.9% + $0.30 per transaction | Only ever from real sales, not a cost to "avoid" |

The 89-day trial credit shown in the console absorbs all of this many times over during development regardless.

---

## Recap checklist

**Part A — Firebase Auth + Firestore:**
- [x] A1 — Create Firebase project
- [x] A2 — Install CLI, log in
- [x] A3 — `flutterfire configure` (all 3 platforms)
- [x] A4 — Packages added, initialized in `bootstrap.dart`
- [x] A5 — Enable Email/Password sign-in
- [x] A6 — Create Firestore database
- [x] Blaze plan enabled
- [x] Real email/password auth wired into the app (sign-in/sign-up dialogs, `AccountBloc`, `account_page.dart`, header greeting)
- [x] A10 — Phone Authentication enabled in console (Android SHA added) + real code wiring done
- [x] Google Sign-In enabled in console (support email set, `google-services.json` refreshed) + real code wiring done for Android/Web (iOS blocked on Mac access)
- [ ] A7 — Security rules written ([firestore.rules](../firestore.rules)) ← **paste into console or deploy — next up for you, changed again (phone_index)**
- [ ] Flip your test account's `role` to `admin` (after your first real signup through the app)

**Part B — Firebase Storage (before admin product management):**
- [ ] B1 — Enable Cloud Storage
- [ ] B2 — (optional) Install Resize Images extension
- [ ] B3 — Storage security rules

**Part C — Cloud Functions + Stripe (later, Stripe phase):**
- [ ] C1 — Create Stripe account (test mode)
- [ ] C2 — `firebase init functions`

Ping me once A7's security rules are published — that's the one thing standing between "code is done" and "auth fully works end to end" (Firestore denies reads/writes until they're applied).
