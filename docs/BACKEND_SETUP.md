# Backend Setup Guide (Beginner-Friendly, A–Z)

Everyday Wholesale's backend is split across three services, each doing the job it's actually good at, all free at this project's scale:

| Service | Handles | Status |
|---|---|---|
| **Firebase** | Auth (login/signup), Firestore (products, categories, orders, users) | 🚧 Set up now — Part A below |
| **Cloudinary** | Product images (admin-uploaded, many products × several photos each) | ⬜ Set up before admin product management is built — Part B below |
| **Netlify + Stripe** | Online payment (creating PaymentIntents securely) | ⬜ Set up when Stripe integration begins — Part C below |

This file replaces the old `FIREBASE_SETUP.md` — Firebase alone no longer describes the whole backend. Written for a first-timer: console/dashboard steps say exactly what to click, and any step needing your own login is called out explicitly.

> Companion docs: [PLAN.md](PLAN.md) (why these decisions) and [IMPLEMENTATION.md](IMPLEMENTATION.md) (what's actually built so far).

**Why three services instead of just Firebase:** Firebase's Cloud Storage and Cloud Functions both require upgrading to the paid **Blaze** plan (a card on file) just to activate — regardless of actual usage. Cloudinary and Netlify each do that one job for free, with no card required, so Firebase itself stays on the free **Spark** plan permanently. Full reasoning in [PLAN.md §4.3](PLAN.md).

---

## Part A — Firebase: Auth + Firestore (do this now)

### Phase A0 — Before starting

- A Google account (personal or a dedicated business one — your call; if this is a client project, consider creating it under an account that's easy to hand over later, see the ownership-transfer note in chat history / ask if unsure).
- [Node.js](https://nodejs.org/) installed (needed for the Firebase CLI).
- This repo checked out locally with Flutter working (`flutter doctor` clean).

### Phase A1 — Create the Firebase project (console)

1. Go to [console.firebase.google.com](https://console.firebase.google.com) and sign in.
2. **Add project** → name it (e.g. `everyday-wholesale`) → note the generated project ID.
3. Google Analytics prompt: fine to enable (it's free, gives useful e-commerce reporting later — screen views, cart abandonment, purchase tracking) or skip if you'd rather decide later; either is fine.
4. **Create project**.

### Phase A2 — Install the CLI tools (your machine, one-time)

```bash
npm install -g firebase-tools
```
```bash
firebase login
```
Opens a browser — log in with the same Google account from Phase A1.

```bash
dart pub global activate flutterfire_cli
```

> **Windows note:** if PowerShell blocks these with a "running scripts is disabled" error, either run `npm.cmd install ...` / `firebase.cmd login` instead, or fix it permanently with `Set-ExecutionPolicy -Scope CurrentUser RemoteSigned`.

### Phase A3 — Register the app platforms

From the project root:

```bash
flutterfire configure
```

- Select **android, ios, web** when asked which platforms.
- It detects the current package IDs (`com.example.everyday_wholesale` / `com.example.everydayWholesale`) — these are placeholders from `flutter create`. Fine to proceed with them for development; just don't ship to app stores with `com.example.*`.
- Generates `lib/firebase_options.dart` (safe to commit — public client identifiers, not secrets) and downloads `android/app/google-services.json`. On Windows, `ios/Runner/GoogleService-Info.plist` may not download automatically — not blocking; `firebase_options.dart` alone covers Auth/Firestore on iOS, the `.plist` only matters when building on an actual Mac later.

**Status: ✅ done** — project created, CLI installed, `flutterfire configure` run, all three platforms registered.

### Phase A4 — Wire Firebase into the app code (my part)

**Status: ✅ done** — packages added, `Firebase.initializeApp()` wired into `bootstrap.dart`, verified booting cleanly (all three SDKs initialize with no errors) on web.

Once Phase A3 is done:
1. Add `firebase_core`, `firebase_auth`, `cloud_firestore` to [pubspec.yaml](../pubspec.yaml) — **not** `firebase_storage` (Part B/Cloudinary handles images instead).
2. Initialize in [lib/app/bootstrap.dart](../lib/app/bootstrap.dart): `await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);`
3. Per-platform wiring — only one of the three actually needs manual changes:
   - **Android**: Google Services Gradle plugin registered in `android/build.gradle.kts` and `android/app/build.gradle.kts` — this is what makes the build read `google-services.json`. The only platform with a real manual step.
   - **iOS**: nothing extra — Firebase's iOS SDKs are pulled in automatically via CocoaPods once the packages are in `pubspec.yaml` (`pod install` runs implicitly on next build). No manual Xcode project changes needed for Auth/Firestore.
   - **Web**: nothing extra — no `index.html`/`<script>` changes needed with the current `firebase_core` package; it's handled internally.

### Phase A5 — Enable Authentication (console)

1. **Build → Authentication → Get started** (or under **Security** in newer console layouts).
2. **Sign-in method** tab → enable **Email/Password**.
3. Ignore the "Sign in with Google" recommendation banner — optional, not needed, can add later without breaking anything.

**Admin vs. customer:** one Auth system, distinguished by a `role` field (`customer`/`admin`) on each user's Firestore document — not a console setting. The first admin account is created by signing up normally through the app, then manually flipping that one user's `role` to `admin` in the Firestore console (Phase A6). No self-service admin signup, by design.

**Status: ✅ done** — Email/Password enabled.

### Phase A6 — Create the Firestore database (console)

1. **Build → Firestore Database → Create database**.
2. **Standard edition** (not Enterprise — that's a paid, higher-scale option not needed here).
3. Pick a **location** closest to your actual customers (can't change later without migrating).
4. **Production mode** (locked down by default — safer than test mode, which leaves it open for 30 days). Rules get added in Phase A7 before real code touches it.
5. **Create**.

No manual "create table" step — collections (`users`, `products`, `categories`, `orders`) get created automatically the first time code writes to them. The one manual step here: after your first test signup, **Firestore console → `users` collection → your document → edit `role` to `admin`**.

**Status: ✅ done** — Firestore database created (Standard edition, production mode).

### Phase A7 — Security rules (my part, you paste them in)

Firestore denies all access by default in production mode. Rules will express: anyone can read products/categories (public catalog); signed-in users can read/write only their own user doc and orders; only `role: admin` can write products/categories or manage any order. I'll write the exact rule text and hand it to you to paste into **Firestore → Rules**.

### Phase A8 — Platform-specific notes

- **Android**: Google Sign-In (if added later) needs a SHA-1/SHA-256 fingerprint added in console — not needed for Email/Password.
- **iOS**: real Apple Developer account only needed for physical device/TestFlight builds, not for Firebase itself.
- **Web**: `localhost` is authorized by default; add your deployed domain under Authentication → Settings → Authorized domains once hosted somewhere.

### Phase A9 — Local testing (optional)

Firebase Local Emulator Suite (`firebase init emulators` / `firebase emulators:start`) runs Auth/Firestore on your machine, no real data touched. Optional, set up later if useful.

---

## Part B — Cloudinary: Product Images (set up before admin product management)

Not urgent today — the app currently uses local placeholder images ([IMPLEMENTATION.md](IMPLEMENTATION.md)), and admin photo upload doesn't exist yet (roadmap Phase 5). Steps are here so nothing needs re-deciding when that phase starts.

**Why Cloudinary and not Firebase Storage:** Firebase Storage requires the paid Blaze plan to activate at all — a Google policy, not a usage limit. Cloudinary's free tier (25GB storage + bandwidth/month) needs no card, and does on-the-fly image resizing — one upload per product serves thumbnail, card, and detail-page sizes without storing multiple copies. See [PLAN.md §4.3](PLAN.md).

### Phase B1 — Create a Cloudinary account (console, you do this)

1. Go to [cloudinary.com](https://cloudinary.com) → sign up (free, no card).
2. From the dashboard, note your **Cloud name**, **API key**, and **API secret** — you'll hand these to me (or store them as environment variables, never hardcoded in the Flutter app).

### Phase B2 — Create a signed upload preset (console, you do this)

1. Dashboard → **Settings → Upload → Upload presets → Add upload preset**.
2. Set **Signing Mode** to **Signed** (not "Unsigned" — signed means only requests carrying a valid signature can upload, which prevents random users from uploading arbitrary files to your account).
3. Save and note the preset name.

### Phase B3 — Wire uploads into the app (my part, later)

Since a signed upload needs the Cloudinary **API secret**, and that secret must never live inside the Flutter app (anyone could extract it and abuse your account), uploads go through the same small-serverless-function pattern as Stripe:
1. A Netlify Function (shared with Part C's Netlify setup) generates a short-lived upload signature using the API secret, kept as a Netlify environment variable.
2. The Flutter admin screens request a signature from that function, then upload the image directly to Cloudinary using it.
3. The resulting image URL is saved on the product's Firestore document (e.g. `imageUrl` field) — Firebase itself never touches image bytes.
4. Only the admin role can reach this upload flow, gated the same way as other admin-only actions.

Nothing to build yet — this is the plan for when admin product management (roadmap Phase 5) starts.

---

## Part C — Netlify + Stripe: Payments (set up later — Stripe phase)

Furthest out on the roadmap (Phase 6) — customer/product/cart/checkout/orders (Phase 4) and the admin side (Phase 5) come first. Documented now so the decision doesn't need re-litigating later.

**Why Netlify instead of Firebase Cloud Functions:** creating a Stripe PaymentIntent needs a server holding the Stripe **secret key** — client-side calls alone aren't safe (the secret key would be exposed). Firebase Cloud Functions could do this, but requires upgrading the whole Firebase project to Blaze. Netlify Functions' free tier runs this one low-traffic function without ever touching Firebase billing. See [PLAN.md §4.3](PLAN.md).

### Phase C1 — Create a Netlify account (console, you do this)

1. Go to [netlify.com](https://netlify.com) → sign up (free, no card — can use GitHub login for convenience, matching the repo).
2. Connect it to the `everyday-wholesale` GitHub repo when prompted (or later, from the dashboard).

### Phase C2 — Create a Stripe account (console, you do this)

1. Go to [stripe.com](https://stripe.com) → sign up.
2. **Test mode** is fully free and requires no card — the entire payment flow can be built and tested with fake card numbers before ever going live.
3. From the Stripe dashboard, note the **Publishable key** and **Secret key** (test mode versions, prefixed `pk_test_...` / `sk_test_...`).
4. A real bank account only needs to be added when switching to **live mode** to actually receive customer payments — not needed for development.

### Phase C3 — Build the payment function (my part, later)

1. A Netlify Function (e.g. `netlify/functions/create-payment-intent.js`) that takes an order total, calls Stripe's API using the secret key, and returns a `client_secret`.
2. The Stripe secret key is stored as a **Netlify environment variable** — never committed to the repo, never sent to the Flutter app.
3. The Flutter app calls this function over plain HTTPS to get a `client_secret`, then hands it to the `flutter_stripe` package to complete the payment on-device.
4. Optionally, a second Netlify function acts as a Stripe **webhook** endpoint, so Stripe can confirm payment success server-side (more reliable than trusting the client alone) — writes the final order/payment status to Firestore.

### Phase C4 — Costs, plainly

- **Stripe's own fee** (~2.9% + $0.30 per successful charge) is unavoidable — every payment processor charges this, it's how they make money, and it's only ever deducted from real sales, never billed upfront.
- **Netlify Functions free tier** easily covers this — one lightweight function, low traffic, no card needed.
- **Firebase stays untouched** — Blaze is never required for this.

---

## Free-tier summary (all three services)

| Service | Free limits (Spark/free tier) | Card required? |
|---|---|---|
| Firebase Auth | Unlimited (Email/Password) | No |
| Firestore | 50,000 reads/day, 20,000 writes/day, 1 GiB stored | No |
| Cloudinary | 25GB storage + bandwidth/month | No |
| Netlify Functions | Generous monthly invocation quota, easily covers 1–2 low-traffic functions | No |
| Stripe | No monthly fee; ~2.9% + $0.30 per successful transaction only | No (test mode); bank details needed only to go live |

At this project's expected scale, none of these should ever produce a bill outside of Stripe's own per-sale cut once real payments start.

---

## Recap checklist

**Part A — Firebase (do now):**
- [x] A1 — Create Firebase project
- [x] A2 — Install CLI, log in
- [x] A3 — `flutterfire configure` (all 3 platforms registered)
- [x] A5 — Enable Email/Password sign-in
- [x] A6 — Create Firestore database
- [ ] A6 (after first signup) — Flip your test account's `role` to `admin` ← **you're here** (needs a real signup to exist first, so this waits for A4/A7 code work)

**My part, once Firestore exists:**
- [x] A4 — Add Firebase packages, initialize in `bootstrap.dart`
- [ ] A7 — Write and hand you security rules to paste in
- [ ] Swap mock datasources for real Firebase-backed ones (repository interfaces already in place, per [PLAN.md](PLAN.md))

**Part B — Cloudinary (before admin product management, not now):**
- [ ] B1 — Create Cloudinary account, note credentials
- [ ] B2 — Create a signed upload preset

**Part C — Netlify + Stripe (later, Stripe phase):**
- [ ] C1 — Create Netlify account, connect repo
- [ ] C2 — Create Stripe account (test mode)

Ping me once Firestore (A6) is created and I'll pick up A4.
