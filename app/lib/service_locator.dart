//additional packages
import 'package:get_it/get_it.dart';

//imported classes for dependency injection
import 'package:imu_tracker/services/localstorage_service.dart';
import 'package:imu_tracker/services/websocket_handler.dart';

final getIt = GetIt.instance;

Future setupLocator() async {
  var localStorageInstance = await LocalStorageService.getInstance();
  getIt.registerSingleton<LocalStorageService>(localStorageInstance);

  getIt.registerLazySingleton<WebSocketHandler>(() => WebSocketHandler());
}
