import 'package:get_it/get_it.dart';
import 'package:imu_tracker/services/localstorage_service.dart';

final getIt = GetIt.instance;

Future setupLocator() async {
  var instance = await LocalStorageService.getInstance();
  getIt.registerSingleton<LocalStorageService>(instance);

  //getIt.registerLazySingleton<LocalStorageService>(() => LocalStorageService());
}
