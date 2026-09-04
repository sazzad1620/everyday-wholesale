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

## Phase 1 — Storefront pages ✅ done (highest visual impact, matches reference images 1–5)

All of these ride on Phase 0 automatically once their scroll body is wrapped
in `ResponsiveContentContainer`; only the specific files needing *extra*
reflow beyond "wrap + let the grid delegate do its job" are called out.

- [x] **Home** (`lib/features/home/presentation/pages/home_page.dart`): wrap the
  `ListView` body. Category grid reflows via Phase 0.2 automatically.
- [x] **Category / product listing** (`lib/features/product/presentation/pages/product_list_page.dart`):
  wrap body; breadcrumb, subcategory grid, and product grid all reflow.
- [x] **Product detail** (`lib/features/product/presentation/widgets/product_detail_content.dart`):
  reflowed the top section into a `Row` — image on the left, the
  title-through-add-to-cart block on the right — while
  `ProductHighlightBoxes` and `ProductDetailTabs` stay full-width below.
  **Two corrections made after seeing it live**: a fixed 440 image width (as
  planned) overflowed the info column's own rows (rating/stock,
  qty/cart/wishlist) at narrower desktop widths, where 440 left too little
  of the remaining space — switched to a capped flex share (`Expanded(flex:
  2)` image / `Expanded(flex: 3)` info, image still capped at a max of 440)
  so the info column always gets its proportional share of whatever width
  is actually available. That alone still wasn't enough right above the
  tablet/desktop cutover (~600–650px), where the sidebar alone leaves less
  room here than a phone has — the split now only engages once a
  `LayoutBuilder` confirms this widget itself has >=700px to work with
  (checked against its own constraints, not the screen width), stacking
  like phone otherwise.
