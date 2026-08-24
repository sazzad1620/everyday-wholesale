# Everyday Wholesale — Project Plan

Source of truth for what this app is, why it's built the way it is, and the technical decisions behind it. If a future decision contradicts this file, update this file in the same change.

## 1. Product

**Everyday Wholesale** is a grocery ordering app. Customers browse grocery products and place orders; admins/managers manage the catalog and fulfil orders. Primary purpose: sell grocery products of different types.

## 2. Client requirements

1. Company: Everyday Wholesale — sells grocery products of different types.
2. Optimized for Android, iOS, and Web.
3. Two user roles in one app:
   - **Customer**: login, browse products, order, pay online (payment gateway added later).
   - **Admin/Manager**: login, manage products, view/manage orders and order status, receive payment via the payment gateway.
4. UI design follows [gunmahalalfood.com](https://gunmahalalfood.com/) initially, subject to change on client request. Screenshots from that site are provided to design each page.
5. Payment gateway: **Stripe** (integrated later, not part of the initial build).

## 3. Developer decisions

1. **Flutter, single codebase** for Android, iOS, and Web.
2. **Clean layered architecture** (data / domain / presentation), **feature-first**, SOLID principles, **pure BLoC** for state management (no Cubit, no mixed styles).
   - Reference project: `docs/VanSalesPro` (git-ignored, not part of this app) — used only to inform architecture/pattern conventions, not copied wholesale. It's a different type of app (van sales/distribution); only the parts relevant to Everyday Wholesale are adapted.
3. **Firebase** (free tier where possible) is the backend for as much data handling as feasible.
4. **English only for now**, but strings live in translation files (`assets/translations/en.json`) so more languages can be added later without code changes.
5. **Light theme only for now**, but the theme system is built to support dark mode later without rework.
6. **Modularized** as much as practical — no hardcoded strings/colors/spacing in UI files; everything comes from shared modules so the UI stays visually consistent.
7. UI pages are designed from screenshots of gunmahalalfood.com supplied to the AI agent.
8. **Build order**: project structure/foundation first → UI-first customer-side build with a few mock data points on the home page (no backend, no admin) → Firebase integration once the UI is in place → real data replaces mocks.

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
  app/                    # bootstrap.dart (DI + localization init + runApp), app.dart (MaterialApp.router)
  config/
    di/                   # get_it + injectable wiring (injection_container.dart, generated .config.dart)
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

Every new feature replicates the `data/domain/presentation` structure shown by the `splash` feature (the reference implementation built during foundation setup).

### 4.3 Tech stack and why

| Concern | Choice | Why |
|---|---|---|
| State management | `flutter_bloc` + `equatable` | Client requirement: pure BLoC, no Cubit |
| Dependency injection | `get_it` + `injectable` (codegen) | Matches reference project; scales cleanly as features grow |
| Routing | `go_router` | Official Flutter package; strong web URL/deep-link support (reference project's `fluro` is weaker for web, and web is a hard requirement here) |
| Error handling | `fpdart` (`Either<Failure, T>`) | Same pattern as reference project's `dartz`, but actively maintained with better Dart 3 support |
| Localization | `easy_localization` | Uses literal `assets/translations/en.json` files as requested; simple to add more locales later |
| Responsive layout | Custom breakpoint helper (`core/utils/responsive`), no package | Reference project's `flutter_screenutil` scales by mobile width, which actively fights responsive web/desktop layouts — a hard requirement here |
| Backend | Firebase (Auth, Firestore, Storage; Cloud Functions likely for Stripe) | Client requirement, free tier where possible — **not yet added**, deferred to the Firebase integration phase |
| Payments | Stripe | Client requirement — **not yet integrated**, deferred until backend + order flow exist |
| Models | Manual `fromMap`/`toMap` | Matches reference project; keeps codegen surface limited to `injectable` |

### 4.4 Naming conventions

- Bloc: three files per bloc — `{name}_bloc.dart`, `{name}_event.dart`, `{name}_state.dart`.
- Domain repository interface: `{Name}Repository` (abstract). Data implementation: `{Name}RepositoryImpl`.
- One usecase per file, extends `UseCase<ReturnType, Params>`.
- Pages live in `presentation/pages`, feature-local widgets in `presentation/widgets`, cross-feature widgets in `shared/widgets`.

### 4.5 Explicitly deferred (not built yet)

- Firebase packages/integration (`firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_storage`, likely `cloud_functions` for Stripe).
- Stripe integration.
- Real Home UI with product data (currently a bare placeholder).
- `auth`, `product`/`catalog`, `cart`, `checkout`, `orders` features (customer side).
- Login/signup, address management, and order-history UI (currently inline mock buttons / "coming soon" stubs / no entry point in `account_sheet.dart`) — see Phase 2.
- `admin` feature group: dashboard, product management, order management (manager side).
- Dark mode toggle (theme exists, not wired to a switch).
- Additional locales beyond English.

## 5. Roadmap (phases)

1. **Foundation** ✅ — project structure, dependencies, DI/router/theme/localization boilerplate, one fully-wired template feature (Splash → Home placeholder). See [IMPLEMENTATION.md](IMPLEMENTATION.md) for status.
2. **UI-first customer build** — real Home page UI with mock/hardcoded product data, no backend. Also product listing/detail, cart, and checkout screens, plus login/signup and account sub-pages (address management, edit profile, order history) as static UI against mock data, built from gunmahalalfood.com screenshots.
3. **Firebase integration** — Firestore data models for products/orders/users, Firebase Auth for customer + admin/manager login, Firebase Storage for product images. Mock data sources swapped for Firebase-backed ones behind the existing repository interfaces (no presentation-layer changes needed, by design).
4. **Customer features end-to-end** — auth, product catalog, cart, checkout, order placement, order history/status — wired to real Firebase data.
5. **Admin/manager side** — dashboard, product management (CRUD), order management, order status updates.
6. **Stripe integration** — online payment on the customer side, payment receipt on the admin side. Requires a Cloud Function (or similar backend) to create PaymentIntents securely — client-side Stripe calls alone aren't safe for this.
7. **Polish** — dark mode wiring, additional locales if requested, further platform-specific optimizations.

## 6. Design source

UI is built from screenshots of [gunmahalalfood.com](https://gunmahalalfood.com/) supplied per-page/per-flow. The client may request a different design direction later; when that happens, this file and the relevant feature's UI should be updated together.
