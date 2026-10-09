import 'route_paths.dart';

/// Which page, if any, [location] must be redirected to — the admin/customer
/// separation rules, kept free of Flutter and global state so every case can
/// be unit-tested.
///
/// [isInitializing] is true until the saved session has been restored at
/// launch; during that time the role is not known yet, so [rememberedAdmin]
/// (what the last session on this device was) stands in for it. That is what
/// lets a returning admin go straight to the dashboard instead of seeing the
/// customer home first. Once the session resolves, [userIsAdmin] decides, and
/// a wrong guess is corrected by the redirect re-running on that account
/// change.
String? adminRedirect({
  required String location,
  required bool isInitializing,
  required bool userIsAdmin,
  required bool rememberedAdmin,
}) {
  final isAdmin = isInitializing ? rememberedAdmin : userIsAdmin;

  if (location.startsWith(RoutePaths.admin)) {
    return isAdmin ? null : RoutePaths.home;
  }

  // An admin should never land in the customer storefront (bottom-nav
  // Home/Wishlist/Cart) — e.g. a stale link, the browser back button on
  // web, or anything else outside the admin's own navigation. Bounce
  // straight back to the dashboard instead.
  final isCustomerShellRoute =
      location == RoutePaths.home ||
      location == RoutePaths.catalogue ||
      location.startsWith('${RoutePaths.catalogue}/') ||
      location == RoutePaths.categories ||
      location == RoutePaths.wishlist ||
      location == RoutePaths.cart;
  if (isAdmin && isCustomerShellRoute) return RoutePaths.admin;

  return null;
}
