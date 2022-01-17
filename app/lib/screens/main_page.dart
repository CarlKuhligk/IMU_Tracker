//flutter packages
import 'package:flutter/material.dart';

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

  var accelerationValues;
  var gyroscopeValues;
  String _connectionStateText = 'Not Connected';
  @override
  void initState() {
    var authenticationData = LocalStorageService.getAuthenticationFromMemory();
    //var receivedMessage = websocket.connectWebSocket(authenticationData).then((value) => null)

    Future.delayed(Duration.zero, () async {
      int receivedMessage =
          await websocket.connectWebSocket(authenticationData);
      if (websocket.sucessfullyRegistered) {
        websocket.streamController.stream.listen(
          (event) {
            websocket.messageHandler(event);
          },
          onDone: () {
            websocket.isWebsocketRunning = false;
            setState(() {});
          },
        );
      }
    });

    super.initState();
    accelerometerEvents.listen((AccelerometerEvent event) {
      accelerationValues = event;
    });
    gyroscopeEvents.listen((GyroscopeEvent event) {
      gyroscopeValues = event;
      if (websocket.sucessfullyRegistered)
        websocket.buildValueMessage(
            accelerationValues, gyroscopeValues, 5); //To be implemented
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("IMU_Tracker DEMO"),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[],
          ),
        ));
  }
}
