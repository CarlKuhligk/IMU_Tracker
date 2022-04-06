//dart packages
import 'dart:async';

import 'package:sensors/sensors.dart';
import 'package:battery_plus/battery_plus.dart';

class InternalSensorService {
  final Battery _battery = Battery();

  BatteryState? batteryState;
  StreamSubscription<BatteryState>? _batteryStateSubscription;

  StreamSubscription? accelerationSubscription;
  StreamSubscription? gyroscopeSubscription;
  Timer? timer;
  UserAccelerometerEvent? event;

  var accelerationValues;
  var gyroscopeValues;

  startInternalSensors() {
    if (_batteryStateSubscription == null) {
      _batteryStateSubscription =
          _battery.onBatteryStateChanged.listen((BatteryState state) {
        batteryState = state;
      });
    } else {
      // it has already ben created so just resume it
      _batteryStateSubscription?.resume();
    }

    // if the accelerometer subscription hasn't been created, go ahead and create it
    if (accelerationSubscription == null) {
      accelerationSubscription =
          userAccelerometerEvents.listen((UserAccelerometerEvent eve) {
        accelerationValues = eve;
      });
    } else {
      // it has already ben created so just resume it
      accelerationSubscription?.resume();
    }

    if (gyroscopeSubscription == null) {
      gyroscopeSubscription = gyroscopeEvents.listen((GyroscopeEvent eve) {
        gyroscopeValues = eve;
      });
    } else {
      // it has already ben created so just resume it
      gyroscopeSubscription?.resume();
    }
  }
}
