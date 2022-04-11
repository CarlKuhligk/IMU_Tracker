// ignore_for_file: prefer_typing_uninitialized_variables
//dart packages
import 'dart:async';
import 'dart:math';

import 'package:sensors/sensors.dart';

import 'package:battery_info/battery_info_plugin.dart';

class InternalSensorService {
  final _battery = BatteryInfoPlugin();

  StreamSubscription? accelerationSubscription;
  StreamSubscription? gyroscopeSubscription;
  Timer? measurementIntervalTimer;

  var magnitudeAccelerometer;
  var magnitudeGyroscope;
  var _accelerationValues;
  var _gyroscopeValues;
  var batteryLevel;
  var deviceTemperature;

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
    _battery.androidBatteryInfoStream.listen((event) {
      deviceTemperature = event!.temperature;
      batteryLevel = event.batteryLevel;
    });
  }

  _startMeasurementInterval() {
    if (measurementIntervalTimer == null ||
        !measurementIntervalTimer!.isActive) {
      measurementIntervalTimer =
          Timer.periodic(const Duration(milliseconds: 200), (_) {
        _calculateGyroscopeMagnitude();
        _calculateAccelerometerMagnitude();
      });
    }
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
