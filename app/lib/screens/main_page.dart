import 'package:IMU_Tracker/services/message_builder.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:sensors/sensors.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';

class MainPage extends StatefulWidget {
  const MainPage({
    Key? key,
  }) : super(key: key);
  @override
  _MyMainPageState createState() => _MyMainPageState();
}

class _MyMainPageState extends State<MainPage> {
  var accelerationValues = {'X': 0, 'Y': 0, 'Z': 0};
  var gyroscopeValues = {'X': 0, 'Y': 0, 'Z': 0};
  double accelerationX = 0, accelerationY = 0, accelerationZ = 0;
  double gyroscopeX = 0, gyroscopeY = 0, gyroscopeZ = 0;
  bool sucessfullyRegistered = false;
  String _connectionStateText = 'Not Connected';
  var _channel = WebSocketChannel.connect(Uri.parse('ws://192.168.0.20:8080'));
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
      if (sucessfullyRegistered) buildValueMessage();
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
          title: Text("IMU-Tracker DEMO"),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              new RaisedButton(
                onPressed: () => {registerAsSender()},
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
                stream: _channel.stream,
                builder: (context, snapshot) {
                  Future.delayed(Duration.zero, () async {
                    _messageHandler(snapshot.data);
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

  void _sendMessage(messageString) {
    if (messageString.isNotEmpty) {
      _channel.sink.add(jsonEncode(messageString));
      //print('sent message');
      //print(messageString);
    }
  }

  void registerAsSender() {
    _channel.sink.add(jsonEncode(loginMessage));
    print(loginMessage);
  }

  void sendGyroValues() {
    _channel.sink.add(jsonEncode(gyroMessage));
    print(gyroMessage);
    print(jsonEncode(gyroMessage));
  }

  void _messageHandler(message) {
    if (message != null) {
      var incomingMessage = jsonDecode(message);
      //print(message);
      if (incomingMessage['type'] == 'response' &&
          incomingMessage['id'] == '10') {
        //print("Successfully registered as Sender");
        sucessfullyRegistered = true;
        setState(() {
          _connectionStateText = 'Connected';
        });
      }
    }
  }

  void buildValueMessage() {
    var buildMessage = {
      "type": "data",
      "value": [
        accelerationX,
        accelerationY,
        accelerationZ,
        gyroscopeX,
        gyroscopeY,
        gyroscopeZ,
        "0",
        "0",
        "0"
      ],
      "apikey": apikey
    };
    _sendMessage(buildMessage);
  }

  void dispose() {
    _channel.sink.close();
    super.dispose();
  }
}
