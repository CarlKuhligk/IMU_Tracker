//flutter packages
import 'package:flutter/material.dart';

//project specific types
import 'package:imu_tracker/data_structures/response_types.dart';

//screens
import 'package:imu_tracker/screens/main_page.dart';
import 'package:imu_tracker/screens/qr_code_registration_screen.dart';

class QrCodeFoundPage extends StatefulWidget {
  const QrCodeFoundPage({Key? key}) : super(key: key);

  @override
  State<QrCodeFoundPage> createState() => _QrCodeFoundPageState();
}

class _QrCodeFoundPageState extends State<QrCodeFoundPage> {
  int _counter = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Found QR-Code'),
      ),
      body: Center(
        child: Column(
          // horizontal).
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'Korrektes QR-Code Fromat',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headline4,
            ),
          ],
        ),
      ),
    );
  }
}
