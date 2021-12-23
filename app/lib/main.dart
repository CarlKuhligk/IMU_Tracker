import 'package:imu_tracker/screens/qr_code_registration_screen.dart';
import 'package:imu_tracker/services/localstorage_service.dart';
import 'screens/main_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'service_locator.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await setupLocator();
    runApp(MyApp());
  } catch (error) {
    print('Locator setup has failed');
  }
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
    bool _newLaunch = LocalStorageService.getDeviceIsRegistered();
    setState(() {
      if (_newLaunch == Null) {
        _newLaunch = false;
      }
      newLaunch = _newLaunch;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: newLaunch ? RegistrationScreen() : MainPage());
  }
}
