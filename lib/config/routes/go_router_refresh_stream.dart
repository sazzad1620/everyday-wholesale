import 'dart:async';

import 'package:flutter/foundation.dart';

/// Bridges a Bloc/Stream into go_router's `refreshListenable` — standard
/// pattern from go_router's own docs. Without this, `redirect` only runs on
/// navigation events, so signing out (or in) while already sitting on a
/// guarded route wouldn't re-evaluate the guard until the next navigation.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
