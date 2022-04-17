//flutter packages
// ignore_for_file: prefer_typing_uninitialized_variables, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';

//project internal services / dependency injection
import 'package:imu_tracker/service_locator.dart';
import 'package:imu_tracker/services/websocket_handler.dart';
import 'package:imu_tracker/services/localstorage_service.dart';
import 'package:imu_tracker/services/internal_sensor_service.dart';
import 'package:imu_tracker/services/device_settings_handler.dart';
import 'package:imu_tracker/services/notification_service.dart';

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
  var deviceSettings = getIt<DeviceSettingsHandler>();
  var _notificationService = getIt<NotificationService>();

  Timer? timer;
  TextEditingController _textFieldController = TextEditingController();
  late String codeDialog;
  late String valueText;
  String _connectionStateText = 'Not Connected';
  @override
  void initState() {
    var authenticationData = LocalStorageService.getAuthenticationFromMemory();

    Future.delayed(Duration.zero, () async {
      await websocket.connectWebSocket(authenticationData);
      if (websocket.successfullyRegistered.value) {
        websocket.startTransmissionInterval();
      }
    });

    websocket.successfullyRegistered.addListener(() {
      setState(() {});
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("IMU_Tracker"),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              if (!websocket.successfullyLoggedOut.value)
                _getConnectionStateIcon(websocket.successfullyRegistered.value),
              if (websocket.successfullyRegistered.value)
                FlatButton(
                  color: Colors.teal,
                  textColor: Colors.white,
                  onPressed: () {
                    _displayTextInputDialog(context);
                  },
                  child: const Text('Logout'),
                ),
              if (websocket.successfullyLoggedOut.value)
                FlatButton(
                  color: Colors.teal,
                  textColor: Colors.white,
                  onPressed: () {
                    SystemNavigator.pop();
                  },
                  child: const Text('Close App'),
                ),
              FlatButton(
                color: Colors.green,
                textColor: Colors.white,
                child: const Text('Show notification'),
                onPressed: () async {
                  await _notificationService.showNotifications();
                },
              ),
              FlatButton(
                color: Colors.green,
                textColor: Colors.white,
                child: const Text('Cancel notification'),
                onPressed: () async {
                  await _notificationService.cancelNotifications();
                },
              )
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

  Future<void> _displayTextInputDialog(BuildContext context) async {
    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('LogOut'),
            content: TextField(
              onChanged: (value) {
                setState(() {
                  valueText = value;
                });
              },
              controller: _textFieldController,
              decoration: const InputDecoration(hintText: "LogOut Pin"),
            ),
            actions: <Widget>[
              FlatButton(
                color: Colors.red,
                textColor: Colors.white,
                child: const Text('Cancel'),
                onPressed: () {
                  setState(() {
                    Navigator.pop(context);
                  });
                },
              ),
              FlatButton(
                color: Colors.green,
                textColor: Colors.white,
                child: const Text('Logout'),
                onPressed: () {
                  websocket.buildLogOutMessage(valueText);
                  setState(() {
                    codeDialog = valueText;
                    Navigator.pop(context);
                  });
                },
              ),
            ],
          );
        });
  }
}