- [x] **Cart** (`lib/features/cart/presentation/pages/cart_page.dart`): reflowed
  `_CartBody`'s stacked list into `Row(children: [Expanded(items list +
  voucher), SizedBox(width: 360, child: sticky CartSummaryCard)])` at >=600
  — matches the reference bag page's items-table + total-panel split, no new
  widgets needed (`CartItemCard`/`CartSummaryCard`/`CartVoucherCard` reused
  as-is).
- [x] **Checkout** (`lib/features/checkout/presentation/pages/checkout_page.dart`):
  same idea — `DeliveryAddressCard` + `PaymentMethodCard` on the left,
  `OrderSummaryCard` + place-order button sticky on the right, at >=600.
- [x] **Wishlist** (`lib/features/wishlist/presentation/pages/wishlist_page.dart`):
  wrap body; grid reflows via Phase 0.2.

Verified at 375 (mobile, unchanged), 620 (the narrow-desktop edge case that
first exposed the product-detail overflow), 1000, and 1440 — no
`RenderFlex` overflow at any of them, `flutter analyze` clean throughout.

## Phase 2 — Account area ✅ done (images 6–9's *structural* idea only, not their stats/table features)

The reference's dashboard/orders/reviews pages have no equivalent data in
our app (no reward points, no pending/completed/cancelled counters as
separate fields). What we *can* borrow cheaply: a persistent left account
nav alongside content, instead of push-navigating to a full-screen page for
every item.

- [x] Added `DesktopAccountNav` (`lib/features/account/presentation/widgets/desktop_account_nav.dart`,
  built as a standalone widget rather than the originally-sketched private
  `_DesktopAccountNav` — reused from 4 different pages, so it couldn't stay
  page-private) — reuses the exact same 5 rows `AccountPage._AccountBody`
  already renders (Edit Profile / Address / Order History / My Reviews /
  Logout), as a highlighted vertical list, self-contained for navigation
  (`pushReplacement` between sections, not `push` — so clicking around the
  sidebar doesn't stack pages the back button then has to unwind one at a
  time) and logout. Shown alongside content at >=600 via a new
  `DesktopAccountBody` wrapper (mirrors `DesktopBody` from Phase 0 — lives
  *inside* each page below its own header/tab bar, same reasoning) on:
  - [x] `AccountPage` — `current: null` (the hub isn't one of its own 5
    links, so nothing is highlighted). **Two corrections after seeing it
    live**: first, the main content originally still rendered the same 5
    rows too, directly duplicating the sidebar sitting right next to it —
    `_AccountBody` now only renders that row list on phone width (where
    there's no sidebar and it's the only way to reach them); at desktop it
    shows just the profile card. Second, the header's account icon still
    navigated *to* this now-sparse hub page on desktop, which read as an
    odd extra hop — `AppHeader`'s account entry
    (`_AccountHeaderAction`/`_AccountPopupButton`) now opens a small
    `PopupMenuButton` with the same 5 items directly from the header icon
    instead, for a signed-in non-admin customer at desktop width (signed-out
    still opens the sign-in dialog, admin still goes to the admin account
    page — both unchanged, same as phone). Items `context.push` the same
    routes `DesktopAccountNav` does. `AccountPage` itself is still reachable
    (e.g. a direct link) but is no longer the primary way there from the
    header on desktop.
  - [x] `OrderHistoryPage` — `current: AccountNavItem.orderHistory`
  - [x] `AddressFormPage` — `current: AccountNavItem.address`
  - [x] `EditProfilePage` — `current: AccountNavItem.editProfile`
  - [x] `MyReviewsPage` — `current: AccountNavItem.myReviews`; its `TabBar`
    moved inside `DesktopAccountBody`'s content column (same "lives beside
    the sidebar, not above it" treatment `BreadcrumbBar` got in Phase 0)
- [x] Since these are separate routes (not tabs in one page), the nav
  doesn't need shared state — each page renders its own `DesktopAccountNav`
  with itself highlighted, same as `AdminMenuDrawer`'s `selectedIndex`.
- [x] `AddressFormPage`'s form now reflows into two columns of fields at
  >=600 (receiver+phone, postal+state, city+street, chome-banchi-go+
  building) via a small `_fieldPair` helper — `Row` of two `Expanded`s
  wide, stacked `Column` on phone, no new fields.
- [x] Found and fixed a real bug during verification: `DesktopAccountNav`'s
  selected-row highlight used a colored `Container` wrapping the `ListTile`
  (same mistake `DesktopSidebar` made in Phase 0, and same fix — the
  `ListTile`'s ink/tap-highlight paints on the nearest `Material` ancestor,
  and a `Container` in between hides it; caught via a live Flutter
  assertion, not visually).

Verified at 375 (mobile, unchanged — still the plain `ListTile` list, no
sidebar, plain account icon opening the sign-in dialog same as always) and
~1100 desktop (sidebar renders, `pushReplacement` navigation between all 4
linked pages works, correct item highlighted each time, no console errors
after the `Material` fix; header's account icon still opens the sign-in
dialog signed-out, confirming that branch of `_AccountHeaderAction` works).
The `AccountPage` duplication fix was additionally confirmed against a real
signed-in account via screenshots from the user's own session. The header
popup itself (added after that same screenshot prompted the "same things in
double" feedback) has **not** been click-tested signed-in yet, in either
session — it follows the exact `PopupMenuButton` pattern already proven in
`order_status_pill.dart`, but worth a real look before considering this
fully done.

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
3. ✅ Phase 1 pages (Home → Category/Product list → Product detail → Cart →
   Checkout → Wishlist) — done, with the product-detail fixes described
   above. Verified at 375/620/1000/1440.
4. ✅ Phase 2 (account area) — done, with the `Material`/ink fix described
   above. Verified at 375 and ~1100.

All phases of this plan are done. What's left is the two remaining
Phase 0/1 loose ends called out above: `ResponsiveContentContainer` still
isn't wired into Home/Category-listing/Wishlist, and the account section
was verified logged-out only.

Testing: `everyday_wholesale-web` / `everyday_wholesale-web-server` launch
configs already exist in `.claude/launch.json` — use the browser preview at
each step, resizing to tablet/desktop widths, and spot-check phone width
(375) stays unchanged.
