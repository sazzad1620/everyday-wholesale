import 'package:everyday_wholesale/core/utils/admin_session_hint.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('defaults to "not an admin" when nothing was saved', () async {
    SharedPreferences.setMockInitialValues({});
    await AdminSessionHint.load();
    expect(AdminSessionHint.isAdmin, isFalse);
  });

  test('a saved admin session is available synchronously after load', () async {
    SharedPreferences.setMockInitialValues({'last_session_was_admin': true});
    await AdminSessionHint.load();
    expect(AdminSessionHint.isAdmin, isTrue);
  });

  test('record() updates the hint at once and persists it for the next launch', () async {
    SharedPreferences.setMockInitialValues({});
    await AdminSessionHint.load();

    AdminSessionHint.record(isAdmin: true);
    expect(AdminSessionHint.isAdmin, isTrue);
    // Let the fire-and-forget save finish.
    await Future<void>.delayed(Duration.zero);
    expect((await SharedPreferences.getInstance()).getBool('last_session_was_admin'), isTrue);

    // Signing out (or a non-admin signing in) clears it.
    AdminSessionHint.record(isAdmin: false);
    expect(AdminSessionHint.isAdmin, isFalse);
    await Future<void>.delayed(Duration.zero);
    expect((await SharedPreferences.getInstance()).getBool('last_session_was_admin'), isFalse);
  });
}
