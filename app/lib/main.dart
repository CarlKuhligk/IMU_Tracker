import 'package:imu_tracker/screens/qr_code_registration_screen.dart';
import 'package:imu_tracker/services/websocket_handler.dart';
import 'screens/main_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:sensors/sensors.dart';

void main() {
  runApp(MyApp());
  /*accelerometerEvents.listen((AccelerometerEvent event) {
    setState(() {
      accelerationX = event.x;
      accelerationY = event.y;
      accelerationZ = event.z;
    });
  });*/
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'IMU_Tracker',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: LoadPage() //MyHomePage(title: 'SharedPreferences Demo'),
        );
  }
}

class LoadPage extends StatefulWidget {
  //LoadPage({Key key}) : super(key: key);

  @override
  LoadPageState createState() => LoadPageState();
}

class LoadPageState extends State {
  bool newLaunch = false;

  @override
  void initState() {
    super.initState();
    loadNewLaunch();
  }

  loadNewLaunch() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      bool _newLaunch = ((prefs.getBool('newLaunch') ?? true));
      if (_newLaunch == Null) {
        _newLaunch = false;
      }
      newLaunch = _newLaunch;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: newLaunch ? MainPage() : MainPage());
  }
}
