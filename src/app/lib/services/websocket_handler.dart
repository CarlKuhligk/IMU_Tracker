//dart packages
// ignore_for_file: prefer_typing_uninitialized_variables
import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:async';
import 'dart:io';
//project specific types
import 'package:imu_tracker/data_structures/function_return_types.dart';
import 'package:imu_tracker/data_structures/response_numbers.dart';
import 'package:crypto/crypto.dart';

//project internal services / dependency injection
import 'package:imu_tracker/service_locator.dart';
import 'package:imu_tracker/services/device_settings_handler.dart';
import 'package:imu_tracker/services/internal_sensor_service.dart';

class WebSocketHandler {
//Websocket Variables
  bool isWebsocketRunning = false; //status of a websocket
  ValueNotifier<bool> successfullyRegistered = ValueNotifier<bool>(false);
  ValueNotifier<bool> successfullyLoggedOut = ValueNotifier<bool>(false);
  late WebSocket _channel; //initialize a websocket channel
  Timer? _pingIntervalTimer;
  Timer? _transmitIntervalTimer;
  var _socketData;

  var deviceSettings = getIt<DeviceSettingsHandler>();

  var internalSensors = getIt<InternalSensorService>();

  connectWebSocket(socketData) async {
    _socketData = socketData;

    try {
      _channel = await WebSocket.connect(
          'ws://${socketData['host']}:${socketData['port']}');
      isWebsocketRunning = true;
      registerAsSender(socketData);
      _channel.listen(
        (message) {
          _messageHandler(message);
        },
        onDone: () {
          isWebsocketRunning = false;
          //TODO: Errorhandling via errorhandlingpackage
        },
        onError: (err) {
          isWebsocketRunning = false;
          //TODO: Errorhandling via errorhandlingpackage
        },
      );
    } catch (e) {
      isWebsocketRunning = false;
      //TODO: Errorhandling via errorhandlingpackage
    }

    return await Future.delayed(const Duration(seconds: 1), () {});
  }

  Future<WebSocketTestResultReturnType> testWebSocketConnection(
      socketData) async {
    bool _isWebsocketRunning = false;

    bool _isApiKeyValid = false;

    var _webSocketResponseNumber = 0;

    var _apiKeyTestMessage = buildApiKeyTestMessage(socketData);

    var _webSocket;

    try {
      _webSocket = await WebSocket.connect(
          'ws://${socketData['host']}:${socketData['port']}');
      _isWebsocketRunning = true;
      _webSocket.add(jsonEncode(_apiKeyTestMessage));

      _webSocket.listen(
        (message) {
          var decodedMessage = messageDecoder(message);

          if (_isWebSocketMessageValidApiKeyMessage(decodedMessage)) {
            _isApiKeyValid = true;
          }
          _webSocketResponseNumber = decodedMessage.webSocketResponseNumber;
        },
        onError: (err) {
          _isWebsocketRunning = false;
          if (_webSocket != null) {
            _webSocket.close();
          }
        },
      );
    } catch (e) {
      _isWebsocketRunning = false;
      _isApiKeyValid = false;
      return WebSocketTestResultReturnType(
          _isWebsocketRunning, _isApiKeyValid, _webSocketResponseNumber);
    }

    return await Future.delayed(const Duration(milliseconds: 500), () {
      if (_webSocket != null) {
        _webSocket.close();
      }
      return WebSocketTestResultReturnType(
          _isWebsocketRunning, _isApiKeyValid, _webSocketResponseNumber);
    });
  }

  void buildValueMessage() {
    var buildMessage = {
      "t": "m",
      "a": internalSensors.magnitudeAccelerometer,
      "r": internalSensors.magnitudeGyroscope,
      "tp": internalSensors.deviceTemperature,
      "b": internalSensors.batteryLevel
    };
    if (internalSensors.magnitudeAccelerometer != null &&
        internalSensors.magnitudeGyroscope != null &&
        internalSensors.deviceTemperature != null &&
        internalSensors.batteryLevel != null) {
      sendMessage(buildMessage);
    }
  }

  buildRegistrationMessage(socketData) {
    var _registrationMessage = {"t": "i", "a": "", "c": 0};
    _registrationMessage['a'] = socketData['apikey'];

    return _registrationMessage;
  }

  buildApiKeyTestMessage(socketData) {
    var _apiKeyTestMessage = {"t": "i", "a": "", "c": 1};
    _apiKeyTestMessage['a'] = socketData['apikey'];

    return _apiKeyTestMessage;
  }

