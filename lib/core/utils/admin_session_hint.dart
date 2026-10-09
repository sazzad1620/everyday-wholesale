import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Remembers on this device whether the last signed-in account was an admin.
///
/// Why: a returning admin's session is restored asynchronously, and until it
/// is, the app can't know the user is an admin — so it showed the customer
/// home page for a moment and *then* jumped to the dashboard. With this hint
/// the router and splash send a returning admin straight to `/admin` at
/// startup. It is only a hint, never a permission: the real role still comes
/// from Firestore, and if the restored account turns out not to be an admin
/// (session expired, role removed) the router's redirect moves them off
/// `/admin` as soon as that is known. Admin screens' data is protected by
/// Firestore rules regardless.
abstract final class AdminSessionHint {
  static const _key = 'last_session_was_admin';

  static bool _isAdmin = false;

  /// Whether the last session on this device was an admin's. Read
  /// synchronously (it is loaded once during startup — see [load]).
  static bool get isAdmin => _isAdmin;

  /// Call once during startup, before the router first runs.
  static Future<void> load() async {
    try {
      _isAdmin = (await SharedPreferences.getInstance()).getBool(_key) ?? false;
    } catch (e) {
      // Storage unavailable (private mode…): behave as "not an admin".
      debugPrint('AdminSessionHint.load failed: $e');
    }
  }

  /// Called whenever the signed-in account is known (including "nobody").
  static void record({required bool isAdmin}) {
    if (_isAdmin == isAdmin) return;
    _isAdmin = isAdmin;
    unawaited(_save(isAdmin));
  }

  static Future<void> _save(bool isAdmin) async {
    try {
      await (await SharedPreferences.getInstance()).setBool(_key, isAdmin);
    } catch (e) {
      debugPrint('AdminSessionHint.save failed: $e');
    }
  }
}
