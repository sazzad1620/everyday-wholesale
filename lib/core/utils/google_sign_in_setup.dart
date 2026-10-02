import 'package:google_sign_in/google_sign_in.dart';

/// One-time `GoogleSignIn.instance.initialize()` for Android/iOS.
///
/// The package requires it exactly once, before any other GoogleSignIn call.
/// It used to be awaited during startup, delaying the first frame for a
/// feature only the "Continue with Google" button needs. Startup now starts
/// it in the background and every GoogleSignIn call awaits [ensureReady]
/// first — instant if it already finished. (Web signs in through Firebase's
/// popup and never calls this.)
abstract final class GoogleSignInSetup {
  static Future<void>? _ready;

  static Future<void> ensureReady() => _ready ??= _initialize();

  static Future<void> _initialize() async {
    try {
      await GoogleSignIn.instance.initialize();
    } catch (_) {
      _ready = null; // let the next sign-in attempt retry
      rethrow;
    }
  }
}
