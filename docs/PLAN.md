# Everyday Wholesale — Project Plan & Status

Single source of truth for what this app is, why it's built the way it is, the technical decisions behind it, and what's actually done vs. still to build. If a future decision contradicts this file, update this file in the same change. **§7 (Roadmap & Status) is the living checklist** — update it whenever a phase or task changes status; it should always reflect the real state of the code, not aspiration.

> Companion docs: [BACKEND_SETUP.md](BACKEND_SETUP.md) (beginner-friendly Firebase console walkthrough), [IOS_SETUP.md](IOS_SETUP.md) (exact checklist for when Mac/Xcode access is available).

## 1. Product

**Everyday Wholesale** is a grocery ordering app. Customers browse grocery products and place orders; admins/managers manage the catalog and fulfil orders. Primary purpose: sell grocery products of different types.

## 2. Client requirements

1. Company: Everyday Wholesale — sells grocery products of different types.
2. Optimized for Android, iOS, and Web.
3. Two user roles in one app:
   - **Customer**: login (email, phone, or Google), browse products, order, pay online (payment gateway added later).
   - **Admin/Manager**: login (same system, `role: admin`), manage products, view/manage orders and order status, receive payment via the payment gateway.
4. UI design follows [gunmahalalfood.com](https://gunmahalalfood.com/) initially, subject to change on client request. Screenshots from that site are provided to design each page.
5. Payment gateway: **Stripe** (integrated later, not part of the initial build).

## 3. Developer decisions

1. **Flutter, single codebase** for Android, iOS, and Web.
2. **Clean layered architecture** (data / domain / presentation), **feature-first**, SOLID principles, **pure BLoC** for state management (no Cubit, no mixed styles).
   - Reference project: `docs/VanSalesPro` (git-ignored, not part of this app) — used only to inform architecture/pattern conventions, not copied wholesale.
3. **Firebase** is the backend for as much data handling as feasible (see §5 for the full stack and its history).
4. **English only for now**, but strings live in translation files (`assets/translations/en.json`) so more languages can be added later without code changes.
5. **Light theme only for now**, but the theme system is built to support dark mode later without rework.
6. **Modularized** as much as practical — no hardcoded strings/colors/spacing in UI files; everything comes from shared modules so the UI stays visually consistent.
7. UI pages are designed from screenshots of gunmahalalfood.com supplied to the AI agent.
8. **Build order**: project structure/foundation → UI-first customer build with mock data → Firebase integration → real data replaces mocks → admin side → payments → polish. (§7 below is the current, refined version of this ordering.)
9. **Role-based access, not a separate login**: one shared sign-in system for customer and admin — no role picker anywhere in the UI. After sign-in, the app reads the user's `role` field and routes accordingly. Nobody can self-promote to admin from the app; that's a manual Firestore console edit only.

## 4. Architecture

### 4.1 Pattern

Clean Architecture, feature-first, three layers per feature:

- **domain** — entities, repository interfaces, usecases. No Flutter/Firebase/package imports beyond `fpdart`.
- **data** — datasources (remote/local), models (manual `fromMap`/`toMap`, no `freezed`/`json_serializable`), repository implementations that map exceptions → `Failure` and return `Either<Failure, T>`.
- **presentation** — bloc (`_bloc.dart` / `_event.dart` / `_state.dart`, one bloc per screen/flow), pages, widgets.

Repositories always return `Future<Either<Failure, T>>` (via `fpdart`). Usecases extend a shared `UseCase<ReturnType, Params>` base ([lib/core/usecase/usecase.dart](../lib/core/usecase/usecase.dart)).

### 4.2 Where things live

```
lib/
  main.dart              # entry point → bootstrap()
  app/                    # bootstrap.dart (DI + Firebase + localization init + runApp), app.dart (MaterialApp.router)
  config/
    di/                   # get_it + injectable wiring (injection_container.dart, generated .config.dart, firebase_module.dart)
    routes/                # go_router config + route path constants
  core/                    # cross-cutting infra: errors, usecase base, constants, responsive utils
  shared/                  # cross-feature reusable pieces: theme, shared widgets
  features/
    <feature>/
      data/{datasources,models,repositories}
      domain/{entities,repositories,usecases}
      presentation/{bloc,pages,widgets}
assets/
  translations/           # en.json, future locale files
```

Every new feature replicates the `data/domain/presentation` structure shown by the `auth` feature (the most fully-built reference implementation so far — see [lib/features/auth](../lib/features/auth)).

### 4.3 Naming conventions

- Bloc: three files per bloc — `{name}_bloc.dart`, `{name}_event.dart`, `{name}_state.dart`.
- Domain repository interface: `{Name}Repository` (abstract). Data implementation: `{Name}RepositoryImpl`.
- One usecase per file, extends `UseCase<ReturnType, Params>`.
- Pages live in `presentation/pages`, feature-local widgets in `presentation/widgets`, cross-feature widgets in `shared/widgets`.

## 5. Tech stack and why

| Concern | Choice | Why |
|---|---|---|
| State management | `flutter_bloc` + `equatable` | Client requirement: pure BLoC, no Cubit |
| Dependency injection | `get_it` + `injectable` (codegen) | Matches reference project; scales cleanly as features grow |
| Routing | `go_router` | Official Flutter package; strong web URL/deep-link support |
| Error handling | `fpdart` (`Either<Failure, T>`) | Actively maintained, good Dart 3 support |
| Localization | `easy_localization` | Uses literal `assets/translations/en.json` files as requested; simple to add more locales later |
| Responsive layout | Custom breakpoint helper (`core/utils/responsive`), no package | Avoids fighting responsive web/desktop layouts, a hard requirement here |
| Backend | Firebase — Auth, Firestore, Cloud Storage, Cloud Functions (all on the **Blaze** plan) | Client requirement. **History**: originally planned Auth+Firestore-only on the free Spark plan, with Storage/payments routed through Cloudinary/Netlify specifically to avoid Blaze's card requirement. **Superseded** — the project upgraded to Blaze, so the whole backend now consolidates into Firebase alone |
| Auth methods | Email/password, phone (SMS OTP), Google Sign-In — all via Firebase Auth | All three client-requested. Phone is real OTP, not password-based (confirmed with client). Google: `google_sign_in` package for native Android/iOS, `FirebaseAuth.signInWithPopup` for Web (the package's web implementation needs its own rendered button and can't be called imperatively) |
| Payments | Stripe, via Firebase Cloud Functions | Client requirement — not yet integrated. A Cloud Function holds the Stripe secret key and creates PaymentIntents; the Flutter app calls it via the `cloud_functions` package |
| Product images | Firebase Cloud Storage, with the official "Resize Images" Extension for thumbnail/card/detail sizes | Storage Rules gate uploads to `role: admin`, checked directly against the signed-in user — no separate signing server needed |
| Models | Manual `fromMap`/`toMap` | Keeps codegen surface limited to `injectable` |

## 6. Design source

UI is built from screenshots of [gunmahalalfood.com](https://gunmahalalfood.com/) supplied per-page/per-flow. The client may request a different design direction later; when that happens, this file and the relevant feature's UI should be updated together.

---

## 7. Roadmap & Status

One phase worked on at a time, sized to be a substantial, self-contained chunk of work rather than many tiny steps. Check items off as they land; add notes inline when something needed a real decision.

### Phase 1 — Foundation ✅ done

- [x] Git repo initialized, `.gitignore` set up (`docs/VanSalesPro/` ignored)
- [x] Core dependencies (`flutter_bloc`, `equatable`, `get_it`, `injectable`, `go_router`, `fpdart`, `easy_localization`)
- [x] `core/errors`, `core/usecase` base types
- [x] `core/utils/responsive` (custom breakpoint helper, no `flutter_screenutil`)
- [x] `shared/theme` (colors, text styles, spacing, light+dark `ThemeData` — dark mode theme exists but isn't wired to a switch yet, see Phase 7)
- [x] DI (`get_it` + `injectable`) and routing (`go_router`) wired
- [x] Localization (`easy_localization`) wired
- [x] Template feature (Splash → Home) fully wired end to end as the pattern reference
- [x] `flutter analyze` / `flutter test` clean, web build verified

### Phase 2 — Customer UI, mock data ✅ core done, 3 items deliberately deferred

- [x] Home page (search bar, banner carousel, category grid) — [lib/features/home](../lib/features/home)
- [x] Category cards, subcategories, category drawer
- [x] Bottom navigation shell (Home / Wishlist / Cart) — Account isn't a tab, reached via a header icon instead
- [x] Product listing + detail UI — [lib/features/product](../lib/features/product)
- [x] Cart UI — [lib/features/cart](../lib/features/cart)
- [x] Checkout UI (mock, no real payment) — [lib/features/checkout](../lib/features/checkout)
- [x] Login/signup UI as centered modal dialogs (client decision, not full pages) — [lib/shared/widgets/dialogs](../lib/shared/widgets/dialogs)
- [ ] Address management UI
- [ ] Edit profile UI
- [ ] Order history UI

**Note:** the last three were originally planned as mock-first UI, but since real auth/Firestore now exists (Phase 3), it makes more sense to build them directly against real data in Phase 4 rather than mock-then-rebuild. Moved there.

### Phase 3 — Firebase backend & full auth system ✅ done

The whole backend foundation, not just auth — this phase grew large in practice and is now complete.

- [x] Firebase project created, `flutterfire configure` run for all 3 platforms, packages wired into `bootstrap.dart`
- [x] Project upgraded to **Blaze** plan — unlocked Cloud Storage, Cloud Functions, Phone Auth (see §5 for the free-Spark-vs-Blaze history)
- [x] Firestore database created
- [x] Firestore security rules written ([firestore.rules](../firestore.rules)) — public read for `products`/`categories`, owner-or-admin for `users`/`orders`, public-read/owner-write `phone_index` for the phone pre-check
  - [ ] **Action item (you):** republish — the file changed after the last publish (added `phone_index`); Firestore denies reads/writes on anything not covered by whatever's currently live
- [x] Real `auth` feature slice — [lib/features/auth](../lib/features/auth), full domain/data/presentation, `AuthRepository`/`AuthRemoteDatasource`/usecases
- [x] Email/password sign-in & sign-up, wired into `AccountBloc` and the dialogs; `users/{uid}` Firestore doc created on sign-up (`role: 'customer'`)
- [x] Phone (SMS OTP) sign-in & sign-up — real `sendPhoneOtp`/`verifyPhoneOtp`, 6-digit box UI, real resend, Android SHA fingerprints + Play Integrity API enabled
- [x] Phone account-existence checks — sign-in with an unregistered number is rejected pre-OTP (`phone_index` check, fails open on error); sign-up with an already-registered number is rejected at verify-time
- [x] Google Sign-In — Android/Web done and tested; **iOS not wired**, blocked on Mac/Xcode access (see [IOS_SETUP.md](IOS_SETUP.md))
- [x] Forgot password (email) — `sendPasswordResetEmail`, Firebase hosts the reset page itself, no custom screen built
- [x] `AccountBloc` stays synced to Firebase's real auth state via `authStateChanges()` — signed-in sessions survive app restarts
- [x] Admin role-based routing — **proof-of-concept only**: placeholder `AdminDashboardPage` + `/admin` route, confirms `role: admin` → different landing page works end to end. Not the real admin dashboard (that's Phase 5); superseded once Phase 5 starts
- [x] `flutter analyze` / `flutter test` clean, web build verified after every change in this phase

### Phase 4 — Real data layer & customer flow 🚧 core commerce loop done, 2 items deferred to a follow-up pass

Firestore schema + swapping customer-facing mock data for real data, plus the 3 account sub-pages originally deferred from Phase 2.

- [x] Firestore data model: `categories` (with embedded `subcategories`) — `lib/features/home/data/models/category_model.dart`
- [x] Firestore data model: `products` — `lib/features/product/data/models/product_model.dart`, filtered by `categoryId`/`subcategoryId` via Firestore queries
- [x] Firestore data model: `orders` — new `order` feature (`lib/features/order/`), full domain/data/presentation
- [x] Swap `home`/`product` mock datasources for Firestore-backed ones — `HomeRemoteDatasource`/`ProductRemoteDatasource` replace the old mock ones; promo banners deliberately stayed local/static (marketing content, no admin banner management planned)
- [x] One-off seed script — `lib/tools/seed_data.dart`, run via `flutter run -t lib/tools/seed_data.dart -d chrome`, signs in as an admin and batch-writes the same 9 categories / 25 products the old mock data had
  - [ ] **Action item (you):** run it once against the real project
- [x] Swap `cart` to real, persisted (per-user) data — `users/{uid}/cart/{productId}` (quantity only; product data resolved fresh from `products` on every read, so cart never shows stale price/stock). **Now requires sign-in** — adding to cart while signed out shows a toast + opens sign-in, `CartBloc` reloads/empties the cart automatically on sign-in/out
- [x] Real checkout / order placement — `CheckoutBloc` (new, checkout was presentation-only before) writes a real `orders` doc; order confirmation page shows the real order ID; cart clears only after a confirmed write, not optimistically
- [x] Order history UI wired to real orders — new `OrderHistoryBloc`, replaces the old page-local mock `_Order` list
- [x] Firestore security rules updated for the above: `users/{uid}/cart/{productId}` (owner-only); `orders` already supported the right shape from Phase 3
- [x] `flutter analyze` / `flutter test` clean, web build verified after every step
  - [ ] **Action item (you):** republish `firestore.rules` again — changed once more (added the cart subcollection rule)

**Deferred to a follow-up pass** (not blocking anything above, address/profile data isn't referenced by cart/checkout/orders):
- [ ] Address management UI, wired to real user profile data
- [ ] Edit profile UI, wired to real user profile data

### Phase 5 — Admin/manager side 🚧 shell + dashboard done

- [x] Real admin shell — replaces the Phase 3 proof-of-concept. Responsive nav (`ResponsiveBuilder`, existing breakpoint helper): bottom `NavigationBar` on mobile, `NavigationRail` on tablet/desktop. 4 sections: Dashboard, Products, Categories, Orders. Deliberately its own shell/header (`AdminShellPage`, `AdminHeader`), not the customer `MainShell`/`AppHeader` — a search bar and cart badge don't belong in a back-office context
- [x] Real admin dashboard — quick-stat cards (product/category/order counts, pending orders) via lightweight Firestore `.count()` aggregate queries, not full document scans. New `DashboardBloc`/`AdminDashboardRepository`
- [x] **Route guard added** — closed a real gap the shell work turned up: `/admin` had *no* access control at all (anyone could reach it by URL). `app_router.dart` now has a top-level `redirect` gating any `/admin*` path to `role: admin`, reactively (via `GoRouterRefreshStream` wrapping `AccountBloc`'s stream — signing out while already on an admin page kicks you out immediately, not just on next navigation). Verified: deep-linking to `#/admin` while signed out correctly redirects to `#/home`
- [x] Products/Categories/Orders tabs exist and are navigable now, showing a clean placeholder until their turn below (not blank/missing)
- [x] `flutter analyze` / `flutter test` clean, web build verified, route guard verified live in-browser
- [x] Product management (CRUD, no photo upload yet — see below) — same shape as category management: `AdminProductRepository` (adds unscoped `getAllProducts()`, since the customer-side `ProductRepository` only ever reads scoped by category), `AdminProductRemoteDatasource`, `GetAllProductsUseCase`/`CreateProductUseCase`/`UpdateProductUseCase`/`DeleteProductUseCase`. Presentation: `AdminProductListBloc`, `AdminProductFormBloc` (one per visit), `AdminProductFormPage` (pushed, `/admin/products/form`) with name/price/unit/category+subcategory dropdowns/condition/origin/description/in-stock toggle. `iconKey` isn't a form field — it's derived from the selected category (matches seed data; `ProductImage` doesn't actually use it, only `imageUrl`). New products get a Firestore auto-generated id (unlike categories, products have no natural stable slug). `flutter analyze`/`flutter build web`/`flutter test` clean; live-browser check confirmed the app boots and all new chunks load, but the authenticated CRUD flow itself wasn't driven end-to-end in-browser (no admin test credentials in-session) — worth a manual spot-check
- [ ] Product photo upload — Firebase Cloud Storage + Security Rules (`role: admin` gated), "Resize Images" Extension for thumbnail/card/detail sizes
- [x] Category management — full CRUD. New `AdminCategoryRepository` (write-side, kept separate from the read-only `HomeRepository` per Interface Segregation; list-read still reuses the existing `GetCategoriesUseCase`), `AdminCategoryRemoteDatasource`, `CreateCategoryUseCase`/`UpdateCategoryUseCase`/`DeleteCategoryUseCase`. Presentation: `CategoryListBloc` (list + delete, flag-based state so a delete-in-progress doesn't blank the list) and `CategoryFormBloc` (one per form visit, matches `CheckoutBloc`). Add/edit is a full pushed page (`AdminCategoryFormPage`, root navigator, `/admin/categories/form`) not a dialog — name field, new `IconPicker` grid widget, variable-length subcategory editor. Category/subcategory ids are auto-slugified from name at creation (new `core/utils/slugify.dart`), fixed thereafter. New reusable `showConfirmDialog` (`shared/widgets/dialogs/confirm_dialog.dart`) backs the delete confirmation — first confirmation-dialog pattern in the app, built on the existing `showBlurredDialog`/`DialogCard` shell. Expanded `category_icons.dart`'s icon palette (9 → 20) so newly created categories aren't stuck with the generic fallback icon. `flutter analyze`/`flutter build web`/`flutter test` clean; live-browser check confirmed the app boots and all new route/page/bloc JS chunks compile and load without error, but the authenticated admin CRUD flow itself wasn't driven end-to-end in-browser (no admin test credentials available in this session) — worth a manual spot-check
- [ ] Order management (view all orders, update status)

### Phase 6 — Stripe payments ⬜

- [ ] Firebase Cloud Function to create PaymentIntents (holds the Stripe secret key — can't be done client-side alone)
- [ ] Customer-side payment flow (`flutter_stripe` package)
- [ ] Admin-side payment/receipt visibility
- [ ] Order status updates on payment success (Cloud Function or webhook)

### Phase 7 — iOS finalization & polish ⬜

- [ ] Full checklist in [IOS_SETUP.md](IOS_SETUP.md): first real iOS build/test, Google Sign-In `Info.plist` wiring, APNs key for smoother Phone Auth, real Bundle ID
- [ ] Apple's "Sign in with Apple" requirement — needed for App Store approval once Google Sign-In is included (`sign_in_with_apple` package)
- [ ] Dark mode toggle (theme already supports it, `AppTheme.dark` — just needs a switch wired to `ThemeMode`)
- [ ] Additional locales, if requested
- [ ] Real Android package name (currently the `com.example.everyday_wholesale` placeholder — must change before Play Store submission)
