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
    playSound: true,
    priority: Priority.high,
    importance: Importance.high,
  );

  Future<void> showBatteryNotification() async {
    await flutterLocalNotificationsPlugin.show(
      0,
      "Battery Level low!",
      "Your Battery Level is too low!",
      NotificationDetails(android: _androidNotificationDetails),
    );
  }

  Future<void> cancelBatteryNotification() async {
    await flutterLocalNotificationsPlugin.cancel(0);
  }

  Future<void> showMovementNotification() async {
    await flutterLocalNotificationsPlugin.show(
      3,
      "You need to move!",
      "If you're not moving within the next seconds, the alarm for no movement will trigger!",
      NotificationDetails(android: _androidNotificationDetails),
    );
  }

  Future<void> cancelMovementNotification() async {
    await flutterLocalNotificationsPlugin.cancel(3);
  }

  Future<void> showLostConnectionNotification() async {
    await flutterLocalNotificationsPlugin.show(
      5,
      "Lost Server Connection",
      "Lost Connection to Server!",
      NotificationDetails(android: _androidNotificationDetails),
    );
  }

  Future<void> cancelLostConnectionNotification() async {
    await flutterLocalNotificationsPlugin.cancel(3);
  }
}
