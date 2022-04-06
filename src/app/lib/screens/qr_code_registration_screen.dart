//dart packages
// ignore_for_file: prefer_typing_uninitialized_variables

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
import 'package:imu_tracker/data_structures/function_return_types.dart';
import 'package:imu_tracker/data_structures/response_numbers.dart';

//screens
import 'package:imu_tracker/screens/qr_code_found_page.dart';

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
          Expanded(flex: 9, child: _buildQrView(context)),
          Expanded(
            flex: 1,
            child: FittedBox(
              fit: BoxFit.contain,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: const <Widget>[
                  Text('Bitte den QR-Code scannen'),
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
    var scanArea = (MediaQuery.of(context).size.width < 200 ||
            MediaQuery.of(context).size.height < 200)
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
        var qrCodeHasRightFormat = true;
        var socketData;
        socketData = scanData.code;
        var webSocketTestResult =
            await websocket.testWebSocketConnection(json.decode(socketData));
        if (webSocketTestResult.isWebSocketConnected) {
          if (webSocketTestResult.webSocketResponseType ==
              responseList['deviceRegistered']!.responseNumber) {
            LocalStorageService.writeAuthenticationToMemory(scanData.code);
            LocalStorageService.setDeviceIsRegistered(true);
          }
        }
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => QrCodeFoundPage(
                qrCheckResult: qrCodeHasRightFormat,
                webSocketTestResult: webSocketTestResult),
          ),
        );
      } else {
        var qrCodeHasRightFormat = false;
        var webSocketTestResult = WebSocketTestResultReturnType(false, 0);
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => QrCodeFoundPage(
                qrCheckResult: qrCodeHasRightFormat,
                webSocketTestResult: webSocketTestResult),
          ),
        );
      }
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
