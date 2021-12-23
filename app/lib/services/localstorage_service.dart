import 'dart:convert';

import 'dart:async' show Future;
import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageService {
  static late LocalStorageService _instance;
  static late SharedPreferences _preferences;
  static const String deviceIsSetUpKey = 'deviceIsSetUp';

  static Future<LocalStorageService> getInstance() async {
    _instance = LocalStorageService();

    _preferences = await SharedPreferences.getInstance();

    return _instance;
  }

  writeAuthenticationToMemory(authenticationValues) {}

  getAuthenticationFromMemory() {}

  static bool getDeviceIsRegistered() {
    bool _newLaunch = ((_preferences.getBool(deviceIsSetUpKey) ?? true));
    return _newLaunch;
  }

  void saveStringToDisk(String key, String content) {
    print(
        '(TRACE) LocalStorageService:_saveStringToDisk. key: $key value: $content');
    _preferences.setString(key, content);
  }
}
