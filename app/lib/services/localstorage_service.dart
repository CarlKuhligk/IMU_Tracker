import 'dart:convert';

import 'dart:async' show Future;
import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageService {
  static late LocalStorageService _instance;
  static late SharedPreferences _preferences;
  static const String deviceIsSetUpKey = 'deviceIsSetUp';
  static const String AuthenticationValuesKey = 'AuthenticationValues';

  static Future<LocalStorageService> getInstance() async {
    _instance = LocalStorageService();

    _preferences = await SharedPreferences.getInstance();

    return _instance;
  }

  static void writeAuthenticationToMemory(authenticationValues) {
    _preferences.setString(AuthenticationValuesKey, authenticationValues);
  }

  static getAuthenticationFromMemory() {
    var _authenticationValues = (AuthenticationValuesKey);
    return jsonDecode(_authenticationValues);
  }

  static void setDeviceIsRegistered(isRegistered) {
    _preferences.setBool(deviceIsSetUpKey, isRegistered);
  }

  static bool getDeviceIsRegistered() {
    bool _isRegistered = ((_preferences.getBool(deviceIsSetUpKey) ?? true));
    return _isRegistered;
  }
}
