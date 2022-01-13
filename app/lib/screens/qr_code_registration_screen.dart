//dart packages
import 'dart:developer';
import 'dart:io';
import 'dart:convert';

//flutter packages
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

//additional packages
import 'package:qr_code_scanner/qr_code_scanner.dart';

//project internal services / dependency injection
import 'package:imu_tracker/service_locator.dart';
import 'package:imu_tracker/services/login_data_handling.dart';
import 'package:imu_tracker/services/websocket_handler.dart';
import 'package:imu_tracker/services/localstorage_service.dart';

//project specific types
import 'package:imu_tracker/data_structures/response_types.dart';

//screens
import 'package:imu_tracker/screens/qr_code_found_page.dart';
import 'package:imu_tracker/screens/qr_code_wrong_format.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _RegistrationScreen();
}

class _RegistrationScreen extends State<RegistrationScreen> {
  Barcode? result;
  QRViewController? controller;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');

  // In order to get hot reload to work we need to pause the camera if the platform
  // is android, or resume the camera if the platform is iOS.
  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller!.pauseCamera();
    }
    controller!.resumeCamera();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[
          Expanded(flex: 4, child: _buildQrView(context)),
          Expanded(
            flex: 1,
            child: FittedBox(
              fit: BoxFit.contain,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  if (result != null)
                    Text(
                        'Barcode Type: ${describeEnum(result!.format)}   Data: ${result!.code}')
                  else
                    const Text('Scan a code'),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildQrView(BuildContext context) {
    // For this example we check how width or tall the device is and change the scanArea and overlay accordingly.
    var scanArea = (MediaQuery.of(context).size.width < 400 ||
            MediaQuery.of(context).size.height < 400)
        ? 150.0
        : 300.0;
    // To ensure the Scanner view is properly sizes after rotation
    // we need to listen for Flutter SizeChanged notification and update controller
    return QRView(
      key: qrKey,
      onQRViewCreated: _onQRViewCreated,
      overlay: QrScannerOverlayShape(
          borderColor: Colors.red,
          borderRadius: 10,
          borderLength: 30,
          borderWidth: 10,
          cutOutSize: scanArea),
      onPermissionSet: (ctrl, p) => _onPermissionSet(context, ctrl, p),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    setState(() {
      this.controller = controller;
    });

    var websocket = getIt<WebSocketHandler>();
    controller.scannedDataStream.listen((scanData) async {
      controller.pauseCamera();
      if (checkQrCode(describeEnum(scanData.format), scanData.code)) {
        var socketData;
        socketData = scanData.code;
        var webSocketTestResult =
            await websocket.testWebSocketConnection(json.decode(socketData));
        if (webSocketTestResult.isWebSocketConnected) {
          if (webSocketTestResult.webSocketResponseType ==
              responseList['deviceRegistered']!.responseNumber) {
            LocalStorageService.writeAuthenticationToMemory(scanData.code);
            LocalStorageService.setDeviceIsRegistered(true);
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => QrCodeFoundPage(
                    // Pass in the recognised item to the Order Page,
                    ),
              ),
            );
          } else {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => QrCodeFoundPage(
                    // Pass in the recognised item to the Order Page,
                    ),
              ),
            );
          }
        }
      } else {
        print("Wrong Data Format");
        //Implement Pushroute/Overlay for the wrong data format
      }

      controller.resumeCamera();
      setState(() {
        result = scanData;
      });
    });
  }

  void _onPermissionSet(BuildContext context, QRViewController ctrl, bool p) {
    log('${DateTime.now().toIso8601String()}_onPermissionSet $p');
    if (!p) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('no Permission')),
      );
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}
