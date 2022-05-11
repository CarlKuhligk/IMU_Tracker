// ignore_for_file: prefer_typing_uninitialized_variables
//flutter packages
import 'package:flutter/material.dart';
//dart packages
import 'dart:async';
import 'dart:math';

//additional packages
import 'package:sensors/sensors.dart';
import 'package:battery_info/battery_info_plugin.dart';

//project internal services / dependency injection
import 'package:imu_tracker/service_locator.dart';
import 'package:imu_tracker/services/device_settings_handler.dart';
import 'package:imu_tracker/services/notification_service.dart';

class InternalSensorService {
  var _deviceSettings = getIt<DeviceSettingsHandler>();
  var _notificationService = getIt<NotificationService>();

  final _battery = BatteryInfoPlugin();

  StreamSubscription? _accelerationSubscription;
  StreamSubscription? _gyroscopeSubscription;
  Timer? _movementTimer;

  var _accelerationValues;
  var _gyroscopeValues;
  var magnitudeAccelerometer;
  var magnitudeGyroscope;
  var batteryLevel;
  var deviceTemperature;

  ValueNotifier<bool> movementAlarmstate = ValueNotifier<bool>(false);
  ValueNotifier<bool> batteryAlarmstate = ValueNotifier<bool>(false);

  startInternalSensors() {
    _startGyroscopeSensor();
    _startAccelerationSensor();
    _startBatterySensor();
  }

  stopSensors() {
    _movementTimer!.cancel();
    movementAlarmstate.value = false;
    batteryAlarmstate.value = false;
    _accelerationSubscription!.cancel();
    _gyroscopeSubscription!.cancel();
  }

  _startGyroscopeSensor() {
    // if the gyroscope subscription hasn't been created, go ahead and create it
    if (_gyroscopeSubscription == null) {
      _gyroscopeSubscription = gyroscopeEvents.listen((GyroscopeEvent eve) {
        _gyroscopeValues = eve;
      });
    } else {
      // it has already ben created so just resume it
      _gyroscopeSubscription?.resume();
    }
  }

  _startAccelerationSensor() {
    // if the accelerometer subscription hasn't been created, go ahead and create it
    if (_accelerationSubscription == null) {
      _accelerationSubscription =
          userAccelerometerEvents.listen((UserAccelerometerEvent eve) {
        _accelerationValues = eve;
      });
    } else {
      // it has already ben created so just resume it
      _accelerationSubscription?.resume();
    }
  }

  _startBatterySensor() {
    _battery.androidBatteryInfoStream.listen((event) {
      deviceTemperature = event!.temperature;
      batteryLevel = event.batteryLevel;
    });
  }

  getCurrentValues() {
    _calculateGyroscopeMagnitude();
    _calculateAccelerometerMagnitude();
    _checkMovementTimeout();
    _checkBatteryAlarmstate();
  }

  _calculateGyroscopeMagnitude() {
    var rawData = _gyroscopeValues;
    magnitudeGyroscope = sqrt(_sqrVariable(rawData.x) +
        _sqrVariable(rawData.y) +
        _sqrVariable(rawData.z));
  }

  _calculateAccelerometerMagnitude() {
    var rawData = _accelerationValues;
    magnitudeAccelerometer = sqrt(_sqrVariable(rawData.x) +
        _sqrVariable(rawData.y) +
        _sqrVariable(rawData.z));
  }

  _checkMovementTimeout() {
    if (magnitudeAccelerometer < _deviceSettings.deviceSettings["a"]) {
      if (_movementTimer == null || !_movementTimer!.isActive) {
        _movementTimer = Timer(
          Duration(seconds: (_deviceSettings.deviceSettings["it"])),
          () {
            if (!movementAlarmstate.value) {
              _notificationService.showMovementNotification();
            }
            movementAlarmstate.value = true;
          },
        );
      }
    } else {
      movementAlarmstate.value = false;
      _notificationService.cancelMovementNotification();
      _movementTimer!.cancel();
    }
  }

  _checkBatteryAlarmstate() {
    if (batteryLevel < _deviceSettings.deviceSettings["b"]) {
      if (!batteryAlarmstate.value) {
        _notificationService.showBatteryNotification();
      }
      batteryAlarmstate.value = true;
    } else {
      _notificationService.cancelBatteryNotification();
      batteryAlarmstate.value = false;
    }
  }

  _sqrVariable(value) {
    return value * value;
  }
}
