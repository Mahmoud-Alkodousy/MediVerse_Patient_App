import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _ready = false;

  static Future<void> initialize() async {
    if (_ready) return;

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );
    _ready = true;
  }

  static Future<void> _show({
    required int    id,
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'mediverse_queue',
      'MediVerse - متابعة الدور',
      channelDescription: 'إشعارات الدور والمواعيد',
      importance:     Importance.max,
      priority:       Priority.high,
      playSound:      true,
      enableVibration: true,
      styleInformation: BigTextStyleInformation(''),
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    await _plugin.show(
      id,
      title,
      body,
      const NotificationDetails(android: androidDetails, iOS: iosDetails),
    );
  }

  static Future<void> notifyTurnSoon(String doctorName, String location) =>
      _show(
        id:    1,
        title: '🔔 دورك قريب!',
        body:  'باقي مريض واحد — استعد للذهاب إلى د. $doctorName\n📍 $location',
      );

  static Future<void> notifyYourTurn(String doctorName, String location) =>
      _show(
        id:    2,
        title: '🏥 حان دورك الآن!',
        body:  'توجّه فوراً إلى د. $doctorName\n📍 $location',
      );
}
