import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static Future<NotificationService> getInstance() async {
    final NotificationService _notificationService =
        NotificationService._internal();

    return _notificationService;
  }

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    final AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('app_icon');

    final InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  AndroidNotificationDetails _androidNotificationDetails =
      AndroidNotificationDetails(
    'channel ID',
    'channel name',
    icon: "app_icon",
    playSound: true,
    enableVibration: false,
    priority: Priority.high,
    importance: Importance.high,
  );

  Future<void> showBatteryNotification() async {
    await flutterLocalNotificationsPlugin.show(
      0,
      "Niedriger Akkustand!",
      "Niedriger Akkustand!",
      NotificationDetails(android: _androidNotificationDetails),
    );
  }

  Future<void> cancelBatteryNotification() async {
    await flutterLocalNotificationsPlugin.cancel(0);
  }

  Future<void> showMovementNotification() async {
    await flutterLocalNotificationsPlugin.show(
      3,
      "Bewegungslosigkeit erkannt!",
      "Wenn Sie sich nicht bewegen, wird der Alarm ausgelöst!",
      NotificationDetails(android: _androidNotificationDetails),
    );
  }

  Future<void> cancelMovementNotification() async {
    await flutterLocalNotificationsPlugin.cancel(3);
  }

  Future<void> showLostConnectionNotification() async {
    await flutterLocalNotificationsPlugin.show(
      5,
      "Verbindung zum Server verloren!",
      "Es werden keine Daten gesendet!",
      NotificationDetails(android: _androidNotificationDetails),
    );
  }

  Future<void> cancelLostConnectionNotification() async {
    await flutterLocalNotificationsPlugin.cancel(5);
  }

  Future<void> cancelAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }
}
