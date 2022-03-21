//dart packages
import 'dart:convert';
import 'dart:async' show Future;

//additional packages
import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageService {
  static late LocalStorageService _instance;
  static late SharedPreferences _preferences;
  static const String deviceIsSetUpKey = 'deviceIsSetUp';
  static const String authenticationValuesKey = 'AuthenticationValues';

  static Future<LocalStorageService> getInstance() async {
    _instance = LocalStorageService();

    _preferences = await SharedPreferences.getInstance();

    return _instance;
  }

  static void writeAuthenticationToMemory(authenticationValues) {
    _preferences.setString(authenticationValuesKey, authenticationValues);
  }

  static getAuthenticationFromMemory() {
    var _authenticationValues = _preferences.getString(authenticationValuesKey);
    if (_authenticationValues != null) {
      return jsonDecode(_authenticationValues);
    } else {
      //TODO Implement error handling
      return "";
    }
  }

  static void setDeviceIsRegistered(isRegistered) {
    _preferences.setBool(deviceIsSetUpKey, isRegistered);
  }

  static bool getDeviceIsRegistered() {
    bool _isRegistered = ((_preferences.getBool(deviceIsSetUpKey) ?? true));
    return _isRegistered;
  }
}
