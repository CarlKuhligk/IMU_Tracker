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

  // In order to get hot reload to work we need to pause the camera if the platform is android
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
    // check how width or tall the device is and change the scanArea and overlay accordingly.
    var scanArea = (MediaQuery.of(context).size.width < 200 ||
            MediaQuery.of(context).size.height < 200)
        ? 150.0
        : 300.0;
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

    var _websocket = getIt<WebSocketHandler>();
    controller.scannedDataStream.listen((scanData) async {
      controller.pauseCamera();
      if (checkQrCode(describeEnum(scanData.format), scanData.code)) {
        var _qrCodeHasRightFormat = true;
        var _socketData;
        _socketData = scanData.code;
        var _webSocketTestResult =
            await _websocket.testWebSocketConnection(json.decode(_socketData));
        if (_webSocketTestResult.isWebSocketConnected &
            _webSocketTestResult.isApiKeyValid) {
          LocalStorageService.writeAuthenticationToMemory(scanData.code);
          LocalStorageService.setDeviceIsRegistered(true);
        }

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => QrCodeFoundPage(
                qrCheckResult: _qrCodeHasRightFormat,
                webSocketTestResult: _webSocketTestResult),
          ),
          (Route<dynamic> route) => false,
        );
      } else {
        var _qrCodeHasRightFormat = false;
        var _webSocketTestResult =
            WebSocketTestResultReturnType(false, false, 0);
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => QrCodeFoundPage(
                qrCheckResult: _qrCodeHasRightFormat,
                webSocketTestResult: _webSocketTestResult),
          ),
          (Route<dynamic> route) => false,
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
