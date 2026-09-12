# Japanese Bilingual Support — Implementation Plan

Goal: the whole system (customer app + admin side, on Android/iOS/Web) works in **English** and **Japanese**. The user picks a language; every screen, every product, every category, every order shows in that language.

This document is the agreed plan **and** the progress tracker — see **§9 (Roadmap & Status)** for what's done. Sections 1–8 describe the design and are not rewritten as work lands; only §9 checkboxes and §11 status change.

**Status: all 9 phases implemented** — Phases 2–9 awaiting developer commit; Phase 7 migration tool ready to run; Phase 9 has developer-side checks listed (admin + signed-in flows).

**Commit convention:** the developer reviews and commits each phase manually — the assistant never commits. Each phase's checklist notes the commit it landed in once that happens.

---

## 0. Decisions already made

| # | Decision | Choice |
|---|----------|--------|
| 1 | Required language for admin-entered text | **English required, Japanese optional.** Japanese falls back to English when empty. |
| 2 | App language on first launch | **Always English.** User switches to Japanese from Account (mobile) / header (web). Choice is remembered on the device. |
| 3 | Auto-translate button in admin form | **Not now.** Documented as a future idea (section 10). |
| 4 | `condition` / `origin` become dropdowns | **Yes** — stored as codes, translated by the app. |
| 5 | `unit` | **Stays a single language-neutral free-text field** (open question A → A1). |
| 6 | Origin country list | **Short list** (BD, IN, BR, JP, TH, VN, PH, ID, NP, LK, PK, CN, US, AU) — extend later as needed (open question B). |
| 7 | Condition list | **Keep the current five** — Fresh, Frozen, Dry / Packaged, Ambient, Freshly Prepared (open question C). |
| 8 | Language switcher placement | **Both** — `EN \| 日本語` toggle in the web/tablet header **and** a Language row in the phone drawer / account page (open question D). |
| 9 | Japanese translation review | First pass by developer; **client to arrange a native-speaker review** before release (open question E). |

---

## 1. Current state (what exists today)

- `easy_localization` is already set up in `lib/app/bootstrap.dart` with **only** `Locale('en')` and one file `assets/translations/en.json` (18 groups, ~268 keys).
- Almost every screen already uses `'key'.tr()`. The codebase is in good shape for step 1.
- **Not yet localized:**
  - Error messages: `lib/core/errors/failures.dart` (default English messages), `auth_remote_datasource.dart` `_messageForCode()` + 4 hardcoded `AuthException('...')`, and `AuthException` in cart / order / review datasources ("Please sign in to ...").
  - Dates: `DateFormat.yMMMMd()` / `yMMMd()` in 6 places with no locale passed (order history, admin orders, admin reviews, order detail, reviewable item card, review history tile).
  - Font: `GoogleFonts.oswald` is used for the header wordmark. Oswald has **no Japanese glyphs**. Body text uses the default Material font (fine for JA on device, but Web needs an explicit JA-capable font).
  - No language switcher UI anywhere.
- **Admin-entered text stored as plain `String` in Firestore:**
  - `products/{id}`: `name`, `description`, `unit`, `condition`, `origin`
  - `categories/{id}`: `name`, and `subcategories[].name`
  - Snapshots: `orders/{id}.items[].name`, `orders/{id}.items[].unit`, `reviews/{id}.productName`
- Search is client-side: `product.name.toLowerCase().contains(query)` in `product_remote_datasource.dart`.
- Existing values in `lib/tools/seed_data.dart`:
  - `condition`: Fresh, Frozen, Dry / Packaged, Ambient, Freshly Prepared
  - `origin`: Bangladesh, India, Brazil
  - `unit`: 1kg, 500g, 400g, 250g, 200g, 100g, 2kg, 5kg, 1L, 800ml, 10pcs, 20pcs, "1.5L x 6"

---

## 2. Two kinds of text, two solutions

| Kind | Examples | Solution |
|------|----------|----------|
| **A. Fixed UI text** | Search, Explore By Categories, Add To Cart, bottom nav, error messages, order statuses | `en.json` + new `ja.json`. Same keys, Japanese values. Already how the app works. |
| **B. Admin-entered text** | Product name, product description, category name, subcategory name | Store **both languages in one field** on the Firestore document (a map). App picks the one matching the current language. |
| **C. Admin-picked options** | Condition, origin (and maybe unit) | Store a **code** (`frozen`, `BD`). Translate the code with `en.json`/`ja.json`. Admin picks from a dropdown, types nothing. |

---

## 3. Data model — the `LocalizedText` field

### 3.1 Firestore shape

