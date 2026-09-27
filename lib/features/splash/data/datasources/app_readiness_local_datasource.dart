import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

abstract class AppReadinessLocalDatasource {
  Future<bool> checkAppReady();
}

@LazySingleton(as: AppReadinessLocalDatasource)
class AppReadinessLocalDatasourceImpl implements AppReadinessLocalDatasource {
  /// Minimum time the splash logo stays up on mobile, so it reads as a
  /// deliberate brand moment rather than a flicker. Web skips it: by the
  /// time Flutter draws its first frame the visitor has already been
  /// watching the same logo on `index.html`'s loading screen, so holding it
  /// longer is pure extra wait.
  static const Duration _mobileMinimumSplash = Duration(milliseconds: 1200);

  @override
  Future<bool> checkAppReady() async {
    if (!kIsWeb) await Future<void>.delayed(_mobileMinimumSplash);
    return true;
  }
}
