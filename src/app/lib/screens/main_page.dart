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
import 'package:imu_tracker/services/notification_service.dart';

import 'package:flutter_background/flutter_background.dart';

class MainPage extends StatefulWidget {
  const MainPage({
    Key? key,
  }) : super(key: key);
  @override
  _MyMainPageState createState() => _MyMainPageState();
}

class _MyMainPageState extends State<MainPage> {
  var _websocket = getIt<WebSocketHandler>();
  var _internalSensors = getIt<InternalSensorService>();
  var _notificationService = getIt<NotificationService>();
  var _connectionWarningDialogOpen = false;
  var _movementWarningDialogOpen = false;
  var _batteryWarningDialogOpen = false;

  Timer? timer;
  TextEditingController _textFieldController = TextEditingController();
  late String _valueText;
  @override
  void initState() {
    var authenticationData = LocalStorageService.getAuthenticationFromMemory();

    Future.delayed(Duration.zero, () async {
      await _websocket.connectWebSocket(authenticationData);
      if (_websocket.successfullyRegistered.value) {
        _websocket.startTransmissionInterval();
      }
    });

    _websocket.successfullyRegistered.addListener(() {
      if (!_websocket.successfullyRegistered.value &&
          !_connectionWarningDialogOpen &&
          !_websocket.successfullyLoggedOut.value) {
        _showConnectionDialog();
      }
      setState(() {});
    });

    _websocket.logOutFailed.addListener(() {
      if (_websocket.logOutFailed.value) {
        _showLogOutDialog(context);
      }
    });
    _internalSensors.batteryAlarmstate.addListener(() {
      if (_internalSensors.movementAlarmstate.value &&
          !_batteryWarningDialogOpen) {
        _showBatteryDialog();
      }
      setState(() {});
    });
    _internalSensors.movementAlarmstate.addListener(() {
      print(_movementWarningDialogOpen);
      if (_internalSensors.movementAlarmstate.value &&
          !_movementWarningDialogOpen) {
        _showMovementDialog();
      }
      setState(() {});
    });

    if (_websocket.logOutFailed.value) {
      _showLogOutDialog(context);
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Color.fromARGB(255, 18, 18, 18),
        appBar: AppBar(
          title: const Text("Security-Motion-Tracker"),
          backgroundColor: Color.fromARGB(255, 30, 30, 30),
        ),
        body: Center(
          child: Column(
            children: <Widget>[
              Expanded(
                  flex: 10,
                  child: Column(
                    //mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: <Widget>[
                      Column(children: [
                        if (!_websocket.successfullyLoggedOut.value)
                          _getConnectionStateIcon(
                              _websocket.successfullyRegistered.value),
                        if (_websocket.successfullyRegistered.value)
                          Text(
                            'Erfolgreich verbunden!',
                            style:
                                TextStyle(fontSize: 20.0, color: Colors.green),
                          ),
                        if (!_websocket.successfullyRegistered.value &&
                            !_websocket.successfullyLoggedOut.value)
                          Text(
                            'Keine Verbindung zum Server!',
                            style: TextStyle(fontSize: 20.0, color: Colors.red),
                          ),
                      ]),
                      Table(
                        border: TableBorder.symmetric(),
                        columnWidths: const {
                          0: FractionColumnWidth(0.2),
                          1: FractionColumnWidth(0.8)
                        },
                        children: [
                          if (_internalSensors.movementAlarmstate.value)
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
                                  child: Text('Bewegungslosigkeit erkannt!',
                                      style: TextStyle(
                                          fontSize: 20.0, color: Colors.red)),
                                )
                              ],
                            ),
                          if (_internalSensors.batteryAlarmstate.value)
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
                                  child: Text('Batteriestand niedrig!',
                                      style: TextStyle(
                                          fontSize: 20.0, color: Colors.red)),
                                )
                              ],
                            ),
                        ],
                      ),
                    ],
                  )),
              if (_websocket.successfullyRegistered.value)
                Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: FlatButton(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                    shape: const StadiumBorder(),
                    color: Colors.teal,
                    textColor: Colors.white,
                    onPressed: () {
                      _showLogOutDialog(context);
                    },
                    child: const Text('Abmelden'),
                  ),
                ),
              if (_websocket.successfullyLoggedOut.value)
                Text('Erfolgreich abgemeldet!',
                    style: TextStyle(fontSize: 20.0, color: Colors.green)),
              if (_websocket.successfullyLoggedOut.value)
                Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: FlatButton(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                    shape: const StadiumBorder(),
                    color: Colors.teal,
                    textColor: Colors.white,
                    onPressed: () async {
                      SystemNavigator.pop();
                      await FlutterBackground.disableBackgroundExecution();
                      _notificationService.cancelAllNotifications();
                    },
                    child: const Text('App schließen'),
                  ),
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
        size: 130.0,
      );
    } else {
      return const Icon(
        Icons.wifi_off,
        color: Colors.red,
        size: 100.0,
      );
    }
  }

  Future<void> _showLogOutDialog(BuildContext context) async {
    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Abmeldung'),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  if (_websocket.logOutFailed.value)
                    Text('Abmeldung fehlgeschlagen, falsche Pin!'),
                  TextField(
                    onChanged: (value) {
                      setState(() {
                        _valueText = value;
                      });
                    },
                    controller: _textFieldController,
                    keyboardType: TextInputType.number,
                    decoration:
                        const InputDecoration(hintText: "Persönliche Pin"),
                  ),
                ],
              ),
            ),
            actions: <Widget>[
              FlatButton(
                color: Colors.red,
                textColor: Colors.white,
                child: const Text('Abbrechen'),
                onPressed: () {
                  setState(() {
                    Navigator.pop(context);
                  });
                },
              ),
              FlatButton(
                color: Colors.teal,
                textColor: Colors.white,
                child: const Text('Abmelden'),
                onPressed: () {
                  _websocket.logoutDevice(_valueText);
                  setState(() {
                    Navigator.pop(context);
                  });
                },
              ),
            ],
          );
        });
  }

  Future<void> _showBatteryDialog() async {
    _batteryWarningDialogOpen = true;
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Batteriestand niedrig!",
              style: TextStyle(fontSize: 20.0, color: Colors.red)),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text("Batteriestand niedrig!"),
              ],
            ),
          ),
          actions: <Widget>[
            FlatButton(
              color: Colors.teal,
              textColor: Colors.white,
              child: const Text('Wahrgenommen'),
              onPressed: () {
                _batteryWarningDialogOpen = false;
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showMovementDialog() async {
    _movementWarningDialogOpen = true;
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Bewegungslosigkeit erkannt!",
              style: TextStyle(fontSize: 20.0, color: Colors.red)),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text("Wenn Sie sich nicht bewegen, wird der Alarm ausgelöst"),
              ],
            ),
          ),
          actions: <Widget>[
            FlatButton(
              color: Colors.teal,
              textColor: Colors.white,
              child: const Text('Wahrgenommen'),
              onPressed: () {
                _movementWarningDialogOpen = false;
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showConnectionDialog() async {
    _connectionWarningDialogOpen = true;
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Verbindung zum Server verloren!",
              style: TextStyle(fontSize: 20.0, color: Colors.red)),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(
                    "Verbindung zum Server verloren, es werden keine Daten gesendet!"),
              ],
            ),
          ),
          actions: <Widget>[
            FlatButton(
              color: Colors.teal,
              textColor: Colors.white,
              child: const Text('Wahrgenommen'),
              onPressed: () {
                _connectionWarningDialogOpen = false;
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