Before:
```json
{ "name": "Basmati Rice", "description": "Long grain ..." }
```

After:
```json
{
  "name":        { "en": "Basmati Rice",  "ja": "バスマティライス" },
  "description": { "en": "Long grain ...", "ja": "長粒米 ..." }
}
```

Why a map and not `name_en` / `name_ja`:
- One Dart value object handles the "which language, and what if it's empty" logic everywhere.
- A third language later = one more key, not a schema change across every model, form and screen.
- Firestore can still query `name.en` with dot-notation if ever needed.

### 3.2 Dart value object (new file `lib/core/localization/localized_text.dart`)

```dart
class LocalizedText extends Equatable {
  const LocalizedText({required this.en, this.ja = ''});
  final String en;   // required (decision #1)
  final String ja;   // optional

  /// Text for [locale]; falls back to English when Japanese is empty.
  String resolve(Locale locale) =>
      locale.languageCode == 'ja' && ja.trim().isNotEmpty ? ja : en;

  /// Accepts BOTH the old plain-string shape and the new map shape,
  /// so the app keeps working before and during migration.
  factory LocalizedText.fromFirestore(Object? raw) { ... }
  Map<String, String> toMap() => {'en': en, 'ja': ja};
}
```

A tiny extension `context.localized(product.name)` will be provided so screens read naturally.

### 3.3 Fields that change type to `LocalizedText`

| Entity / model | Field(s) |
|----------------|----------|
| `ProductEntity` / `ProductModel` | `name`, `description` |
| `CategoryEntity` / `CategoryModel` | `name` |
| `SubcategoryEntity` / `SubcategoryModel` | `name` |
| `OrderItemEntity` / `OrderItemModel` (snapshot) | `name` |
| `ReviewEntity` / `ReviewModel` (snapshot) | `productName` |
| `ReviewableItemEntity` | `productName` |
| `CartItem` (in-memory, wraps `ProductEntity`) | inherits — no change |

### 3.4 Fields that change to **codes** (section 2, kind C)

| Field | Stored value | Display |
|-------|--------------|---------|
| `condition` | `fresh` / `frozen` / `dry_packaged` / `ambient` / `freshly_prepared` | `'product.condition.frozen'.tr()` → "Frozen" / "冷凍" |
| `origin` | ISO-3166 alpha-2: `BD`, `IN`, `BR`, `JP`, ... | `'country.BD'.tr()` → "Bangladesh" / "バングラデシュ" |
| `unit` | unchanged — single language-neutral free text (decision 5) | shown as-is in both languages |

Condition list will be a Dart enum (`ProductCondition`) so the dropdown, validation and translation keys stay in one place. Origin list will be a `const` list of country codes in `lib/core/constants/` — start with the countries the client actually sources from (BD, IN, BR, JP, + a handful of common ones); extending is one line + two translation entries.

---

## 4. Admin side

### 4.1 Product form (`admin_product_form_page.dart`)

- **Name**: two inputs — `Name (English) *` and `Name (日本語)`.
- **Description**: two inputs — `Description (English) *` and `Description (日本語)`.
- Layout: side-by-side on wide screens, stacked on narrow. A small "EN / JA" label on each input so it is obvious which is which.
- **Condition**: dropdown (5 options, translated labels).
- **Origin**: dropdown (country list, translated labels, searchable if the list grows).
- **Unit**: unchanged, single free-text input (decision 5).
- Validation: English required; Japanese optional; condition + origin required.

### 4.2 Category form (`admin_category_form_page.dart`)

- Category name: EN * + JA inputs.
- Each subcategory row: EN * + JA inputs.

### 4.3 Product / category list pages (admin)

Show the name in the admin's current UI language (via `resolve`). Optional: show the other language in smaller grey text underneath so admin can see at a glance which products are missing Japanese. **Recommended** — cheap and useful.

### 4.4 Admin UI language

The admin pages use the same `en.json` / `ja.json`, so the admin panel itself is bilingual with no extra work beyond translating the `admin.*` keys.

---

## 5. Customer side

### 5.1 Language switcher

