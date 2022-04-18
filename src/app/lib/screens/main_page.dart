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
  var connectionWarningDialogOpen = false;
  var movementWarningDialogOpen = false;
  var batteryWarningDialogOpen = false;

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
      if (!websocket.successfullyRegistered.value &&
          !connectionWarningDialogOpen) {
        _showConnectionDialog();
      }
      setState(() {});
    });
    internalSensors.batteryAlarmstate.addListener(() {
      if (internalSensors.movementAlarmstate.value &&
          !batteryWarningDialogOpen) {
        _showBatteryDialog();
      }
      setState(() {});
    });
    internalSensors.movementAlarmstate.addListener(() {
      print(movementWarningDialogOpen);
      if (internalSensors.movementAlarmstate.value &&
          !movementWarningDialogOpen) {
        _showMovementDialog();
      }
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
            //mainAxisAlignment: MainAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              if (!websocket.successfullyLoggedOut.value)
                _getConnectionStateIcon(websocket.successfullyRegistered.value),
              Table(
                border: TableBorder.symmetric(),
                columnWidths: const {
                  0: FractionColumnWidth(0.2),
                  1: FractionColumnWidth(0.8)
                },
                children: [
                  if (internalSensors.movementAlarmstate.value)
                    TableRow(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: const Icon(
                            Icons.report_problem,
                            color: Colors.red,
                            size: 24.0,
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text('Movement Alarm!',
                              style: TextStyle(fontSize: 20.0)),
                        )
                      ],
                    ),
                  if (internalSensors.batteryAlarmstate.value)
                    TableRow(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: const Icon(
                            Icons.battery_alert,
                            color: Colors.red,
                            size: 24.0,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text('Battery Alarm!',
                              style: TextStyle(fontSize: 20.0)),
                        )
                      ],
                    ),
                ],
              ),
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

  Future<void> _showBatteryDialog() async {
    batteryWarningDialogOpen = true;
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Batterylevel too low!"),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text("Batterylevel too low!"),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Acknowledge'),
              onPressed: () {
                batteryWarningDialogOpen = false;
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showMovementDialog() async {
    movementWarningDialogOpen = true;
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Alarm for no movement"),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(
                    "You need to move, otherwise the alarm for no movement will be triggered"),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Acknowledge'),
              onPressed: () {
                movementWarningDialogOpen = false;
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showConnectionDialog() async {
    connectionWarningDialogOpen = true;
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Lost Connection to Server!"),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text("Lost Connection to Server, no Data is sent"),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Acknowledge'),
              onPressed: () {
                connectionWarningDialogOpen = false;
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}

class PrimitiveWrapper {
  var value;
  PrimitiveWrapper(this.value);
}
