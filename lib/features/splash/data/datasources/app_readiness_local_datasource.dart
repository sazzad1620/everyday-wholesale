import 'package:injectable/injectable.dart';

abstract class AppReadinessLocalDatasource {
  Future<bool> checkAppReady();
}

/// No artificial minimum splash time on any platform any more: the logo is
/// already on screen before Flutter starts (the native launch screen on
/// Android/iOS, `index.html`'s loading screen on web) and the splash page
/// shows the same logo, so holding it for a fixed 1.2 s (the old mobile
/// minimum) only made every launch slower. The splash still waits for the
/// saved session on mobile (see `SplashPage`), so admins land directly on
/// the admin panel without a flash of the storefront.
@LazySingleton(as: AppReadinessLocalDatasource)
class AppReadinessLocalDatasourceImpl implements AppReadinessLocalDatasource {
  @override
  Future<bool> checkAppReady() async => true;
}