- One control everywhere: a **pill toggle** — `EN` and `日本語` side by side on the app's grey input-fill track, the active one in a filled brand-green capsule. One tap switches; there is no separate picker step.
- **Web / tablet**: the pill sits in `app_header.dart` (right side, next to Wishlist / Cart / Account) — reachable signed-out.
- **Phone**: a "Language / 言語" row with the same pill inline on the right, in the main-menu drawer (signed-out entry point), the admin drawer, and the account page.
- Uses `context.setLocale(...)`. `easy_localization` persists the choice on the device automatically. First launch = English (decision #2).
- Also saved to the user's Firestore doc as `preferredLocale` when logged in — for future emails/push/receipts from Cloud Functions, and so it syncs across devices. (Section 8.)

### 5.2 Every place a product/category name is shown

Replace `product.name` with `context.localized(product.name)` (or `.resolve(context.locale)`). Same for description, category name, subcategory name. This touches: home, category products page, product detail, search results, cart items, checkout summary, order history / detail, wishlist, reviews (reviewable item card, review history tile), admin lists.

**Route extras:** the category → product-list → product-detail navigation passes `categoryName` / `subcategoryName` as plain `String` through go_router `extra` (`category_navigation.dart`, `app_router.dart`, `product_list_page.dart`, `product_detail_page.dart`). These will carry the `LocalizedText` object instead, so the page title updates if the user switches language while on that page.

**No change needed:** the Firestore cart stores only `{productId → quantity}` (no name snapshot) and the wishlist is in-memory `ProductEntity` — both pick up the localized name automatically.

### 5.3 Order history & reviews (snapshots)

Orders and reviews store a **copy** of the product name at the time of purchase (so renaming a product later does not rewrite history). That copy must now be the **whole `{en, ja}` map**, not a single resolved string — otherwise a customer who switches language later sees old orders in the old language. `order_repository_impl.dart` (where the snapshot is built) and `review_remote_datasource.dart` change accordingly.

### 5.4 Search

- Match the query against **both** `name.en` and `name.ja`, regardless of current language. Japanese users often type in romaji/English; English-speaking staff may paste Japanese.
- Normalise before comparing: lowercase, trim, convert full-width → half-width (`ＡＢＣ１２３` → `ABC123`) and katakana ↔ hiragana so `らいす` matches `ライス`. Small pure-Dart helper, no package needed.
- Still client-side (as today).

---

## 6. Fixed UI text — `ja.json` and remaining gaps

### 6.1 `assets/translations/ja.json`

- Same structure and keys as `en.json` (18 groups, ~268 keys). Missing keys fall back to English automatically (`fallbackLocale: Locale('en')`).
- New groups added to **both** files: `product.condition.*`, `country.*`, `unit.*` (if applicable), `language.*`, `errors.*`.
- Translation quality: I will produce a first-pass Japanese translation. **The client should have a native speaker review `ja.json`** before release — UI copy tone (polite form です/ます) matters in Japan.

### 6.2 `bootstrap.dart`

```dart
supportedLocales: const [Locale('en'), Locale('ja')],
startLocale: const Locale('en'),   // decision #2
```

### 6.3 Error messages → keys

`Failure.message` and `AuthException` currently carry English sentences. Change them to carry a **translation key** (e.g. `errors.auth.wrong_password`) and let the UI call `.tr()` at display time. Files: `failures.dart`, `exceptions.dart`, `auth_remote_datasource.dart`, `cart_remote_datasource.dart`, `order_remote_datasource.dart`, `review_remote_datasource.dart`, and the ~10 bloc/page sites that display `failure.message`.

### 6.4 Enum labels

- `PaymentStatusPill` already displays through `'order_history.payment_status_${status.name}'.tr()` — just needs the JA values.
- **Gap found:** `OrderStatusPill` (`order_status_pill.dart:32` and the admin dropdown at `:54`) renders `status.name.toUpperCase()` — hardcoded English "PENDING / PROCESSING / COMPLETED / CANCELLED". Add `order_history.order_status_<name>` keys and use them in both places.

### 6.5 Dates

`DateFormat.yMMMMd()` → `DateFormat.yMMMMd(context.locale.toString())`. Japanese renders `2026年9月12日`. Requires `initializeDateFormatting('ja')` at startup (from `intl`) — verified that `easy_localization` 3.0.8 does **not** do this for us. 6 call sites.

### 6.6 Currency / numbers

Verified: `formatYen` (`lib/core/utils/currency_formatter.dart`) already uses `NumberFormat.currency(locale: 'ja_JP', symbol: '¥', decimalDigits: 0)`. Output is identical in both languages. **No change.**

### 6.7 Font

- Add **Noto Sans JP** (via `google_fonts`) as the text theme font when locale is `ja`, or as a global fallback family. Without it, Web shows tofu/mismatched glyphs; Android/iOS fall back to system JA fonts but weights look inconsistent.
- Header wordmark stays Oswald (it is the brand, Latin letters only).
- Not pre-fetched at startup (unlike Oswald): the JP font is several MB and English-only users would pay for it on every cold start. It downloads on first switch to Japanese and is cached after that; a brief system-font flash on that first switch is accepted.
- Known limitation: `google_fonts` registers one font *variant* per family name, so bold Japanese text is synthesized by the engine (faux bold) rather than loaded as a real bold weight. Looks fine; can be revisited by bundling Noto Sans JP static weights as assets if the client wants true bold.

**Implementation note (found in Phase 1):** most screens read strings with a context-free `'key'.tr()`, which registers no inherited dependency, and the widget tree is heavily `const` — so after `setLocale` only the theme changed and the visible text stayed in the old language. Fix: `MaterialApp.router` is keyed on the locale (`app.dart`), which remounts the tree on a switch. Safe because `appRouter` is a global (current route is kept) and app state lives in `getIt` blocs, not widget state.

### 6.8 Stripe

Checked `flutter_stripe` 14.0.0 (`payment_confirmation.dart`):
- **Mobile** uses `PaymentSheet` — the native Stripe sheet follows the **device** locale on its own; there is no per-call locale parameter. A Japanese phone already gets a Japanese sheet.
- **Web** uses `CardField` — the package docs state locale is "not supported on the web". Only the card-number/expiry/CVC placeholders come from Stripe; every label around it is ours and goes through `ja.json`.

**No code change for Stripe.** (Earlier draft said we'd pass a locale — that option doesn't exist in this package version.)

---

## 7. Migration of existing Firestore data

1. `LocalizedText.fromFirestore` accepts both `"string"` and `{en, ja}` — so the app keeps working the moment models change, **before** data is migrated.
2. New script `lib/tools/migrate_localized_fields.dart` (same style as `seed_data.dart`), run once by a developer:
   - `products`: `name`, `description` → `{en: <old>, ja: ""}`; `condition` "Dry / Packaged" → `dry_packaged`, etc.; `origin` "Bangladesh" → `BD`, etc. (`unit` untouched — decision 5).
   - `categories`: `name` and each `subcategories[].name` → map.
   - `orders`: `items[].name` → map. `reviews`: `productName` → map.
   - Idempotent — safe to re-run; skips docs already in the new shape.
3. `seed_data.dart` updated to the new shape so fresh environments seed correctly.
4. After migration is verified, the "accept plain string" tolerance in `fromFirestore` can stay (harmless) or be removed.

Admin then fills in Japanese names/descriptions for existing products at their own pace; until then those products show English in both languages (fallback).

---

## 8. `users/{uid}.preferredLocale`

- New optional field `preferredLocale: "en" | "ja"`, written whenever the logged-in user changes language.
- On login, if the doc has `preferredLocale`, apply it (so a user's choice follows them to a new device).
- Cloud Functions (`functions/src/index.ts`) don't send any user-facing text today; when they do (order confirmation email/push), this field tells them which language to use.

---

## 9. Roadmap & Status

Each phase is independently shippable and testable. Update this section as work lands — `✅ done` / `🔄 in progress` / `⬜ not started` on the phase header, `- [x] ~~item~~` for finished items, same convention as `PLAN.md` and `PAYMENTS_PLAN.md`.

### Phase 1 — Locale foundation ✅ done — committed as `35681cc feat: initialize japanese language support`
- [x] ~~`lib/core/localization/app_locales.dart` — single source of truth for supported locales (`en`, `ja`), start locale (`en`, decision #2), native labels, and the per-locale body font~~
- [x] ~~`bootstrap.dart` — `supportedLocales: [en, ja]`, `startLocale: en`, `initializeDateFormatting('ja')`~~
- [x] ~~`ja.json` — full first-pass translation, all 256 keys, polite です/ます form; key parity and `{placeholder}` parity against `en.json` verified by script~~
- [x] ~~New keys in both files: `language.title` / `language.choose`, `order_history.order_status_{pending,processing,completed,cancelled}`~~
- [x] ~~Language switcher (`lib/shared/widgets/language/language_switcher.dart`): `LanguageToggle` (`EN | 日本語`) in the tablet/desktop `AppHeader` — reachable signed-out, customer and admin; `LanguageMenuTile` in the phone `MainMenuDrawer`, `AdminMenuDrawer`, and the account page (decision D: both)~~
- [x] ~~**Revised after review:** the toggle is now a pill (active language in a filled green capsule on the input-fill track) and the phone rows embed it inline — the bottom-sheet picker and its `language.choose` key were removed~~
- [x] ~~Noto Sans JP for `ja` via `ThemeData.fontFamily` (`AppTheme.light/dark({bodyFont})`, `app.dart`) — every existing `AppTextStyles` usage inherits it, no widget changes~~
- [x] ~~`MaterialApp.router` keyed on the locale so a switch remounts the tree (see §6.7 implementation note — const widgets + context-free `.tr()` otherwise kept the old language)~~
- [x] ~~`OrderStatusPill` — both the customer chip and the admin dropdown now use `order_history.order_status_*` keys instead of `status.name.toUpperCase()`~~
- [x] ~~`lib/core/utils/date_formatter.dart` (`formatLongDate` / `formatShortDate`) replacing all 6 bare `DateFormat` calls — renders `2026年9月12日` in JA; covered by `test/core/date_formatter_test.dart`~~
- [x] ~~`test/widget_test.dart` updated for the new `AppTheme` signature + body-font assertion; `flutter analyze` clean, 4/4 tests pass~~
- [x] ~~Verified in browser: desktop header toggle switches EN ↔ JA in place (route kept, no reload); phone drawer → picker → JA applied instantly; choice persists across restart~~

### Phase 2 — Error messages → keys ✅ done — awaiting developer commit
- [x] ~~`core/errors/failures.dart` + `exceptions.dart` — the field is now `messageKey` (a translation key), defaults `errors.server` / `errors.cache` / `errors.unexpected` / `errors.not_found` / `errors.auth`. Renaming (not just re-purposing `message`) made the compiler surface every site~~
- [x] ~~`auth_remote_datasource.dart` — `_messageForCode()` → `_keyForCode()` returning `errors.auth_*` keys; the 4 inline `AuthException('...')` → `errors.auth_phone_exists` / `auth_phone_not_found` / `auth_sign_in_cancelled` / `auth_google_failed`~~
- [x] ~~`cart_remote_datasource.dart`, `order_remote_datasource.dart`, `order_repository_impl.dart`, `review_remote_datasource.dart`, `review_repository_impl.dart` — "Please sign in to …" → `errors.sign_in_required_*`; order-placement timeout → `errors.order_place_timeout`~~
- [x] ~~`payment_remote_datasource.dart` — timeouts / missing secret → `errors.payment_start_*`; `FirebaseFunctionsException` no longer forwards the server's English text — its `code` is mapped to a key (`unauthenticated` → sign-in-required, `not-found`, `deadline-exceeded`/`unavailable` → timeout, else generic)~~
- [x] ~~`account_bloc.dart` — the one hardcoded English message in a bloc → `errors.auth_phone_not_found`~~
- [x] ~~All repositories forward `e.messageKey`; all blocs store `failure.messageKey` in their existing `errorMessage` / `message` state fields (field names kept to avoid churn — the value is now a key, documented on `Failure`)~~
- [x] ~~`errors.*` group (28 keys) added to `en.json` + `ja.json`; script-verified every key used in Dart exists in both files and none is unused~~
- [x] ~~Every UI sink calls `.tr()` — 22 sites: toasts in address/edit-profile/checkout/my-reviews/sign-in/sign-up/admin pages, `ErrorView`s in admin lists, `DashboardFailure`, `OrderHistoryFailure`, `ProductDetailError`, `ProductListError`, search bar error, `retry_payment_button`~~
- [x] ~~Stripe's own `localizedMessage` (already device-localized) still passes through `PaymentConfirmationFailed` as text; `.tr()` on a non-key returns it unchanged, so the checkout toast handles both~~
- [x] ~~`flutter analyze` clean, 4/4 tests pass; verified in browser: wrong password in JA shows メールアドレスまたはパスワードが正しくありません。~~

### Phase 3 — `LocalizedText` + models ✅ done — awaiting developer commit
- [x] ~~`lib/core/localization/localized_text.dart` — `LocalizedText(en, ja)`, `resolve(locale)` with JA→EN fallback, tolerant `fromFirestore` (map **or** legacy plain string), `toMap()`, `values` (for search), `hasJa`, `empty`; `context.localized(text)` extension. Unit-tested (`test/core/localized_text_test.dart`, 8 cases)~~
- [x] ~~`ProductEntity` / `ProductModel` — `name`, `description`~~
- [x] ~~`CategoryEntity` / `CategoryModel`, `SubcategoryEntity` / `SubcategoryModel` — `name` (incl. the nested `subcategories[]` array in `CategoryModel.toMap`)~~
- [x] ~~`OrderItemEntity` / `OrderItemModel` — `name`; `order_repository_impl.dart` snapshots the whole map from `item.product.name`~~
- [x] ~~`ReviewEntity` / `ReviewModel`, `ReviewableItemEntity` — `productName`; typed as `LocalizedText` through `SubmitReviewUseCase` → `ReviewRepository` → `MyReviewsEvent`, so the review doc stores the map~~
- [x] ~~Route extras: `CategoryProductsExtra`, `ProductListExtra`, `ProductDetailExtra` carry `LocalizedText`; `ProductListPage` / `ProductDetailPage` keep the object for re-pushing and resolve only for display (deep link with no extra falls back to the raw id, as before)~~
- [x] ~~19 display sites use `context.localized(...)`: home category card, subcategory card, category nav list (drawer + desktop sidebar, 3 sites), product card, product detail title/description, breadcrumbs, search results, cart item, order item tile, reviewable item card, review history tile, admin product/category lists + delete dialogs, admin reviews list, admin product form's category/subcategory dropdown labels~~
- [x] ~~Search datasource matches against every stored language (`name.values`) — normalisation comes in Phase 6~~
- [x] ~~Admin forms: minimal compile-correct change only (EN input → `LocalizedText`, existing JA preserved on edit) — dual inputs are Phase 5~~
- [x] ~~`flutter analyze` clean, 11/11 tests pass~~

### Phase 4 — Codes for condition / origin ✅ done — awaiting developer commit
- [x] ~~`lib/features/product/domain/entities/product_condition.dart` — `ProductCondition` enum (`fresh`, `frozen`, `dry_packaged`, `ambient`, `freshly_prepared`; decision 7), `code` for storage, `labelKey` → `product.condition.<code>`, tolerant `parse()` that also maps the legacy English labels ("Dry / Packaged" → `dryPackaged`) so unmigrated docs still load~~
- [x] ~~`lib/core/constants/countries.dart` — short ISO list (decision 6), `label(code)` (translated, unknown code shown verbatim), tolerant `parse()` mapping legacy names ("Bangladesh" → `BD`)~~
- [x] ~~`product.condition.*` (5) and `country.*` (14) keys in both JSON files~~
- [x] ~~`ProductEntity.condition` is `ProductCondition`; `origin` stays `String` but holds a code; `ProductModel` parses/serialises both~~
- [x] ~~`ProductInfoRow` displays `condition.labelKey.tr()` and `Countries.label(origin)`; `unit` untouched (decision 5)~~
- [x] ~~Admin product form: condition and origin are now `AppDropdownField`s (pulled forward from Phase 5 since the type change forced the form to change anyway); hint/error copy updated to "choose"~~
- [x] ~~Parser tests in `test/core/product_codes_test.dart` (7 cases); `flutter analyze` clean, 18/18 tests pass, translation parity 303/303~~

### Phase 5 — Admin forms ✅ done — awaiting developer commit
- [x] ~~`lib/features/admin/presentation/widgets/bilingual_text_field.dart` — `BilingualController` (owns the EN + JA `TextEditingController`s, `.value` → `LocalizedText`), `BilingualTextField` (EN required / JA optional, `EN`/`JA` tag inside each box, side-by-side ≥ 600 px, stacked on phone), `MissingJaBadge`~~
- [x] ~~`admin_product_form_page.dart` — name and description use `BilingualTextField`; condition + origin dropdowns (done in Phase 4)~~
- [x] ~~`admin_category_form_page.dart` — category name uses `BilingualTextField`; every subcategory row too (optional — a blank row is still skipped at submit, ids still slugified from the English name)~~
- [x] ~~Validation: EN required, JA optional, condition + origin required (dropdown validators)~~
- [x] ~~Admin product and category lists show a "JA missing" badge on rows without a Japanese name (§4.3)~~
- [x] ~~New keys `admin.field_en` ("{field} (English)"), `admin.field_ja` ("{field} (日本語)"), `admin.ja_missing` in both files~~
- [x] ~~Widget tests `test/features/admin/bilingual_text_field_test.dart` (5 cases: EN required, JA optional, initial value + composition, responsive layout, badge); `flutter analyze` clean, 23/23 tests pass~~
- Not verified in the browser: the admin pages need an admin sign-in, which the developer should do during the Phase 9 QA pass

### Phase 6 — Search ✅ done — awaiting developer commit
- [x] ~~`lib/core/utils/text_normalizer.dart` — `normalizeForSearch`: lowercase, whitespace collapse, full-width ASCII → half-width, ideographic space, katakana → hiragana, half-width katakana → hiragana (pure Dart, no package)~~
- [x] ~~`product_remote_datasource.dart` — query and every stored language (`name.values`) are normalised before `contains`, regardless of current locale~~
- [x] ~~Tests `test/core/text_normalizer_test.dart` (6 cases incl. "rice / ライス / らいす / ＢＡＳＭＡＴＩ all match"); `flutter analyze` clean~~

### Phase 7 — Migration ✅ tool done — **developer must run it** — awaiting commit
- [x] ~~`lib/tools/migrate_localized_fields.dart` — same sign-in-as-admin shape as `seed_data.dart`; **Dry run** checkbox (default on) lists every doc/field that would change, untick to apply; batches of 400; idempotent (docs already in the new shape are skipped, existing `ja` never overwritten)~~
  - `products`: `name`, `description` → `{en, ja: ""}`; `condition` label → code; `origin` name → ISO code
  - `categories`: `name` + every `subcategories[].name` (array rewritten whole)
  - `orders`: every `items[].name`
  - **`reviews.productName` is not migrated** — `firestore.rules` makes review docs immutable (`allow update: if false`, admins included) and §12 promised no rules change. The tolerant parser reads the old plain string, so those snapshots just show the English name in Japanese mode. Acceptable; revisit only if the client cares about old review rows.
- [x] ~~`seed_data.dart` writes the new shape (`_localized()` for names/descriptions, `ProductCondition.parse(...).code`, `Countries.parse(...)`) — data literals unchanged~~
- [x] ~~`test/tools/migrate_localized_fields_test.dart` locks the legacy → new-shape contract and idempotence; `flutter analyze` clean, 31/31 tests pass~~
- [ ] **Developer:** `flutter run -t lib/tools/migrate_localized_fields.dart -d chrome` → sign in as admin → *Preview changes* → review the log → untick Dry run → *Migrate Firestore*. Until this runs, the app still works (tolerant parsers) but admin list rows all show "JA missing" and legacy origins that didn't map to a known country show verbatim.

### Phase 8 — `users/{uid}.preferredLocale` ✅ done — awaiting developer commit
- [x] ~~`UserEntity.preferredLocale` (+ `copyWith`, which `AccountBloc` now uses for its local user updates instead of re-listing every field), `UserModel` reads/writes it~~
- [x] ~~`AuthRemoteDatasource.updatePreferredLocale` → `AuthRepository` → `UpdatePreferredLocaleUseCase` (DI regenerated)~~
- [x] ~~`AccountPreferredLocaleUpdateRequested` — fired from `setAppLocale` in `language_switcher.dart`; the bloc writes it best-effort for a signed-in user (no error toast: the device already switched) and skips when unchanged~~
- [x] ~~Applied at sign-in: `EverydayWholesaleApp` wraps the router in a `BlocListener<AccountBloc>` that fires only when a different uid becomes signed in (covers the session restored at launch) and calls `context.setLocale` if the profile's preference differs. Profile edits / the preference write itself don't re-trigger it. Sign-out leaves the device language alone~~
- [x] ~~No rules change needed — a user may already update their own `users/{uid}` doc (role unchanged)~~
- [x] ~~`flutter analyze` clean, 31/31 tests pass~~

### Phase 9 — QA pass 🔄 developer-side items remain
Verified by the assistant (Flutter web, debug build, against the **unmigrated** live Firestore data, so the tolerant parsers were exercised for real):
- [x] ~~Static checks: `flutter analyze` clean; 31/31 tests; `en.json` / `ja.json` 306 / 306 keys, 0 missing, 0 placeholder mismatches; all 238 statically-referenced `.tr()` keys exist~~
- [x] ~~Home (phone + desktop) in JA — header, search hint, "カテゴリーから探す", bottom nav, drawer, sidebar~~
- [x] ~~Category page in JA — subcategory grid, breadcrumb, "Frozen Foodのすべての商品" (`{categoryName}` from `LocalizedText`)~~
- [x] ~~Product detail in JA on legacy data — 状態 **冷凍** (from stored `"Frozen"`), 原産地 **バングラデシュ** (from stored `"Bangladesh"`), unit `10pcs` neutral, description falls back to EN, tabs/highlights/stock/add-to-cart translated~~
- [x] ~~Runtime switch JA ↔ EN on the product page — stays on the page; condition/origin flip to "Frozen"/"Bangladesh"; no reload~~
- [x] ~~Search: full-width `ＰＡＲＡＴＨＡ` finds "Frozen Paratha 10pcs" (normaliser live)~~
- [x] ~~Deep link / refresh with no route `extra` — breadcrumb and subcategory grid now resolve from the category cache (new `CategoryContextResolver`; fixed during QA — previously showed raw ids and lost the grid, and the language switch's remount exposed it)~~
- [x] ~~Error path in JA: wrong password → メールアドレスまたはパスワードが正しくありません。(Phase 2)~~
- [x] ~~Font: Noto Sans JP applied on switch; brief tofu on the very first JA load while it downloads (documented, §6.7)~~
- [x] ~~Language persists across restart~~

Needs the developer (requires accounts / data I don't have):
- [ ] **Run the migration** (Phase 7 step) on the live project, then confirm in the admin lists that "JA missing" badges are the only ones expected
- [ ] **Admin, signed in as admin:** product form (EN/JA name + description, condition/origin dropdowns, edit an existing product and confirm nothing is lost on save), category form (EN/JA category + subcategory rows), "JA missing" badges, admin lists in JA
- [ ] Enter Japanese names for a few products/categories and check the customer app shows them in JA mode and English in EN mode
- [ ] **Signed-in customer flows in JA:** cart item names, checkout summary, place an order → order history / detail (item names, `2026年9月12日` dates, 受付中 status pill), My Reviews (reviewable item card, review history tile), Stripe card sheet
- [ ] `preferredLocale`: switch language while signed in → check `users/{uid}.preferredLocale` in the console → sign in on another device/browser and confirm it applies
- [ ] Android + iOS build: system fonts for JA, bottom-sheet language picker, drawer tile; check for label overflow in JA on the narrowest supported phone
- [ ] Native-speaker review of `ja.json` (decision 9)

## 10. Future ideas (out of scope now)

- **Auto-translate button** in admin form: Cloud Function calling DeepL / Google Translate to pre-fill the JA field from EN; admin proofreads. Needs API key + billing. No schema change required — it just fills the `ja` key.
- **Third language**: add `Locale('xx')`, `xx.json`, and an `xx` key in `LocalizedText`. Everything else already works.
- **Server-side search** (Algolia / Typesense) if the catalogue grows beyond a few thousand products — both have built-in Japanese tokenisation.
- **Localized images** (e.g. packaging photos with Japanese labels) — not needed; images are language-neutral.

---

## 11. Open questions ✅ all resolved (2026-09-12 — "go with your recommendations"; recorded as decisions #5–#9 in §0)

### A. `unit` — dropdown doesn't fit the real data → **resolved: A1**

Current `unit` values are **pack sizes**: `1kg`, `400g`, `800ml`, `10pcs`, `1.5L x 6`. That is not a fixed list you can pick from a dropdown.

Options:

| Option | How it works | Pros | Cons |
|--------|--------------|------|------|
| **A1. Keep as one free-text field, treated as language-neutral (Recommended)** | Admin types `400g` once; shown identically in EN and JA. | Zero extra typing. `kg / g / ml / L` are universally understood in Japan. No migration. | `10pcs` / `1.5L x 6` are English-ish. Acceptable in practice (Japanese retail commonly writes `10個` but `10pcs` is understood). |
| A2. Structured: `unitValue` (number) + `unitCode` (dropdown: `g, kg, ml, L, pcs, pack, box`) | Admin enters `400` + picks `g`. App renders `400g` / `400g`, `10pcs` / `10個`. | Fully translatable; enables sorting/filtering by size later. | More admin clicks; `1.5L x 6` doesn't fit (needs a third "multiplier" field). Migration must parse existing strings. |
| A3. Bilingual free text `{en, ja}` like name | Admin types `10pcs` and `10個`. | Fully flexible. | Doubles typing for something that's 90% numbers. |

**My recommendation: A1.** Revisit A2 only if the client explicitly wants `個` / `パック` style Japanese units.

### B. Origin country list → **resolved: short list**

I'll start with **Bangladesh, India, Brazil, Japan, Thailand, Vietnam, Philippines, Indonesia, Nepal, Sri Lanka, Pakistan, China, USA, Australia** (translated in both files). Is that enough, or do you want the full ISO list (~250 entries — heavier dropdown, but nothing is ever missing)? **Recommendation: start with the short list**; adding a country later is a 3-line change.

### C. Condition list → **resolved: keep all five**

Keep the current five — `Fresh`, `Frozen`, `Dry / Packaged`, `Ambient`, `Freshly Prepared` — or trim `Ambient` (overlaps with Dry / Packaged)? **Recommendation: keep all five** as-is so no existing product changes meaning; the client can decide later.

### D. Language switcher placement on web → **resolved: both** (done in Phase 1)

Header toggle `EN | 日本語` (recommended, standard for Japanese e-commerce sites) vs. only inside Account. **Recommendation: both.**

### E. Who reviews the Japanese translation? → **resolved: client arranges native review before release**

I will produce the full first-pass `ja.json`. Does the client have a native Japanese speaker to review it before release? (Recommended — especially for checkout / payment / error wording.)

---

## 12. What will NOT change

- Firestore collection names, document IDs, security rules, Cloud Functions, Stripe flow.
- Prices (already ¥ integers), images, ratings, cart logic, routing.
- Any product/category document that has not been migrated still loads (tolerant parser).
