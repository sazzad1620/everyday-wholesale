# Web / Landscape Layout Optimization Plan

## Context

The app is built mobile-first (Flutter, `lib/features/**/presentation`) and today
renders the *same* single-column mobile layout on every screen width — on a
wide browser tab or landscape tablet, it just stretches: 2-column grids
scaled up, full-bleed search bar, bottom nav + hamburger drawer instead of a
persistent sidebar, everything centered in a way that reads as "a phone
screen blown up," not a web layout.

The reference screenshots the user shared are from an unrelated, more mature
grocery e-commerce website (gunmahalalfood.com) — **not** our app. They show
features we don't have (a prayer-times shortcut, a "purchase points" reward
program with pending/completed/cancelled order tiles) and different data
shapes (table-style order history, a two-panel address form). Those are
**not** in scope — this plan borrows the *structural* ideas (persistent
sidebar, header layout, grid density, list/detail split, sticky order
summary) and reimplements them with **our own colors, type scale, cards, and
data**, per the request to keep our own design language.

## Goal

Make the storefront read as a proper web layout at tablet/desktop widths,
with **zero visual or behavioral change to phone-portrait ("mobile normal
mode")**. Low effort, reusing the app's existing responsive infrastructure
rather than inventing a new one.

## Existing infrastructure we build on

- `lib/core/utils/responsive/breakpoints.dart` — `AppBreakpoints.mobile = 600`,
  `AppBreakpoints.tablet = 1024`, `deviceTypeOf(width)`.
- `lib/core/utils/responsive/responsive_builder.dart` — `ResponsiveBuilder(mobile:, tablet:, desktop:)`,
  already used by `AdminShellPage` to swap in a `NavigationRail` on
  tablet/desktop. We follow the same pattern for the customer side instead of
  introducing a second responsive mechanism.

## Decision: breakpoint cutover

**Recommendation (going with this unless you say otherwise): the new wide
layout activates at `width >= AppBreakpoints.mobile` (600px)** — i.e. it
covers both the existing `tablet` and `desktop` bands. Only genuine
phone-portrait widths (<600) keep today's UI untouched.

Reasoning: a landscape phone or a small tablet in portrait already falls in
the 600–1024 "tablet" band and suffers the exact same "stretched mobile"
complaint as a full desktop tab — there's no natural point in that band where
the old layout suddenly starts looking fine. Splitting "tablet" and "desktop"
into two different treatments would double the work for a distinction the
user didn't ask for. If you'd rather keep 600–1024 on the old mobile layout
and only switch at 1024, that's a one-line change to which breakpoint each
piece below checks.

**Decided: 600px, as recommended above.** In effect since Phase 0.

## Explicitly out of scope

- Any feature visible only in the reference screenshots with no equivalent
  in our domain model: prayer-time shortcut, "purchase points"/reward
  program, pending/completed/cancelled order-count tiles on the account
  dashboard.
- A second hero banner / side banner image on the homepage (reference image
  1) — we have one promo-carousel asset pipeline (`HomePromoCarousel`), no
  second banner slot exists in the data model. Flagged as a possible later
  enhancement, not part of this pass.
- Any change to phone-portrait rendering.
- Admin section (`AdminShellPage` already has its own desktop treatment).

## Phase 0 — Shared building blocks ✅ done

Do these first; everything else depends on them.

- [x] **`ResponsiveContentContainer`** (new, `lib/shared/widgets/responsive_content_container.dart`)
  Centers page content with a max width (~1280) and adaptive horizontal
  padding at width >= 600; passes through unmodified below that. Built as
  planned — **but not wired into any page yet**. `DesktopBody`'s sidebar
  (below) ended up narrowing the effective content column enough at typical
  desktop widths that the "stretched edge-to-edge" problem this solves
  didn't resurface before Phase 1 was reached. Still sitting there unused —
  Phase 1 picks it up.

- [x] **Grid reflow via `SliverGridDelegateWithMaxCrossAxisExtent`**
  Replace `SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, ...)`
  with `SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: ~200, ...)`
  in:
  - [x] `lib/features/home/presentation/widgets/category_grid.dart`
  - [x] `lib/features/home/presentation/widgets/subcategory_grid.dart`
  - [x] `lib/features/product/presentation/pages/product_list_page.dart` (inline grid)
  - [x] `lib/features/wishlist/presentation/pages/wishlist_page.dart` (inline grid)

  Column count grows automatically with available width (2 on a phone, ~3 on
  tablet, 5–6 on desktop) with no breakpoint branching. Category/subcategory
  grids landed exactly as planned. The **product grids needed a follow-up
  fix**: `childAspectRatio` scales the space reserved for `ProductCard`'s
  fixed-height text block proportionally with card width, so it only truly
  fit at the one width it was tuned for — narrower cards (more columns, on
  wider screens) overflowed. Replaced with a new shared
  `lib/shared/widgets/product_grid.dart` that computes the exact card width
  per layout and sizes each row as `cardWidth + a fixed content-height
  constant` instead of a ratio — fits snugly at any column count, matches
  the original tight mobile look everywhere instead of only at one width.

- [x] **Desktop chrome in `StandaloneShellScaffold`** (`lib/shared/widgets/navigation/standalone_shell_scaffold.dart`)
  This one widget already backs Home/Wishlist/Cart (via `MainShell`) *and*
  the standalone `AccountPage` — one change here fixes the drawer/bottom-nav
  problem everywhere at once, same as `AdminShellPage`'s approach.
  - [x] Mobile keeps today's `Scaffold(drawer:, endDrawer:,
    bottomNavigationBar:)` exactly as-is.
  - [x] Tablet/desktop: no `bottomNavigationBar`, no drawer-as-overlay.
    **Implemented differently than planned**: rather than
    `Row([_DesktopSidebar, Expanded(body)])` wrapping the whole page from
    inside `StandaloneShellScaffold`, the sidebar moved into a new
    `lib/shared/widgets/navigation/desktop_body.dart`, used *inside* each
    page below its own header/breadcrumb. Wrapping the whole page put the
    sidebar beside the header too, so the header could never span the full
    page width — a correction made after seeing it live.
    `StandaloneShellScaffold` now only owns drawer/bottom-nav suppression;
    the actual sidebar is `lib/shared/widgets/navigation/desktop_sidebar.dart`,
    with categories shared via a new
    `lib/shared/widgets/navigation/categories_cache.dart` (one fetch per app
    session instead of one per shell instance).
    - [x] Category list, reusing `CategoryDrawer`'s expansion-tile logic —
      extracted into a shared `lib/shared/widgets/navigation/category_nav_list.dart`
      so the drawer and the sidebar both use it.
    - [ ] ~~"Home / Shop / About" quick-link tiles~~ — **dropped per
      follow-up feedback**: no "Shop" destination exists in this app to
      point it at, and a "Home" tile felt redundant once every page already
      has the header's logo directly above the sidebar. Sidebar starts
      straight with "Categories".

- [x] **`AppHeader` desktop variant** (`lib/shared/widgets/navigation/app_header.dart`)
  At width >= 600:
  - [x] Hamburger icon hides (sidebar replaces it; back-button pages keep
    their back arrow regardless of width).
  - [x] Search field gets a max width (~560, adjusted from the original
    ~480–560 estimate) instead of stretching full-bleed edge to edge.
  - [x] Bottom nav's Wishlist/Cart destinations move into the header as
    inline icon+label buttons, reusing `RoutePaths.wishlist`/`RoutePaths.cart`
    and the existing `CartBloc` badge count from `MainBottomNavBar`.
  - [x] Account icon rebuilt from the same icon-over-label widget as
    Wishlist/Cart (not planned originally) — a bare icon next to two labeled
    buttons read as smaller/lighter-weight than them, spotted after the
    first pass shipped.
  - [x] **Layout changed from two rows to one, per follow-up feedback**:
    originally logo/menu/account on one row with the search bar on a second
    row below (matching phone's stacked layout, just minus the hamburger).
    Now a single row — logo → search (left-aligned, capped width) →
    Wishlist/Cart/Account — so the header doesn't waste the extra vertical
    space a two-row layout only needed on a narrow phone.
  - [x] Search button (the small circular icon inside the field) shrunk and
    inset further from the box edge (not in the original plan) — it read as
    an oversized circle breaking past the pill's own rounded corner; now
    reads as part of the same shape.

## Phase 1 — Storefront pages ⬜ (highest visual impact, matches reference images 1–5)

All of these ride on Phase 0 automatically once their scroll body is wrapped
in `ResponsiveContentContainer`; only the specific files needing *extra*
reflow beyond "wrap + let the grid delegate do its job" are called out.

- [ ] **Home** (`lib/features/home/presentation/pages/home_page.dart`): wrap the
  `ListView` body. Category grid reflows via Phase 0.2 automatically.
- [ ] **Category / product listing** (`lib/features/product/presentation/pages/product_list_page.dart`):
  wrap body; breadcrumb, subcategory grid, and product grid all reflow.
- [ ] **Product detail** (`lib/features/product/presentation/widgets/product_detail_content.dart`):
  currently one stacked `Column` (image → title/price/rating → info row →
  qty/cart/wishlist → highlight boxes → tabs). At >=600: reflow the top
  section into a `Row` — image capped at a fixed width (~440) on the left,
  the title-through-add-to-cart block on the right — while
  `ProductHighlightBoxes` and `ProductDetailTabs` stay full-width below,
  matching the reference's gallery/info split without touching the tab
  content itself.
- [ ] **Cart** (`lib/features/cart/presentation/pages/cart_page.dart`): reflow
  `_CartBody`'s stacked list into `Row(children: [Expanded(items list +
  voucher), SizedBox(width: ~360, child: sticky CartSummaryCard)])` at >=600
  — matches the reference bag page's items-table + total-panel split, no new
  widgets needed (`CartItemCard`/`CartSummaryCard`/`CartVoucherCard` reused
  as-is).
- [ ] **Checkout** (`lib/features/checkout/presentation/pages/checkout_page.dart`):
  same idea — `DeliveryAddressCard` + `PaymentMethodCard` on the left,
  `OrderSummaryCard` + place-order button sticky on the right.
- [ ] **Wishlist** (`lib/features/wishlist/presentation/pages/wishlist_page.dart`):
  wrap body; grid reflows via Phase 0.2.

## Phase 2 — Account area ⬜ (images 6–9's *structural* idea only, not their stats/table features)

The reference's dashboard/orders/reviews pages have no equivalent data in
our app (no reward points, no pending/completed/cancelled counters as
separate fields). What we *can* borrow cheaply: a persistent left account
nav alongside content, instead of push-navigating to a full-screen page for
every item.

- [ ] Add a small `_DesktopAccountNav` (reuses the exact same 5 rows
  `AccountPage._AccountBody` already renders — Edit Profile / Address / Order
  History / My Reviews / Logout — just as a highlighted vertical list instead
  of `ListTile`s) shown alongside content at >=600 on:
  - [ ] `AccountPage` (`lib/features/account/presentation/pages/account_page.dart`)
  - [ ] `OrderHistoryPage` (`lib/features/account/presentation/pages/order_history_page.dart`)
  - [ ] `AddressFormPage` (`lib/features/account/presentation/pages/address_form_page.dart`)
  - [ ] `EditProfilePage`, `MyReviewsPage` (same treatment, not yet read in
    detail — confirm same "stacked ListView" shape before touching)
- [ ] Since these are separate routes (not tabs in one page today), the nav
  itself doesn't need new state — each page just renders its own version of
  the nav with itself highlighted, same as how `AdminMenuDrawer` takes a
  `selectedIndex`. Lower priority than Phase 1; do only after Phase 1 is
  confirmed working.
- [ ] `AddressFormPage`'s single-column form can additionally reflow into two
  columns of fields at >=600 (receiver/phone/postal/state/city/street pair
  up) — purely a `Wrap`/`Row` change around the existing
  `TextFormField`s, no new fields.

## Explicitly not doing (flag if you disagree)

- No stat-card dashboard, no reward points, no order-status counters.
- No table/grid view for order history — keeping the existing card layout,
  just placed in the two-column account shell.
- No second hero banner on Home.

## Suggested build order

1. ✅ Phase 0.1 + 0.2 (container + grid delegate swap) — done. Mobile
   verified pixel-identical.
2. ✅ Phase 0.3 + 0.4 (shell sidebar + header) — done, restructured along
   the way per live feedback (see Phase 0 notes above). Drawer/bottom-nav
   behavior verified untouched on mobile.
3. ⬜ Phase 1 pages one at a time (Home → Category/Product list → Product
   detail → Cart → Checkout → Wishlist), verifying in the Chrome/Edge preview
   at a few widths (768, 1024, 1440) after each.
4. ⬜ Phase 2 (account area) once Phase 1 is confirmed.

Testing: `everyday_wholesale-web` / `everyday_wholesale-web-server` launch
configs already exist in `.claude/launch.json` — use the browser preview at
each step, resizing to tablet/desktop widths, and spot-check phone width
(375) stays unchanged.
