import 'package:everyday_wholesale/config/routes/admin_redirect.dart';
import 'package:everyday_wholesale/config/routes/route_paths.dart';
import 'package:flutter_test/flutter_test.dart';

String? _go(
  String location, {
  bool initializing = false,
  bool admin = false,
  bool remembered = false,
}) => adminRedirect(
  location: location,
  isInitializing: initializing,
  userIsAdmin: admin,
  rememberedAdmin: remembered,
);

void main() {
  group('while the saved session is still being restored', () {
    test('a remembered admin opening the site goes straight to the dashboard', () {
      expect(_go(RoutePaths.home, initializing: true, remembered: true), RoutePaths.admin);
      expect(_go(RoutePaths.cart, initializing: true, remembered: true), RoutePaths.admin);
    });

    test('a remembered admin is allowed on /admin (no bounce to the customer home)', () {
      expect(_go(RoutePaths.admin, initializing: true, remembered: true), isNull);
      expect(_go(RoutePaths.adminOfferForm, initializing: true, remembered: true), isNull);
    });

    test('anyone else is kept off /admin', () {
      expect(_go(RoutePaths.admin, initializing: true), RoutePaths.home);
      expect(_go(RoutePaths.home, initializing: true), isNull);
    });
  });

  group('once the session is known, the real role decides', () {
    test('a wrongly remembered admin (session expired / now a customer) is sent off /admin', () {
      expect(_go(RoutePaths.admin, remembered: true), RoutePaths.home);
    });

    test('a customer who was not remembered as admin still reaches the storefront', () {
      expect(_go(RoutePaths.home), isNull);
      expect(_go(RoutePaths.wishlist), isNull);
    });

    test('a real admin stays out of the storefront but can use pages outside it', () {
      expect(_go(RoutePaths.home, admin: true), RoutePaths.admin);
      expect(_go(RoutePaths.categoryProducts('rice'), admin: true), RoutePaths.admin);
      expect(_go(RoutePaths.admin, admin: true), isNull);
      expect(_go(RoutePaths.offers, admin: true), isNull);
      expect(_go(RoutePaths.support, admin: true), isNull);
    });

    test('a real admin whose hint was missing (first sign-in on a device) is not locked out', () {
      expect(_go(RoutePaths.admin, admin: true, remembered: false), isNull);
    });
  });

  test('the splash route is never redirected', () {
    expect(_go(RoutePaths.splash), isNull);
    expect(_go(RoutePaths.splash, initializing: true, remembered: true), isNull);
  });
}
