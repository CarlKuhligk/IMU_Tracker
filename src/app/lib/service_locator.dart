//additional packages
import 'package:get_it/get_it.dart';

//imported classes for dependency injection
import 'package:imu_tracker/services/localstorage_service.dart';
import 'package:imu_tracker/services/notification_service.dart';
import 'package:imu_tracker/services/websocket_handler.dart';
import 'package:imu_tracker/services/internal_sensor_service.dart';
import 'package:imu_tracker/services/device_settings_handler.dart';

final getIt = GetIt.instance;

Future setupLocator() async {
  var localStorageInstance = await LocalStorageService.getInstance();
  getIt.registerSingleton<LocalStorageService>(localStorageInstance);

  var localNotificationInstance = await NotificationService.getInstance();
  getIt.registerSingleton<NotificationService>(localNotificationInstance);

  getIt.registerLazySingleton<WebSocketHandler>(() => WebSocketHandler());

  getIt.registerLazySingleton<InternalSensorService>(
      () => InternalSensorService());

  getIt.registerLazySingleton<DeviceSettingsHandler>(
      () => DeviceSettingsHandler());
}
