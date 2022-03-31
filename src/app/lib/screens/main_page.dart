//flutter packages
import 'package:flutter/material.dart';

//additional packages
import 'package:sensors/sensors.dart';

//project internal services / dependency injection
import 'package:imu_tracker/service_locator.dart';
import 'package:imu_tracker/services/websocket_handler.dart';

class MainPage extends StatefulWidget {
  const MainPage({
    Key? key,
  }) : super(key: key);
  @override
  _MyMainPageState createState() => _MyMainPageState();
}

class _MyMainPageState extends State<MainPage> {
  var websocket = getIt<WebSocketHandler>();
  var accelerationValues = {'X': 0, 'Y': 0, 'Z': 0};
  var gyroscopeValues = {'X': 0, 'Y': 0, 'Z': 0};
  double accelerationX = 0, accelerationY = 0, accelerationZ = 0;
  double gyroscopeX = 0, gyroscopeY = 0, gyroscopeZ = 0;
  String _connectionStateText = 'Not Connected';
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    accelerometerEvents.listen((AccelerometerEvent event) {
      setState(() {
        accelerationX = event.x;
        accelerationY = event.y;
        accelerationZ = event.z;
      });
    });
    gyroscopeEvents.listen((GyroscopeEvent event) {
      if (websocket.sucessfullyRegistered) websocket.buildValueMessage();
      setState(() {
        gyroscopeX = event.x;
        gyroscopeY = event.y;
        gyroscopeZ = event.z;
      });
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
            children: <Widget>[
              new RaisedButton(
                onPressed: () => {websocket.registerAsSender()},
                child: new Text("Connect"),
              ),
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: Text(
                  _connectionStateText,
                  style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.w900),
                ),
              ),
              const SizedBox(height: 24),
              StreamBuilder(
                stream: WebSocketService.channel.stream,
                builder: (context, snapshot) {
                  Future.delayed(Duration.zero, () async {
                    websocket.messageHandler(snapshot.data);
                    if (websocket.sucessfullyRegistered) {
                      setState(() {
                        _connectionStateText = 'Connected';
                      });
                    }
                  });

                  return Text(snapshot.hasData ? '${snapshot.data}' : '');
                },
              ),
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: Text(
                  "Current Accelerometervalues:",
                  style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.w900),
                ),
              ),
              Table(
                border: TableBorder.all(
                    width: 2.0,
                    color: Colors.blueAccent,
                    style: BorderStyle.solid),
                children: [
                  TableRow(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          "X Asis : ",
                          style: TextStyle(fontSize: 20.0),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                            accelerationX.toStringAsFixed(
                                2), //trim the asis value to 2 digit after decimal point
                            style: TextStyle(fontSize: 20.0)),
                      )
                    ],
                  ),
                  TableRow(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          "Y Asis : ",
                          style: TextStyle(fontSize: 20.0),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                            accelerationY.toStringAsFixed(
                                2), //trim the asis value to 2 digit after decimal point
                            style: TextStyle(fontSize: 20.0)),
                      )
                    ],
                  ),
                  TableRow(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          "Z Asis : ",
                          style: TextStyle(fontSize: 20.0),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                            accelerationZ.toStringAsFixed(
                                2), //trim the asis value to 2 digit after decimal point
                            style: TextStyle(fontSize: 20.0)),
                      )
                    ],
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: Text(
                  "Current Gyroscopevalues:",
                  style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.w900),
                ),
              ),
              Table(
                border: TableBorder.all(
                    width: 2.0,
                    color: Colors.blueAccent,
                    style: BorderStyle.solid),
                children: [
                  TableRow(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          "X Asis : ",
                          style: TextStyle(fontSize: 20.0),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                            gyroscopeX.toStringAsFixed(
                                2), //trim the asis value to 2 digit after decimal point
                            style: TextStyle(fontSize: 20.0)),
                      )
                    ],
                  ),
                  TableRow(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          "Y Asis : ",
                          style: TextStyle(fontSize: 20.0),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                            gyroscopeY.toStringAsFixed(
                                2), //trim the asis value to 2 digit after decimal point
                            style: TextStyle(fontSize: 20.0)),
                      )
                    ],
                  ),
                  TableRow(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          "Z Asis : ",
                          style: TextStyle(fontSize: 20.0),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                            gyroscopeZ.toStringAsFixed(
                                2), //trim the asis value to 2 digit after decimal point
                            style: TextStyle(fontSize: 20.0)),
                      )
                    ],
                  ),
                ],
              ),
            ],
          ),
        ));
  }
}