  buildLogOutMessage(personalPin) {
    var _logOutMessage = {"t": "o"};
    var bytes = utf8.encode(personalPin);
    var hashedPin = sha256.convert(bytes);
    _logOutMessage['p'] = hashedPin.toString();
    sendMessage(_logOutMessage);
  }

  void sendMessage(messageString) {
    if (messageString.isNotEmpty) {
      _channel.add(jsonEncode(messageString));
    }
  }

  void registerAsSender(socketData) {
    var _registrationMessage = buildRegistrationMessage(socketData);
    _channel.add(jsonEncode(_registrationMessage));
  }

  MessageDecoderReturnType messageDecoder(message) {
    var decodedJSON;
    bool decodeSucceeded = false;
    try {
      decodedJSON = json.decode(message) as Map<String, dynamic>;
      decodeSucceeded = true;
    } on FormatException {
      return MessageDecoderReturnType(false, 'w', 0);
    }

    if (decodeSucceeded && decodedJSON["t"] != null) {
      switch (decodedJSON["t"]) {
        case "r":
          return MessageDecoderReturnType(true, 'r', decodedJSON['i']);
        case "s":
          return MessageDecoderReturnType(true, 's', decodedJSON);
        default:
          return MessageDecoderReturnType(true, 'u', 0);
      }
    } else {
      return MessageDecoderReturnType(false, 'w', 0);
    }
  }

  _messageHandler(message) {
    var decodedMessage = messageDecoder(message);

    if (decodedMessage.hasMessageRightFormat) {
      switch (decodedMessage.webSocketResponseType) {
        case 'r':
          _handleResponseMessages(decodedMessage);
          break;
        case 's':
          deviceSettings.writeNewDeviceSettingsToInternalStorage(
              decodedMessage.webSocketResponseNumber);
          _transmitIntervalTimer?.cancel();

          startTransmissionInterval();
          break;
        default:
          break; //TODO: Handle unknown response via errorhandler package
      }
    } else {
      //channel.close();
    }
  }

  _handleResponseMessages(message) {
    switch (message.webSocketResponseNumber) {
      case 8:
        successfullyLoggedOut.value = false;
        break;
      case 9:
        _closeWebsocketConnection();
        break;
      case 10:
        successfullyRegistered.value = true;
        _startPingInterval();
        break;
      case 24:
        successfullyRegistered.value = false;
        break;
      default:
        try {
          var responseType = responseList.values.firstWhere((element) =>
              element.responseNumber == message.webSocketResponseNumber);
          return responseType.responseString;
        } catch (e) {
          return "unknown response";
        }
    }
  }

  _isWebSocketMessageValidApiKeyMessage(message) {
    if (message.hasMessageRightFormat &&
        message.webSocketResponseNumber ==
            responseList['validApiKey']!.responseNumber) {
      return true;
    } else {
      return false;
    }
  }

  void _closeWebsocketConnection() {
    successfullyRegistered.value = false;
    successfullyLoggedOut.value = true;
    _channel.close();
    _pingIntervalTimer?.cancel();
    isWebsocketRunning = false;
  }

  _checkServerAvailable() {
    //TODO: Implement the argument socketData into ping
    Socket.connect(_socketData['host'], _socketData['port'],
            timeout: const Duration(seconds: 5))
        .then((socket) {
      isWebsocketRunning = true;
      socket.destroy();
    }).catchError((error) {
      successfullyRegistered.value = false;
      isWebsocketRunning = false;
      _channel.close;
      if (!successfullyLoggedOut.value) connectWebSocket(_socketData);
    });
  }

  _startPingInterval() {
    // Intervall for websocketconnection available test
    if (_pingIntervalTimer == null || !_pingIntervalTimer!.isActive) {
      _pingIntervalTimer = Timer.periodic(const Duration(seconds: 10), (_) {
        _checkServerAvailable();
      });
    }
  }

  startTransmissionInterval() {
    // Intervall for websocketconnection
    internalSensors.startInternalSensors();
    if (_transmitIntervalTimer == null || !_transmitIntervalTimer!.isActive) {
      _transmitIntervalTimer = Timer.periodic(
          Duration(
              milliseconds: (int.parse(deviceSettings.deviceSettings["m"]))),
          (_) {
        if (successfullyRegistered.value) {
          buildValueMessage();
          internalSensors.getCurrentValues();
        }
      });
    }
  }
}
