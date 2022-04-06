//flutter packages
// ignore_for_file: prefer_typing_uninitialized_variables

import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:async';

//additional packages
import 'package:sensors/sensors.dart';
import 'package:battery_plus/battery_plus.dart';

//project internal services / dependency injection
import 'package:imu_tracker/service_locator.dart';
import 'package:imu_tracker/services/websocket_handler.dart';
import 'package:imu_tracker/services/localstorage_service.dart';

class MainPage extends StatefulWidget {
  const MainPage({
    Key? key,
  }) : super(key: key);
  @override
  _MyMainPageState createState() => _MyMainPageState();
}

class _MyMainPageState extends State<MainPage> {
  var websocket = getIt<WebSocketHandler>();
  final Battery _battery = Battery();

  BatteryState? _batteryState;
  StreamSubscription<BatteryState>? _batteryStateSubscription;

  StreamSubscription? accelerationSubscription;
  StreamSubscription? gyroscopeSubscription;
  Timer? timer;
  UserAccelerometerEvent? event;

  var accelerationValues;
  var gyroscopeValues;
  var batteryState;
  String _connectionStateText = 'Not Connected';
  @override
  void initState() {
    var authenticationData = LocalStorageService.getAuthenticationFromMemory();

    Future.delayed(Duration.zero, () async {
      int receivedMessage =
          await websocket.connectWebSocket(authenticationData);
      if (websocket.successfullyRegistered) {
        startTransmissionInterval();
        setState(() {});
        websocket.streamController.stream.listen(
          (event) {
            var response = websocket.messageHandler(event);
          },
          onDone: () {
            websocket.isWebsocketRunning = false;
            print("Websocket Done");
            setState(() {});
          },
          onError: (err) {
            websocket.isWebsocketRunning = false;
            print("Websocket Error");
            setState(() {});
          },
        );
      }
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title:
              const Text("IMU_Tracker DEMO"), //TODO Change title before release
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              _getConnectionStateIcon(websocket.isWebsocketRunning &&
                  websocket.successfullyRegistered),
            ],
          ),
        ));
  }

  _getConnectionStateIcon(bool checkBoxState) {
    if (checkBoxState) {
      return const Icon(
        Icons.wifi,
        color: Colors.green,
        size: 80.0,
      );
    } else {
      return const Icon(
        Icons.wifi_off,
        color: Colors.red,
        size: 80.0,
      );
    }
  }

  startTransmissionInterval() {
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

    // Intervall for websocketconnection
    if (timer == null || !timer!.isActive) {
      timer = Timer.periodic(const Duration(milliseconds: 200), (_) {
        if (websocket.successfullyRegistered) {
          websocket.buildValueMessage(accelerationValues, gyroscopeValues, 5,
              batteryState); //TODO implement all necessary values
        }
      });
    }
  }
}
