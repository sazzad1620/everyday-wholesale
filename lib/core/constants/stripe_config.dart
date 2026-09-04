/// The publishable key is, by Stripe's own design, safe to ship in client
/// code — it can only create PaymentIntents' client-side confirmation step,
/// never charge anything on its own. Still not hardcoded here: it's supplied
/// at build/run time via `--dart-define=STRIPE_PUBLISHABLE_KEY=pk_test_...`
/// (or `pk_live_...` once Phase E switches to live keys), so switching
/// between test and live — or rotating a leaked key — never needs a code
/// change or a git commit.
abstract final class StripeConfig {
  static const String publishableKey = String.fromEnvironment('STRIPE_PUBLISHABLE_KEY');
}
