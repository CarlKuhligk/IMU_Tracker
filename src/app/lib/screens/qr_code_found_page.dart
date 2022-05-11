//flutter packages
// ignore_for_file: prefer_typing_uninitialized_variables, deprecated_member_use

import 'package:flutter/material.dart';

//project specific types
import 'package:imu_tracker/data_structures/function_return_types.dart';
import 'package:imu_tracker/data_structures/response_numbers.dart';

//screens
import 'package:imu_tracker/screens/main_page.dart';
import 'package:imu_tracker/screens/qr_code_registration_screen.dart';

class QrCodeFoundPage extends StatelessWidget {
  const QrCodeFoundPage({
    Key? key,
    required this.qrCheckResult,
    required this.webSocketTestResult,
  }) : super(key: key);
  final qrCheckResult;
  final WebSocketTestResultReturnType webSocketTestResult;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 18, 18, 18),
      appBar: AppBar(
        title: const Text('QR-Code gefunden'),
        backgroundColor: Color.fromARGB(255, 30, 30, 30),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            Table(
              border: TableBorder.symmetric(),
              columnWidths: const {
                0: FractionColumnWidth(0.2),
                1: FractionColumnWidth(0.8)
              },
              children: [
                TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: _getCheckBox(qrCheckResult),
                    ),
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text('QR - Code Format',
                          style:
                              TextStyle(fontSize: 20.0, color: Colors.white)),
                    )
                  ],
                ),
                if (qrCheckResult)
                  TableRow(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: _getCheckBox(
                            webSocketTestResult.isWebSocketConnected),
                      ),
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text('Verbindung zum Server',
                            style:
                                TextStyle(fontSize: 20.0, color: Colors.white)),
                      )
                    ],
                  ),
                if (webSocketTestResult.isWebSocketConnected)
                  TableRow(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: _getCheckBox(webSocketTestResult.isApiKeyValid),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                            '${_getWebsocketResponseString(webSocketTestResult.webSocketResponseNumber)}',
                            style: const TextStyle(
                                fontSize: 20.0, color: Colors.white)),
                      )
                    ],
                  ),
              ],
            ),
            if (webSocketTestResult.isApiKeyValid)
              FlatButton(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                shape: const StadiumBorder(),
                color: Colors.teal,
                textColor: Colors.white,
                onPressed: () => {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const MainPage()),
                    (Route<dynamic> route) => false,
                  )
                },
                child: const Text("App starten"),
              )
            else
              FlatButton(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                shape: const StadiumBorder(),
                color: Colors.teal,
                textColor: Colors.white,
                onPressed: () => {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const RegistrationScreen()),
                    (Route<dynamic> route) => false,
                  )
                },
                child: const Text("QR - Code erneut scannen"),
              ),
          ],
        ),
      ),
    );
  }

  _getCheckBox(bool checkBoxState) {
    if (checkBoxState) {
      return const Icon(
        Icons.check_box,
        color: Colors.green,
        size: 24.0,
      );
    } else {
      return const Icon(
        Icons.indeterminate_check_box,
        color: Colors.red,
        size: 24.0,
      );
    }
  }

  _getWebsocketResponseString(webSocketResponseTypeNumber) {
    try {
      var responseType = responseList.values.firstWhere(
          (element) => element.responseNumber == webSocketResponseTypeNumber);
      return responseType.responseString;
    } catch (e) {
      return "unknown response";
    }
  }
}
