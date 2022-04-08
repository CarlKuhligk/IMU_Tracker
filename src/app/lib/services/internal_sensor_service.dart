// ignore_for_file: prefer_typing_uninitialized_variables
//dart packages

import 'dart:async';
import 'dart:math';

import 'package:sensors/sensors.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:environment_sensors/environment_sensors.dart';

class InternalSensorService {
  final Battery _battery = Battery();

  BatteryState? batteryState;
  StreamSubscription<BatteryState>? _batteryStateSubscription;

  StreamSubscription? accelerationSubscription;
  StreamSubscription? gyroscopeSubscription;
  Timer? measurementIntervalTimer;

  var magnitudeAccelerometer;
  var magnitudeGyroscope;
  var _accelerationValues;
  var _gyroscopeValues;
  var batteryLevel;

  startInternalSensors() {
    _startGyroscopeSensor();
    _startAccelerationSensor();
    _startBatterySensor();
    _startMeasurementInterval();
  }

  _startGyroscopeSensor() {
    // if the gyroscope subscription hasn't been created, go ahead and create it
    if (gyroscopeSubscription == null) {
      gyroscopeSubscription = gyroscopeEvents.listen((GyroscopeEvent eve) {
        _gyroscopeValues = eve;
      });
    } else {
      // it has already ben created so just resume it
      gyroscopeSubscription?.resume();
    }
  }

  _startAccelerationSensor() {
    // if the accelerometer subscription hasn't been created, go ahead and create it
    if (accelerationSubscription == null) {
      accelerationSubscription =
          userAccelerometerEvents.listen((UserAccelerometerEvent eve) {
        _accelerationValues = eve;
      });
    } else {
      // it has already ben created so just resume it
      accelerationSubscription?.resume();
    }
  }

  _startBatterySensor() {
    // if the battery subscription hasn't been created, go ahead and create it
    if (_batteryStateSubscription == null) {
      _batteryStateSubscription =
          _battery.onBatteryStateChanged.listen((BatteryState state) {
        batteryState = state;
      });
    } else {
      // it has already ben created so just resume it
      _batteryStateSubscription?.resume();
    }
  }

  _startMeasurementInterval() {
    if (measurementIntervalTimer == null ||
        !measurementIntervalTimer!.isActive) {
      measurementIntervalTimer =
          Timer.periodic(const Duration(milliseconds: 200), (_) {
        //TODO: get measurement interval from settings
        _getBatteryPercentage();
        _calculateGyroscopeMagnitude();
        _calculateAccelerometerMagnitude();
      });
    }
  }

  _getBatteryPercentage() async {
    batteryLevel = await _battery.batteryLevel;
  }

  _calculateGyroscopeMagnitude() {
    var rawData = _gyroscopeValues;
    magnitudeGyroscope = sqrt((rawData.x * rawData.x) +
        (rawData.y * rawData.y) +
        (rawData.z * rawData.z));
  }

  _calculateAccelerometerMagnitude() {
    var rawData = _accelerationValues;
    magnitudeAccelerometer = sqrt((rawData.x * rawData.x) +
        (rawData.y * rawData.y) +
        (rawData.z * rawData.z));
  }
}
