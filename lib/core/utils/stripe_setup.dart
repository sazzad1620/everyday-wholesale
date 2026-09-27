import 'package:flutter_stripe/flutter_stripe.dart';

import '../constants/stripe_config.dart';

/// One-time Stripe SDK initialization, shared by app startup and the
/// payment flow.
///
/// On web, `applySettings()` downloads Stripe.js (flutter_stripe_web injects
/// the script itself), so awaiting it during startup held the first frame
/// hostage to a third-party network request only checkout ever needs. Web
/// now warms it up in the background instead, and every payment path calls
/// [ensureReady] first — instant if the warm-up already finished.
abstract final class StripeSetup {
  static Future<void>? _ready;

  static Future<void> ensureReady() => _ready ??= _initialize();

  static Future<void> _initialize() async {
    try {
      Stripe.publishableKey = StripeConfig.publishableKey;
      await Stripe.instance.applySettings();
    } catch (_) {
      // Let the next payment attempt retry (e.g. Stripe.js failed to load on
      // a flaky connection) instead of caching the failure forever.
      _ready = null;
      rethrow;
    }
  }
}
