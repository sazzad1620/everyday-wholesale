# Implementation Status

Tracks what's actually built against the roadmap in [PLAN.md](PLAN.md). Update this file whenever a phase or task changes status — it should always reflect the real state of the code, not the plan.

Status key: ✅ done · 🚧 in progress · ⬜ not started

## Phase 1 — Foundation ✅

| Task | Status | Notes |
|---|---|---|
| Git repo initialized, `.gitignore` updated | ✅ | `docs/VanSalesPro/` ignored; rest of `docs/` tracked |
| Core dependencies added | ✅ | `flutter_bloc`, `equatable`, `get_it`, `injectable`, `go_router`, `fpdart`, `easy_localization` |
| `core/errors` (Failure/Exception base types) | ✅ | [lib/core/errors](../lib/core/errors) |
| `core/usecase` (UseCase base) | ✅ | [lib/core/usecase/usecase.dart](../lib/core/usecase/usecase.dart) |
| `core/utils/responsive` (breakpoint helper) | ✅ | [lib/core/utils/responsive](../lib/core/utils/responsive) — no screenutil |
| `shared/theme` (colors, text styles, spacing, light+dark ThemeData) | ✅ | [lib/shared/theme](../lib/shared/theme) — placeholder palette, will be replaced by gunmahalalfood.com-derived colors |
| `shared/widgets` (first shared widget) | ✅ | [AppLoader](../lib/shared/widgets/loaders/app_loader.dart) only so far — more added as features need them |
| DI wiring (`get_it` + `injectable`) | ✅ | [lib/config/di](../lib/config/di) |
| Routing (`go_router`) | ✅ | [lib/config/routes](../lib/config/routes) — 2 routes so far (`/`, `/home`) |
| Localization (`easy_localization`) | ✅ | [assets/translations/en.json](../assets/translations/en.json) |
| Template feature: Splash → Home | ✅ | [lib/features/splash](../lib/features/splash) fully wired (data/domain/presentation/DI); [lib/features/home](../lib/features/home) is a bare placeholder |
| `flutter analyze` clean | ✅ | 0 issues |
| `flutter test` passing | ✅ | Theme sanity test only — no widget/bloc tests yet |
| Verified: web build compiles & serves, all modules load, no console errors | ✅ | Pixel-level visual check not possible in the dev sandbox (browser pane doesn't composite frames there); run `flutter run -d chrome` locally to see it render |

**Not created yet, deliberately** (see PLAN.md §4.5): `core/constants/storage_keys.dart`, `config/di/modules/`, dark mode toggle, additional locales. Add these when a feature actually needs them, not before.

## Phase 2 — UI-first customer build 🚧

| Task | Status | Notes |
|---|---|---|
| Brand assets (logo, home banner, per-category photos) | ✅ | [assets/images](../assets/images) — logo, home banner, and demo category photos (Most Popular, Meat & Fish) supplied by the client. `CategoryEntity.imageUrl` is null for the rest, which fall back to a generic placeholder until an admin uploads one. |
| Home page real UI (search bar, banner carousel, category grid) with mock data | ✅ | [lib/features/home](../lib/features/home) — full data/domain/presentation layers over a mock datasource. |
| Category cards — image-based redesign | ✅ | [category_card.dart](../lib/features/home/presentation/widgets/category_card.dart) + [category_image.dart](../lib/shared/widgets/category_image.dart) — square photo/placeholder + label strip, rotating pastel tile+border+label shades derived from one seed hue per index ([category_palette.dart](../lib/shared/theme/category_palette.dart)), generic placeholder icon (not per-category) until an admin sets a real image. |
| Subcategories | ✅ | `CategoryEntity.subcategories` (empty for categories without them); Meat & Fish, Frozen Food, and Masala & Spice have some, matching mock products via `ProductEntity.subcategoryId`. Tapping a category with subcategories opens [category_landing_page.dart](../lib/features/home/presentation/pages/category_landing_page.dart) ("Browse All" or pick one); categories without go straight to the product list — same branching logic in [category_navigation.dart](../lib/features/home/presentation/utils/category_navigation.dart) for both the grid and the drawer. |
| Category drawer (slide-out menu) | ✅ | [category_drawer.dart](../lib/features/home/presentation/widgets/category_drawer.dart) — categories with subcategories use `ExpansionTile` (chevron expands to indented subcategory rows, tapping a subcategory goes straight to its filtered product list); plain rows for categories without. Static About/Contact footer below a divider (`showComingSoonSnackBar` on tap). |
| Account — moved off bottom nav | ✅ | Dropped the Account tab/branch/page entirely (was dead weight once this changed) — a person icon on the Home top bar (opposite the menu icon) opens [account_sheet.dart](../lib/features/account/presentation/widgets/account_sheet.dart), a bottom sheet mocking signed-out (Log In/Sign Up) and signed-in (name/email, Edit Profile, Address, Logout) states. No real auth yet — "Log In"/"Sign Up" just flip local state to preview both views. |
| Bottom navigation shell (Home / Category / Wishlist / Bag) | ✅ | [main_bottom_nav_bar.dart](../lib/shared/widgets/navigation/main_bottom_nav_bar.dart) — custom bar, not `NavigationBar`, since "Category" opens the drawer rather than switching branches. 3 real `go_router` branches now (Home, Wishlist, Cart) since Account isn't one. Bag badge count now reflects real `CartBloc` state. |
| Product listing UI (mock data) | ✅ | [lib/features/product](../lib/features/product) — full data/domain/presentation layers; `GetProductsByCategoryUseCase` takes an optional `subcategoryId` filter. Routed at `/home/category/:categoryId` (and `/browse/:subcategoryId`), nested under the Home branch so the bottom nav stays visible. |
| Product detail UI (mock data) | ✅ | [lib/features/product](../lib/features/product) — `product_detail_page.dart` + `ProductDetailBloc`, tabs/highlight boxes/info rows, fully wired to `GetProductByIdUseCase` over the mock datasource. |
| Cart UI (mock data) | ✅ | [lib/features/cart](../lib/features/cart) — full data/domain/presentation layers (`CartBloc`, local datasource, add/remove/update-quantity/clear usecases); `cart_page.dart` with item cards, summary, and voucher card. |
| Checkout UI (mock data, no real payment) | ✅ | [lib/features/checkout](../lib/features/checkout) — presentation-only (no bloc/data/domain of its own), reads live `CartBloc` state for the order summary; `checkout_page.dart` clears the cart and navigates to `order_confirmation_page.dart` on "Place Order" — no real payment gateway yet (deferred to Phase 6). Pushed outside the bottom-nav shell as a focused full-screen flow. |
| Login / Signup UI (mock, no real auth) | ✅ | Built as centered modal dialogs, not full pages (client decision) — [lib/shared/widgets/dialogs](../lib/shared/widgets/dialogs): `blurred_dialog.dart` (shared `showBlurredDialog` + `DialogCard`/`DialogCloseButton` shell, reusable for any future dialog), `sign_in_dialog.dart`, `sign_up_dialog.dart`. Tapping the header's account icon while signed out opens `SignInDialog` over a blurred/dimmed backdrop; its "Sign Up" link swaps to `SignUpDialog` and back. Still mock — both just flip `AccountBloc` to signed-in and close, no Firebase call. `account_sheet.dart`'s `openAccountMenu()` is now the single entry point used by all header instances, routing to the sign-in dialog (signed out) or the bottom sheet (signed in); the old inline signed-out bottom-sheet view was removed as dead code. |
| Address management UI (mock data) | ⬜ | "Address" row in `account_sheet.dart` is currently a "coming soon" snackbar |
| Edit profile UI (mock data) | ⬜ | "Edit Profile" row in `account_sheet.dart` is currently a "coming soon" snackbar |
| Order history / My Orders UI (mock data) | ⬜ | No entry point yet — needs adding to `account_sheet.dart` plus a mock orders list/detail |

## Phase 3 — Firebase integration 🚧

| Task | Status | Notes |
|---|---|---|
| Add Firebase packages, configure per platform (Android/iOS/Web) | ✅ | `firebase_core`, `firebase_auth`, `cloud_firestore` added to `pubspec.yaml`; `Firebase.initializeApp()` wired into [lib/app/bootstrap.dart](../lib/app/bootstrap.dart), verified booting cleanly on web (all 3 SDKs initialize, no console errors). Android Gradle plugin wiring was already added by `flutterfire configure`; iOS/Web need no manual wiring. Auth enabled, Firestore database created. `firebase_storage`/`cloud_functions` not yet added — Parts B/C of [BACKEND_SETUP.md](BACKEND_SETUP.md) |
| Project upgraded to Blaze plan | ✅ | Unlocks Cloud Storage, Cloud Functions, and Phone Auth — see [PLAN.md §4.3](PLAN.md) for the full history (originally avoided in favor of Cloudinary/Netlify; superseded) |
| Firestore security rules | 🚧 | [firestore.rules](../firestore.rules) — public read for `products`/`categories`, owner-or-admin for `users`/`orders`, role changes restricted to admins, plus a public-read/owner-write `phone_index` (phone → uid, for the pre-signup-check below). **Changed again after the last publish** — needs republishing, see [BACKEND_SETUP.md](BACKEND_SETUP.md) Phase A7 |
| Firestore data model for products | ⬜ | |
| Firestore data model for orders | ⬜ | |
| Firebase Auth — email/password (customer + admin/manager roles) | ✅ | Real `auth` slice in [lib/features/auth](../lib/features/auth) (domain/data/presentation, `AuthRepository`/`AuthRemoteDatasource`/usecases), wired into `AccountBloc` and the sign-in/sign-up dialogs. `lib/features/account` is now just the profile UI (`account_page.dart`, `order_history_page.dart`), split out from the auth slice for clarity. Sign-up creates a `users/{uid}` Firestore doc with `role: 'customer'`; `AccountBloc` stays synced via `authStateChanges()` so a signed-in session survives app restarts. `flutter analyze` clean, web build verified |
| Firebase Auth — phone (SMS OTP) | ✅ | Confirmed with client: real OTP (not password-based). Phone provider enabled in console, Android SHA fingerprints added. `AuthRepository`/`AuthRemoteDatasource` gained `sendPhoneOtp`/`verifyPhoneOtp`; `AccountBloc` gained `AccountPhoneOtpRequested`/`AccountPhoneOtpVerifyRequested` + `phoneVerificationId` state. `PhoneNumberStep`/`OtpVerificationStep` (`lib/shared/widgets/dialogs/`) send/verify/resend for real now. First-time phone sign-in creates a `users/{uid}` doc same as email (`role: 'customer'`, plus `phone` field). `UserEntity`/`UserModel` gained a `phone` field |
| Account feature — real auth wired into UI | ✅ | `sign_in_dialog.dart`/`sign_up_dialog.dart` (both email and phone tabs) call real Firebase Auth; `account_page.dart` shows the real signed-in user's name/email and calls `AccountSignOutRequested` on logout; header greeting uses the real name too |
| Phone sign-in/sign-up account-existence checks | ✅ | Sign-in with an unregistered number is rejected before an OTP is even sent (`isPhoneRegistered` pre-check against the new `phone_index` collection — fails open to the sign attempt if the check itself errors, so it never blocks on a network hiccup); sign-up with an already-registered number is rejected at verify-time instead, telling the user to sign in. Both cases sign the just-created Firebase Auth session back out so it doesn't leak through as a real login |
| OTP entry UI | ✅ | Redesigned from one text field to 6 individual digit boxes (`_OtpCodeBoxes` in `phone_auth_steps.dart`), auto-advancing focus, no placeholder text |
| Firebase Auth — Google Sign-In | ✅ | Client-requested addition. Native account picker on Android/iOS via `google_sign_in` (v7 API — `GoogleSignIn.instance.initialize()` called once in `bootstrap.dart`, `.authenticate()` per sign-in); `FirebaseAuth.signInWithPopup(GoogleAuthProvider())` on Web instead (the package's web implementation requires its own rendered button and can't be called imperatively, so Firebase's own popup avoids that and keeps a normal custom-styled button). One unified flow — no separate sign-in/sign-up, matching universal Google Sign-In convention; name/email pulled directly from the Google profile, no manual entry. `AccountBloc` gained `AccountGoogleSignInRequested`; `AuthRepository`/`AuthRemoteDatasource` gained `signInWithGoogle()`; `signOut()` now also clears the cached Google session. "Continue with Google" button (`SecondaryButton`, extended with an `isLoading` state) added to both dialogs below an "OR" divider. **iOS not wired/testable** — blocked on Mac/Xcode access, see [IOS_SETUP.md](IOS_SETUP.md); Android + Web fully done |
| Admin role-based routing (proof-of-concept) | ✅ | Placeholder `AdminDashboardPage` (`lib/features/admin/`) + `/admin` route — signing in with a `role: admin` account redirects there instead of staying put, proving the `isAdmin` check flows correctly end to end. Explicitly temporary, not the real admin dashboard (roadmap Phase 5) |
| Forgot password (email) | ✅ | `sendPasswordResetEmail` added to `AuthRepository`/`AuthRemoteDatasource`; Firebase sends the email and hosts the reset page itself, no custom screen needed. "Forgot password?" link on the sign-in dialog's email tab, confirmation toast on send. New `AccountPasswordResetRequested` event, `passwordResetEmailSent` one-shot state field |

## Phase 4 — Customer features end-to-end ⬜

| Task | Status | Notes |
|---|---|---|
| Auth feature (login/signup, customer) | ⬜ | |
| Product catalog (browse/search/filter, real data) | ⬜ | |
| Cart (real data, persisted) | ⬜ | |
| Checkout / order placement (real data) | ⬜ | |
| Order history / order status tracking | ⬜ | |

## Phase 5 — Admin/manager side ⬜

| Task | Status | Notes |
|---|---|---|
| Admin/manager auth & role gating | ⬜ | |
| Admin dashboard | ⬜ | |
| Product management (CRUD) | ⬜ | |
| Order management (view, update status) | ⬜ | |

## Phase 6 — Stripe integration ⬜

| Task | Status | Notes |
|---|---|---|
| Backend (Firebase Cloud Function) to create PaymentIntents | ⬜ | Needed for secure payment — can't do client-side alone. Now on Cloud Functions directly (project upgraded to Blaze), not Netlify — see [PLAN.md §4.3](PLAN.md) |
| Customer-side payment flow | ⬜ | |
| Admin-side payment/receipt visibility | ⬜ | |

## Phase 7 — Polish ⬜

| Task | Status | Notes |
|---|---|---|
| Dark mode toggle | ⬜ | Theme already supports it (`AppTheme.dark`); just needs a switch wired to `ThemeMode` |
| Additional locales | ⬜ | Only if requested |
