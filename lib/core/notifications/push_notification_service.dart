import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../config/di/injection_container.dart';
import '../../config/routes/app_router.dart';
import '../../config/routes/route_paths.dart';
import '../../features/offer/presentation/bloc/offer_badge_bloc.dart';
import 'offer_notification.dart';

/// Receives offer pushes on Android/iOS. Every install — signed in or not —
/// subscribes to one FCM topic per app language (`all_en` / `all_ja`); the
/// `sendOffer` Cloud Function sends each topic its own language, so the
/// notification text follows the app's language, not the device's.
///
/// Android gets a data-only message and draws the notification itself (see
/// [OfferNotification]); iOS gets a normal alert that the system draws. Web
/// is skipped on purpose (offers are read on the Offers page there), so
/// every method is a no-op when [kIsWeb].
abstract final class PushNotificationService {
  static const _topicPrefix = 'all_';

  /// Subscribing can fail for a while after launch (offline, or on iOS before
  /// Apple has handed out the push token), so it retries a few times.
  static const _maxSubscribeRetries = 6;

  static bool get _isAndroid => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  static bool get _isApple =>
      !kIsWeb && (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.macOS);

  /// The language the device is currently subscribed to, if any.
  static String? _subscribedLanguage;

  /// The language the app currently wants; a retry always chases this one.
  static String? _wantedLanguage;
  static bool _subscribeInFlight = false;

  /// Languages whose topic still has to be left after switching language.
  static final Set<String> _staleLanguages = {};
  static String? _pendingRoute;

  /// Call once at startup (not awaited). Never throws — a notification
  /// problem must not stop the app from launching.
  static Future<void> init() async {
    if (kIsWeb) return;
    // Listeners first and in their own guard: whatever fails further down
    // (permission, Android setup) must not leave taps unhandled.
    try {
      FirebaseMessaging.onMessage.listen(_onForegroundMessage);
      FirebaseMessaging.onMessageOpenedApp.listen(_onOpened);
    } catch (e) {
      debugPrint('PushNotificationService: listeners failed: $e');
    }

    try {
      final messaging = FirebaseMessaging.instance;
      // Shows the Android 13+ / iOS permission prompt. Declining only means
      // no system banners; the Offers page still works.
      await messaging.requestPermission();

      if (_isAndroid) {
        // App in the background or closed: handled in a separate isolate (the
        // top-level function builds the notification there).
        FirebaseMessaging.onBackgroundMessage(offerBackgroundMessageHandler);
        // The local-notification plugin is Android-only here; on iOS it is
        // never initialised, because it would then compete with Firebase for
        // control of notification taps.
        await OfferNotification.ensureInitialized(onTap: _onNotificationTap);
      } else if (_isApple) {
        // iOS draws the alert itself, also while the app is open.
        await messaging.setForegroundNotificationPresentationOptions(alert: true, badge: true, sound: true);
      }

      // App was launched by tapping an offer: held until the splash has
      // routed to Home (see `openPendingRoute`), or it would be navigated
      // over. `getInitialMessage` is the iOS path; Android taps arrive via
      // the local notification instead.
      final initial = await messaging.getInitialMessage();
      if (initial != null) _pendingRoute = _routeFor(initial);
      if (_isAndroid && await OfferNotification.launchedFromNotification()) {
        _pendingRoute = RoutePaths.offers;
      }
    } catch (e) {
      debugPrint('PushNotificationService.init failed: $e');
    }
  }

  /// Keeps the device on the topic for [languageCode] only. Idempotent, so
  /// it is safe to call on every rebuild of the app root.
  static Future<void> syncLanguage(String languageCode) async {
    if (kIsWeb) return;
    _wantedLanguage = languageCode;
    if (_subscribeInFlight) return;
    if (_subscribedLanguage == languageCode && _staleLanguages.isEmpty) return;
    _subscribeInFlight = true;
    try {
      await _subscribeWithRetry();
    } finally {
      _subscribeInFlight = false;
    }
  }

  static Future<void> _subscribeWithRetry() async {
    for (var attempt = 0; attempt <= _maxSubscribeRetries; attempt++) {
      final wanted = _wantedLanguage;
      if (wanted == null) return;
      try {
        final messaging = FirebaseMessaging.instance;
        if (_subscribedLanguage != wanted) {
          // Topic subscription on Apple platforms needs the APNs token first
          // (it arrives a moment after launch, and never on a Simulator).
          if (_isApple && await messaging.getAPNSToken() == null) {
            throw StateError('APNs token not available yet');
          }
          await messaging.subscribeToTopic('$_topicPrefix$wanted');
          final previous = _subscribedLanguage;
          _subscribedLanguage = wanted;
          if (previous != null && previous != wanted) _staleLanguages.add(previous);
        }
        // Leaving the old language's topic is separate and retried on its
        // own, so a failure here can never leave the device getting pushes
        // in both languages for good.
        await _leaveStaleTopics(messaging);
        // The language may have changed again while this was running.
        if (_wantedLanguage == _subscribedLanguage && _staleLanguages.isEmpty) return;
      } catch (e) {
        debugPrint('PushNotificationService.syncLanguage attempt ${attempt + 1} failed: $e');
      }
      await Future<void>.delayed(Duration(seconds: 5 * (attempt + 1)));
    }
  }

  static Future<void> _leaveStaleTopics(FirebaseMessaging messaging) async {
    // Never leave the topic we are (again) subscribed to.
    _staleLanguages.remove(_subscribedLanguage);
    for (final language in _staleLanguages.toList()) {
      await messaging.unsubscribeFromTopic('$_topicPrefix$language');
      _staleLanguages.remove(language);
    }
  }

  /// Opens the page a launch-from-push asked for. Called by the splash right
  /// after it routes to Home.
  static void openPendingRoute() {
    final route = _pendingRoute;
    if (route == null) return;
    _pendingRoute = null;
    appRouter.push(route);
  }

  static Future<void> _onForegroundMessage(RemoteMessage message) async {
    // The bell's "new" dot should light up right away, not at next launch.
    getIt<OfferBadgeBloc>().add(const OfferBadgeRefreshed());
    // Android shows nothing by itself while the app is open, so draw the
    // same notification the background path would (iOS draws its own).
    if (_isAndroid) {
      try {
        await showOfferFromMessage(message);
      } catch (e) {
        debugPrint('PushNotificationService: could not show offer: $e');
      }
    }
  }

  static void _onNotificationTap(NotificationResponse response) {
    if (response.payload == OfferNotification.payload) appRouter.push(RoutePaths.offers);
  }

  static void _onOpened(RemoteMessage message) {
    final route = _routeFor(message);
    if (route != null) appRouter.push(route);
  }

  static String? _routeFor(RemoteMessage message) => message.data['type'] == 'offer' ? RoutePaths.offers : null;
}
