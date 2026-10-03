import 'dart:async';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Draws the offer notification on Android.
///
/// Offer pushes arrive as data-only messages (see `sendOffer` in
/// `functions/src/index.ts`) and the app builds the notification itself,
/// instead of letting Firebase's notification payload do it, because only
/// then can it look like other shopping apps (Foodi, Daraz): the full text
/// on expand, with the real logo as the large icon on the right. Firebase's
/// own payload can only add a big picture, and Android draws the small
/// status-bar icon as a flat shape, so the logo can't go there. On iOS the
/// push carries an `apns` alert and the system draws it.
abstract final class OfferNotification {
  /// Tapping a notification carries this; the router opens the Offers page.
  static const String payload = 'offer';

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'offers',
    'Offers',
    description: 'Deals, discounts and delivery offers from Everyday Wholesale.',
    importance: Importance.high,
  );

  /// Flat white cart shown in the status bar (`res/drawable/ic_stat_offer.xml`).
  static const String _smallIcon = 'ic_stat_offer';

  /// Full-colour logo shown on the right (`res/drawable-nodpi/ic_notification_large.png`,
  /// built by `dart run tool/make_notification_large_icon.dart`).
  static const DrawableResourceAndroidBitmap _largeIcon = DrawableResourceAndroidBitmap('ic_notification_large');

  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  static bool _ready = false;

  /// Safe to call repeatedly, and from the background isolate (which has its
  /// own copy of this state). [onTap] only matters in the main isolate.
  static Future<void> ensureInitialized({DidReceiveNotificationResponseCallback? onTap}) async {
    if (_ready) return;
    await _plugin.initialize(
      settings: const InitializationSettings(android: AndroidInitializationSettings(_smallIcon)),
      onDidReceiveNotificationResponse: onTap,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);
    _ready = true;
  }

  /// Whether the app was started by tapping one of these notifications.
  static Future<bool> launchedFromNotification() async {
    final details = await _plugin.getNotificationAppLaunchDetails();
    return (details?.didNotificationLaunchApp ?? false) && details?.notificationResponse?.payload == payload;
  }

  static Future<void> show({
    required String title,
    required String body,
    String? imageUrl,
    String? offerId,
  }) async {
    await ensureInitialized();

    // An offer's own photo becomes the expanded banner; without one the body
    // simply expands to its full text. The logo stays on the right in both
    // cases.
    final picture = (imageUrl == null || imageUrl.isEmpty) ? null : await _download(imageUrl);
    final StyleInformation style = picture == null
        ? BigTextStyleInformation(body)
        : BigPictureStyleInformation(
            ByteArrayAndroidBitmap(picture),
            contentTitle: title,
            summaryText: body,
            largeIcon: _largeIcon,
          );

    await _plugin.show(
      id: (offerId ?? '$title$body').hashCode & 0x7fffffff,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          icon: _smallIcon,
          largeIcon: _largeIcon,
          importance: Importance.high,
          priority: Priority.high,
          styleInformation: style,
          category: AndroidNotificationCategory.promo,
        ),
      ),
      payload: payload,
    );
  }

  /// Best effort: a slow or failing download just means the text-only layout.
  static Future<Uint8List?> _download(String url) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 6);
    try {
      final request = await client.getUrl(Uri.parse(url)).timeout(const Duration(seconds: 8));
      final response = await request.close().timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return null;
      final bytes = await consolidateHttpClientResponseBytes(response).timeout(const Duration(seconds: 12));
      return bytes.length > 5 * 1024 * 1024 ? null : bytes;
    } catch (e) {
      debugPrint('OfferNotification: image download failed: $e');
      return null;
    } finally {
      client.close(force: true);
    }
  }
}

/// Runs in its own isolate when an offer arrives while the app is in the
/// background or closed. Must be top-level for that reason.
@pragma('vm:entry-point')
Future<void> offerBackgroundMessageHandler(RemoteMessage message) async {
  await showOfferFromMessage(message);
}

/// Shows [message] as an offer notification if it is a data-only offer push
/// (the only kind the app has to draw itself).
Future<void> showOfferFromMessage(RemoteMessage message) async {
  final data = message.data;
  if (data['type'] != 'offer' || message.notification != null) return;
  final title = data['title'] as String? ?? '';
  final body = data['body'] as String? ?? '';
  if (title.isEmpty && body.isEmpty) return;
  await OfferNotification.show(
    title: title,
    body: body,
    imageUrl: data['imageUrl'] as String?,
    offerId: data['offerId'] as String?,
  );
}
