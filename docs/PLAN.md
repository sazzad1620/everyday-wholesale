# Everyday Wholesale — Project Plan & Status

Single source of truth for what this app is, why it's built the way it is, the technical decisions behind it, and what's actually done vs. still to build. If a future decision contradicts this file, update this file in the same change. **§7 (Roadmap & Status) is the living checklist** — update it whenever a phase or task changes status; it should always reflect the real state of the code, not aspiration.

> Companion docs: [BACKEND_SETUP.md](BACKEND_SETUP.md) (beginner-friendly Firebase console walkthrough), [IOS_SETUP.md](IOS_SETUP.md) (exact checklist for when Mac/Xcode access is available), [PAYMENTS_PLAN.md](PAYMENTS_PLAN.md) (Phase 6 sub-plan — Stripe integration broken into its own phased checklist).

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
  - [x] Republished — verified live via unauthenticated Firestore REST reads: `products`/`categories`/`phone_index` return 200 (public read), `users` returns 403 (owner-or-admin only), matching the current rules file exactly
- [x] Real `auth` feature slice — [lib/features/auth](../lib/features/auth), full domain/data/presentation, `AuthRepository`/`AuthRemoteDatasource`/usecases
- [x] Email/password sign-in & sign-up, wired into `AccountBloc` and the dialogs; `users/{uid}` Firestore doc created on sign-up (`role: 'customer'`)
- [x] Phone (SMS OTP) sign-in & sign-up — real `sendPhoneOtp`/`verifyPhoneOtp`, 6-digit box UI, real resend, Android SHA fingerprints + Play Integrity API enabled
- [x] Phone account-existence checks — sign-in with an unregistered number is rejected pre-OTP (`phone_index` check, fails open on error); sign-up with an already-registered number is rejected at verify-time
- [x] Google Sign-In — Android/Web done and tested; **iOS not wired**, blocked on Mac/Xcode access (see [IOS_SETUP.md](IOS_SETUP.md))
- [x] Forgot password (email) — `sendPasswordResetEmail`, Firebase hosts the reset page itself, no custom screen built
- [x] `AccountBloc` stays synced to Firebase's real auth state via `authStateChanges()` — signed-in sessions survive app restarts
- [x] Admin role-based routing — **proof-of-concept only**: placeholder `AdminDashboardPage` + `/admin` route, confirms `role: admin` → different landing page works end to end. Not the real admin dashboard (that's Phase 5); superseded once Phase 5 starts
- [x] `flutter analyze` / `flutter test` clean, web build verified after every change in this phase

### Phase 4 — Real data layer & customer flow ✅ done

Firestore schema + swapping customer-facing mock data for real data, plus the 3 account sub-pages originally deferred from Phase 2.

- [x] Firestore data model: `categories` (with embedded `subcategories`) — `lib/features/home/data/models/category_model.dart`
- [x] Firestore data model: `products` — `lib/features/product/data/models/product_model.dart`, filtered by `categoryId`/`subcategoryId` via Firestore queries
- [x] Firestore data model: `orders` — new `order` feature (`lib/features/order/`), full domain/data/presentation
- [x] Swap `home`/`product` mock datasources for Firestore-backed ones — `HomeRemoteDatasource`/`ProductRemoteDatasource` replace the old mock ones; promo banners deliberately stayed local/static (marketing content, no admin banner management planned)
- [x] One-off seed script — `lib/tools/seed_data.dart`, run via `flutter run -t lib/tools/seed_data.dart -d chrome`, signs in as an admin and batch-writes the same 9 categories / 25 products the old mock data had
  - [x] Run against the real project — verified live: `categories` has 9 docs, `products` returns real seeded entries (e.g. `bv_1` "Mango Juice") via Firestore REST reads
- [x] Swap `cart` to real, persisted (per-user) data — `users/{uid}/cart/{productId}` (quantity only; product data resolved fresh from `products` on every read, so cart never shows stale price/stock). **Now requires sign-in** — adding to cart while signed out shows a toast + opens sign-in, `CartBloc` reloads/empties the cart automatically on sign-in/out
- [x] Real checkout / order placement — `CheckoutBloc` (new, checkout was presentation-only before) writes a real `orders` doc; order confirmation page shows the real order ID; cart clears only after a confirmed write, not optimistically
- [x] Order history UI wired to real orders — new `OrderHistoryBloc`, replaces the old page-local mock `_Order` list
- [x] Firestore security rules updated for the above: `users/{uid}/cart/{productId}` (owner-only); `orders` already supported the right shape from Phase 3
- [x] `flutter analyze` / `flutter test` clean, web build verified after every step
  - [x] Republished — `firestore.rules` hasn't changed since the commit that added this rule, and live reads already confirm that same file is deployed (see the Phase 3 rules check above), so this later addition is live too

**Deferred to a follow-up pass — now done:**
- [x] Address management — one saved address per account (not an address book), matching real usage: nothing in the app needs multiple addresses yet. New `AddressEntity`/`AddressModel` embedded as a Firestore map on `users/{uid}` (`AuthRepository.updateAddress`/`UpdateAddressUseCase`, `AccountBloc` gained `AccountAddressUpdateRequested`/`addressUpdated`). Fields follow the Japanese addressing convention (receiver name, phone, postal code, state/prefecture, city, street, chome-banchi-go, optional building name) since every address in the app is a Japanese one. New `AddressFormPage` (`/account/address`) is the single edit surface, reached from both Account > Address and the checkout delivery-address card's "Edit"/"Add" link — one saved address, one place to edit it, everywhere else just reads it. Checkout's `DeliveryAddressCard` now shows the real saved address (or a "no address saved" prompt) instead of mock text, and `CheckoutOrderPlaceRequested` now sends the real address/phone instead of the old placeholder strings; placing an order without a saved address shows a toast instead of silently using fake data. No Firestore rule changes needed (address is just a field within the existing owner-writable `users/{uid}` doc). `flutter analyze`/`flutter build web`/`flutter test` clean; live-browser check confirmed the app boots and every new file loads without error — the actual save/display flow wasn't driven end-to-end in-browser (no test account signed in this session)
- [x] Edit profile UI — deliberately minimal: only the display name is actually editable (`AuthRepository.updateName`/`UpdateNameUseCase`, `AccountBloc` gained `AccountNameUpdateRequested`/`nameUpdated`, keeps Firebase Auth's `displayName` in sync too). Email and phone are shown but not editable — both are tied to the sign-in credential itself, and changing either for real is a Firebase re-authentication flow, not a plain field write. New `EditProfilePage` (`/account/edit-profile`, reached from the existing Account > Edit Profile row): all three fields use the same normal `AppInputStyle.decoration()` look/size as everywhere else in the app (no visual "locked" styling) — email/phone are just `readOnly: true` `TextFormField`s whose `onTap` shows a "Primary contact cannot be changed" toast instead of allowing input; the phone field is omitted entirely for accounts with none (email sign-ups). No Firestore rule changes needed. `flutter analyze`/`flutter build web`/`flutter test` clean; live-browser check confirmed every new file loads without error — the actual save flow wasn't driven end-to-end in-browser (no test account signed in this session)
- [x] Product search — the header's `AppSearchBar` (Home/category/product-list pages) was a visual-only "coming soon" placeholder until now. It's a real text field in place now; typing opens a floating results dropdown anchored just below the bar (`OverlayEntry` + `CompositedTransformFollower`/`CompositedTransformTarget`, closed via `TapRegion.onTapOutside`) rather than navigating to a separate page — each row is a small thumbnail with the name and price (small, muted) below it, tapping one goes straight to that product's detail page. `ProductRepository`/`ProductRemoteDatasource` gained `searchProducts(query)` — fetches the `products` collection and filters client-side by case-insensitive substring match on name (no Firestore full-text search; the catalog is small enough that this is simpler than a prefix-range query or a search index service). New `SearchBloc`/`SearchProductsUseCase` debounce each keystroke ~350ms via a bumped request-id check (no extra `bloc_concurrency` dependency) before querying. `flutter analyze` clean, DI codegen regenerated — not driven end-to-end in-browser this session

### Phase 5 — Admin/manager side ✅ done

- [x] Real admin shell — replaces the Phase 3 proof-of-concept. 4 sections: Dashboard, Products, Categories, Orders.
- [x] **Admin shell UI overhaul** (after manual review found the shell felt inconsistent with the rest of the app): header is now the plain shared `AppHeader` (logo/wordmark + hamburger + account icon, no search bar) instead of a bespoke `AdminHeader` — unifies the look with every customer page instead of running two different header styles. Navigation is a new `AdminMenuDrawer` (`shared`-style drawer matching `MainMenuDrawer`'s shape) opened from that hamburger, replacing the old bottom `NavigationBar` on mobile entirely — a drawer is the standard admin-panel pattern (Shopify, the Firebase console itself) and unifies the interaction model with the customer side's own hamburger-opens-drawer navigation instead of two different nav idioms. Tablet/desktop keeps the always-visible `NavigationRail` alongside the same drawer (confirmed: wide screens have room for both, so the rail stays the primary desktop nav). The admin's name and Logout — previously in the old header — moved into the drawer, same spot `MainMenuDrawer` would put account info. Old `AdminHeader` widget deleted (fully unused after the swap). `flutter analyze`/`flutter build web`/`flutter test` clean; live-browser check confirmed the new drawer/shell files load without error — the actual authenticated look wasn't screenshotted end-to-end (no admin test credentials in this session)
- [x] Real admin dashboard — quick-stat cards (product/category/order counts, pending orders) via lightweight Firestore `.count()` aggregate queries, not full document scans. New `DashboardBloc`/`AdminDashboardRepository`
- [x] **Route guard added** — closed a real gap the shell work turned up: `/admin` had *no* access control at all (anyone could reach it by URL). `app_router.dart` now has a top-level `redirect` gating any `/admin*` path to `role: admin`, reactively (via `GoRouterRefreshStream` wrapping `AccountBloc`'s stream — signing out while already on an admin page kicks you out immediately, not just on next navigation). Verified: deep-linking to `#/admin` while signed out correctly redirects to `#/home`
- [x] **Form field text size unified app-wide** — the new `AppDropdownField` (14sp, explicit `AppTextStyles.body`) read smaller than every plain `TextFormField` next to it, which had no explicit `style:` and so fell back to Material 3's own default (`bodyLarge`, 16sp) instead of the app's actual 14sp body size. Fixed at the theme level, not per-field: `AppTheme`'s `textTheme` now sets `bodyLarge: AppTextStyles.body` too (light and dark), so every text field in the app — this form and every other one — renders at the app's intended 14sp by default, matching the dropdown without having to touch each field individually. `flutter analyze`/`flutter build web`/`flutter test` clean; live-browser check confirmed the home page (search bar, wordmark) renders correctly with no layout regression from the smaller default text
- [x] **Product form dropdowns fixed** — reported from a screenshot: category/subcategory dropdown text rendered bold (inherited from stock `DropdownButtonFormField`'s default text theme) and the open menu stretched full-screen-width with square corners, ignoring the field's own rounded width. Replaced both with a new shared `AppDropdownField<T>` (`shared/widgets/inputs/app_dropdown_field.dart`) — a `FormField<T>` styled like every other input (`AppInputStyle`'s flat rounded box, normal-weight text), whose popup menu is anchored and width-matched to the field itself via `showMenu`'s `constraints`, with matching rounded corners. Subcategory selection is now mandatory (validator added, "(optional)" dropped from the hint) whenever the chosen category actually has subcategories — previously optional despite categories requiring one. `flutter analyze`/`flutter build web`/`flutter test` clean; live-browser check confirmed the new shared widget file loads without error — the actual dropdown interaction wasn't clicked through end-to-end in-browser (no admin test credentials in this session)
- [x] **Startup-routing bug fixed** — reported as "after restarting, an admin sees the customer view; only re-logging in shows the admin panel." Root cause: `SplashPage` always routed to `/home` once its (fake, 1.2s-timer) "ready" check finished, regardless of who's signed in — the *only* place that ever sent an admin to `/admin` was the sign-in dialog's own explicit check, which never runs on a cold restart with an already-persisted session. Fixed by giving `AccountState` a real `isInitializing` flag (true only for the app's very first state, before Firebase Auth's persisted session has been checked; `AccountState.initial()` vs. the existing `.guest()`) and having `SplashPage` wait for that to resolve (bounded by a 5s timeout so a stalled check can never hang the splash screen) before routing — admins now land on `/admin`, everyone else on `/home`, on cold start same as on sign-in. `flutter analyze`/`flutter build web`/`flutter test` clean; live-browser check confirmed the signed-out path still resolves to `/home` correctly with no hang — the admin path itself wasn't verified end-to-end (no admin test credentials in this session)
- [x] Products/Categories/Orders tabs exist and are navigable now, showing a clean placeholder until their turn below (not blank/missing)
- [x] `flutter analyze` / `flutter test` clean, web build verified, route guard verified live in-browser
- [x] Product management (CRUD, no photo upload yet — see below) — same shape as category management: `AdminProductRepository` (adds unscoped `getAllProducts()`, since the customer-side `ProductRepository` only ever reads scoped by category), `AdminProductRemoteDatasource`, `GetAllProductsUseCase`/`CreateProductUseCase`/`UpdateProductUseCase`/`DeleteProductUseCase`. Presentation: `AdminProductListBloc`, `AdminProductFormBloc` (one per visit), `AdminProductFormPage` (pushed, `/admin/products/form`) with name/price/unit/category+subcategory dropdowns/condition/origin/description/in-stock toggle. `iconKey` isn't a form field — it's derived from the selected category (matches seed data; `ProductImage` doesn't actually use it, only `imageUrl`). New products get a Firestore auto-generated id (unlike categories, products have no natural stable slug). `flutter analyze`/`flutter build web`/`flutter test` clean; live-browser check confirmed the app boots and all new chunks load, but the authenticated CRUD flow itself wasn't driven end-to-end in-browser (no admin test credentials in-session) — worth a manual spot-check
- [x] Product photo upload — new `firebase_storage`/`image_picker` dependencies; `AdminProductRepository.uploadProductImage` (+ `UploadProductImageUseCase`, `FirebaseStorage` added to `firebase_module.dart`) uploads to `product_images/{timestamp}.{ext}` and returns the download URL, which the product form saves as `imageUrl` on submit. New `ProductImagePicker` widget (reuses the existing `ProductImage` placeholder) drives pick → upload → preview inline on the form. New [storage.rules](../storage.rules) (public read, `role: admin` write via a cross-service `firestore.get()` check, 5MB/image-type cap) — Cloud Storage enabled and rules published: verified live, a real seeded product's `imageUrl` (`product_images/1787928394277467.png`) fetches with 200 (public read works) while listing the bucket root returns 403 (not openly listable, matching the rules' intent). "Resize Images" Extension still optional/not installed
- [x] Category management — full CRUD. New `AdminCategoryRepository` (write-side, kept separate from the read-only `HomeRepository` per Interface Segregation; list-read still reuses the existing `GetCategoriesUseCase`), `AdminCategoryRemoteDatasource`, `CreateCategoryUseCase`/`UpdateCategoryUseCase`/`DeleteCategoryUseCase`. Presentation: `CategoryListBloc` (list + delete, flag-based state so a delete-in-progress doesn't blank the list) and `CategoryFormBloc` (one per form visit, matches `CheckoutBloc`). Add/edit is a full pushed page (`AdminCategoryFormPage`, root navigator, `/admin/categories/form`) not a dialog — name field, new `IconPicker` grid widget, variable-length subcategory editor. Category/subcategory ids are auto-slugified from name at creation (new `core/utils/slugify.dart`), fixed thereafter. New reusable `showConfirmDialog` (`shared/widgets/dialogs/confirm_dialog.dart`) backs the delete confirmation — first confirmation-dialog pattern in the app, built on the existing `showBlurredDialog`/`DialogCard` shell. Expanded `category_icons.dart`'s icon palette (9 → 20) so newly created categories aren't stuck with the generic fallback icon. `flutter analyze`/`flutter build web`/`flutter test` clean; live-browser check confirmed the app boots and all new route/page/bloc JS chunks compile and load without error, but the authenticated admin CRUD flow itself wasn't driven end-to-end in-browser (no admin test credentials available in this session) — worth a manual spot-check
- [x] Order management — full view + status control, completing Phase 5. New `AdminOrderRepository` (unscoped `getAllOrders()` + `updateOrderStatus()`, mirroring the `AdminCategoryRepository`/`AdminProductRepository` write-side-split pattern; customer-facing `OrderRepository` stays scoped to `customerId == current uid`), `AdminOrderRemoteDatasource`, `GetAllOrdersUseCase`/`UpdateOrderStatusUseCase`. Presentation: `AdminOrderListBloc` (flag-based state like `CategoryListBloc` — updating one order's status doesn't blank the list), `AdminOrdersPage` replacing the placeholder with the same header-bar order card as the customer-side order history, plus a tappable status pill (pending/completed/cancelled, color-coded) that opens a small popup menu to change status inline — no separate form page needed. No Firestore rule changes needed (`orders` already allowed admin read/update from Phase 3). `flutter analyze` clean; DI codegen regenerated (`dart run build_runner build`) and confirmed the new bloc/usecases/repository registered — not driven end-to-end in-browser (no admin test credentials in this session)
- [x] Order detail pages (customer + admin) — tapping either order card now opens a full detail screen instead of doing nothing. No new Firestore reads: both list pages already hold the complete `OrderEntity` (items, cost fields, address), so it's carried via route `extra` and rendered straight away, same trick `ProductDetailPage` uses for its own `extra` fields. Pulled the pieces that were duplicated between the customer/admin cards into shared `lib/features/order/presentation/widgets/`: `OrderIdHeaderBar`, `OrderInfoRow`, `OrderStatusPill` (nullable `onChanged` — plain read-only chip for customer, tappable popup for admin), plus two new ones for the detail view: `OrderItemTile` (thumbnail/name/unit/qty/line-total) and `OrderAddressCard`. Cost breakdown needed zero new code — `OrderEntity`'s totals fields map directly onto the existing `CartTotals` value object, so `OrderDetailContent` (the shared layout composing all of the above) just reuses the already-shared `CartTotalsBreakdown` from cart/checkout. Two thin page wrappers around that shared content, matching how customer/admin already stay separate elsewhere: `account/presentation/pages/order_detail_page.dart` (stateless, read-only) and `admin/presentation/pages/admin_order_detail_page.dart` (owns a new `AdminOrderDetailBloc` — same one-shot-submission shape as `CategoryFormBloc` — to persist a status change, with optimistic UI + revert-on-failure; pops `true` on a real change so the list behind it refreshes, same "push, refresh if true" pattern the category/product forms already use). Two new routes (`orderDetail`, `adminOrderDetail`), both root-navigator pushes with a null-safe `extra` fallback (a missing/reloaded `extra` falls back to the list page instead of crashing on a force-unwrap, matching how `OrderConfirmationPage` already treats its own nullable `extra`). `flutter analyze` clean, DI codegen regenerated — not driven end-to-end in-browser this session
  - **Follow-up fix** (screenshot review found the address card reading oddly): `AddressEntity.formattedLine` was ordering largest-region-first (state, city, street, block, building) — flipped to the standard smallest-first order (building, block/house number, street, city, state). Also split the receiver's name off `OrderEntity.addressLine` into its own new nullable field (`addressReceiverName`) instead of it being pre-glued onto the address text at checkout time (`'$name, $address'`) — `OrderAddressCard` now shows name, then phone, then address, each on their own line, instead of one run-on line. Threaded the new field through `OrderRepository.placeOrder`/`PlaceOrderUseCase`/`CheckoutBloc`/`CheckoutOrderPlaceRequested`/`OrderModel`. Backward-compatible: orders placed before this change have no `addressReceiverName` (reads as `null`) and keep rendering exactly as before — only new orders get the separated name line. Verification also turned up an unrelated pre-existing bug: `OrderHistoryPage` never actually wrapped its content in a `Scaffold` despite its own doc comment claiming it did, so `AppHeader`'s account-icon button had no `Material` ancestor and crashed the page — fixed by wrapping it in a plain `Scaffold`, matching every other "drilled into" page (`EditProfilePage`/`AddressFormPage`/checkout). `flutter analyze` / `flutter test` clean; verified live via a real checkout run in-browser
  - **Added a `processing` order status** — `pending → processing → completed`, `cancelled` reachable from either. Previously an order jumped straight from `pending` to `completed` with no way to signal "accepted, being prepared." One-line addition to the `OrderStatus` enum (Dart's exhaustive `switch` in `OrderStatusPill` caught every place that needed updating); new `AppColors.info` (blue) added for its pill color, distinct from `secondary` (pending) and `primary` (completed). Firestore-safe: `OrderStatusX.parse` already falls back to `pending` for any unrecognized string, so existing orders are unaffected. `flutter analyze` clean
  - **Admin could accidentally end up in the customer storefront** — the header's account icon always pushed the shared, customer-facing `AccountPage`, which (via `StandaloneShellScaffold`) carries the Home/Wishlist/Cart bottom nav; an admin tapping any of those tabs landed in the customer shell with no way back except the browser/OS back button. Fixed with a dedicated `AdminAccountPage` (plain `Scaffold`, no bottom nav) — just avatar/name/email, Edit Profile, and Logout, dropping Address/Order History/My Reviews since none apply to an admin account. `openAccountMenu` now branches on `user.isAdmin` to push it instead of the customer `AccountPage`. New `/admin/account` route sits under the existing `/admin*` role guard for free. Also hardened `app_router.dart`'s top-level `redirect`: previously it only ever kicked non-admins *out* of `/admin*`; it now also bounces a signed-in admin *back* to `/admin` if they land on `/home` (or anything nested under it), `/wishlist`, or `/cart` by any other means (stale link, browser back/forward on web) — so there's no path, not just no button, into the customer view while signed in as admin. `flutter analyze` clean
  - **Real product reviews** — "My Reviews" was a coming-soon stub, and product ratings were fake mock data embedded directly in each `products/{id}` doc (a hardcoded `reviews` array from the seed script; `ProductCard`'s star row didn't even read it, just always rendered 5 empty outline stars). Replaced with a proper `review` feature: new top-level `reviews/{orderId}_{productId}` Firestore collection (deterministic id — one rating per completed order+product pair, matching the client's confirmed answer that repeat purchases can each be rated separately rather than one rating per product for life), `ReviewEntity`/`ReviewModel`/`ReviewRepository` (`getMyReviews`, `getProductReviews`, `getAllReviews`, `submitReview`). Submitting a review is a single Firestore **batch** (not a transaction — pure increments need no prior read): writes the review doc and bumps two new denormalized fields on the product doc, `ratingSum`/`reviewCount` (via `FieldValue.increment`), so every star-rating display reads instantly off the product doc with no extra query. `ProductEntity` dropped its old embedded `reviews`/derived-getter shape for these two stored fields plus a `rating` getter (`ratingSum / reviewCount`); deleted the now-unused `ProductReviewEntity`/`ProductReviewModel`. `ProductCard`'s star row and the product detail page's Review tab (now fetched via `ProductDetailBloc` alongside the product itself, name+stars only — no comment field exists in the new flow) both wired to the real data.
    - **Customer side**: `MyReviewsPage` (`/account/my-reviews`, reached from Account > My Reviews), two real tabs via `DefaultTabController`/`TabBar`: **To Be Reviewed** (every product from a `completed` order the customer hasn't yet rated *for that specific order* — computed client-side in `MyReviewsBloc` by diffing completed-order items against `getMyReviews()`'s result, one query covers both the exclusion set and the History tab's content) and **History** (every review they've submitted). Tapping a star (`StarRatingInput`, new shared write-side counterpart to the existing read-only `StarRating`) submits immediately — no separate confirm step — and the tapped card shows a spinner via a `submittingKey` in state (only that one card, not the whole list) while its own item quietly moves from To Be Reviewed to History on success.
    - **Admin side**: fifth admin section, "User Reviews" (`AdminReviewsPage`, `AdminReviewListBloc` — plain read-only list, same shape as the dashboard's reads), showing every review with reviewer name, product, stars, and date — added to `AdminShellPage`'s destinations list, which the drawer and desktop `NavigationRail` both already render generically, so no separate wiring needed there.
    - **Firestore rules**: new `reviews` collection — public read, `create` restricted to `reviewerId == auth.uid` with a `1–5` int rating and a `get()` check that the referenced order actually belongs to the caller, `update: if false` (a duplicate submission to the same deterministic id just fails outright instead of double-counting), `delete: if isAdmin()` only. `products`' existing `allow write: if isAdmin()` gained a narrow sibling `allow update` letting a signed-in customer touch *only* `ratingSum`/`reviewCount` (`diff().affectedKeys().hasOnly([...])`) — nothing else on the doc.
    - **Data reset**: per instruction, all the old fake seeded ratings are gone — `seed_data.dart`'s `_review()` helper and every product's `reviews: [...]` block deleted; each seeded product now starts at `ratingSum: 0, reviewCount: 0`. Re-running the seed script (`flutter run -t lib/tools/seed_data.dart -d chrome`) overwrites the live Firestore docs the same way, since it's a `.set()` keyed by fixed doc id — **action item (you)**: re-run it once to wipe the old fake ratings from the real project (existing real reviews, if any were somehow submitted before this, live in the separate `reviews` collection and are unaffected either way).
    - Also fixed a latent data-loss bug this surfaced: `AdminProductRepository.updateProduct` does a full `.set()` overwrite, and the admin product form was already carrying forward `widget.initial?.reviews` for exactly this reason — updated that same carry-forward to the new `ratingSum`/`reviewCount` fields so editing a product (e.g. changing its price) can no longer silently reset its accumulated rating to zero.
    - `flutter analyze` / `flutter test` clean, DI codegen regenerated — not driven end-to-end in-browser this session

### Phase 6 — Stripe payments ⬜

Big enough to warrant its own sub-plan — see **[PAYMENTS_PLAN.md](PAYMENTS_PLAN.md)** for the full architecture, decisions, and phased checklist (Cloud Functions backend → client payment flow → order status/history UI → admin visibility → production readiness). Check this item off only once every phase there is done.

### Phase 7 — iOS finalization & polish ⬜

- [ ] Full checklist in [IOS_SETUP.md](IOS_SETUP.md): first real iOS build/test, Google Sign-In `Info.plist` wiring, APNs key for smoother Phone Auth, real Bundle ID
- [ ] Apple's "Sign in with Apple" requirement — needed for App Store approval once Google Sign-In is included (`sign_in_with_apple` package)
- [ ] Dark mode toggle (theme already supports it, `AppTheme.dark` — just needs a switch wired to `ThemeMode`)
- [ ] Additional locales, if requested
- [ ] Real Android package name (currently the `com.example.everyday_wholesale` placeholder — must change before Play Store submission)
