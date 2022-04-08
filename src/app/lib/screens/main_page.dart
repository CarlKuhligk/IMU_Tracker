//flutter packages
// ignore_for_file: prefer_typing_uninitialized_variables

import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:async';

//additional packages

//project internal services / dependency injection
import 'package:imu_tracker/service_locator.dart';
import 'package:imu_tracker/services/websocket_handler.dart';
import 'package:imu_tracker/services/localstorage_service.dart';
import 'package:imu_tracker/services/internal_sensor_service.dart';

class MainPage extends StatefulWidget {
  const MainPage({
    Key? key,
  }) : super(key: key);
  @override
  _MyMainPageState createState() => _MyMainPageState();
}

class _MyMainPageState extends State<MainPage> {
  var websocket = getIt<WebSocketHandler>();
  var internalSensors = getIt<InternalSensorService>();

  Timer? timer;
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
            var response = websocket.messageDecoder(event);
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
    // Intervall for websocketconnection
    internalSensors.startInternalSensors();
    if (timer == null || !timer!.isActive) {
      timer = Timer.periodic(const Duration(milliseconds: 200), (_) {
        if (websocket.successfullyRegistered) {
          websocket.buildValueMessage(
              internalSensors.magnitudeAccelerometer,
              internalSensors.magnitudeGyroscope,
              5,
              internalSensors
                  .batteryLevel); //TODO implement all necessary values
        }
      });
    }
  }
}
