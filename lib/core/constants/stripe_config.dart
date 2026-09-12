/// The publishable key is, by Stripe's own design, safe to ship in client
/// code — it can only create PaymentIntents' client-side confirmation step,
/// never charge anything on its own. It's supplied at build/run time via
/// `--dart-define=STRIPE_PUBLISHABLE_KEY=pk_test_...` (or `pk_live_...` once
/// Phase E switches to live keys), so switching between test and live — or
/// rotating a leaked key — never needs a code change or a git commit; the
/// value below is only a dev-time fallback so plain `flutter run` (no
/// dart-define) still works, and any `--dart-define` passed at run/build
/// time overrides it.
abstract final class StripeConfig {
  static const String publishableKey = String.fromEnvironment(
    'STRIPE_PUBLISHABLE_KEY',
    defaultValue:
        'pk_test_51UAfxwGkGBNqFcW8jjwTYRXH1kuP8IMp9zF9Hkk89WPL1dP6UEs0Scmi75uKHhli1VHUhNCVx0prWfx1nBJRiNOZ00EYKII3Bi',
  );
}
