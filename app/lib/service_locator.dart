import 'package:get_it/get_it.dart';
import 'package:imu_tracker/services/localstorage_service.dart';
import 'package:imu_tracker/services/websocket_handler.dart';

final getIt = GetIt.instance;

Future setupLocator() async {
  var LocalStorageInstance = await LocalStorageService.getInstance();
  getIt.registerSingleton<LocalStorageService>(LocalStorageInstance);

/*
  var WebSocketServiceInstance = await WebSocketService.getInstance();
  getIt.registerSingleton<WebSocketService>(WebSocketServiceInstance);
*/

  getIt.registerLazySingleton<WebSocketService>(() => WebSocketService());
}
