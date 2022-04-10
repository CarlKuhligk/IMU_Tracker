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

class WebSocketHandler {
//Websocket Variables
  bool isWebsocketRunning = false; //status of a websocket
  ValueNotifier<bool> successfullyRegistered = ValueNotifier<bool>(false);
  var successfullyLoggedOut = false;
  late WebSocket _channel; //initialize a websocket channel
  Timer? timer;
  var _socketData;

  var deviceSettings = getIt<DeviceSettingsHandler>();

  connectWebSocket(socketData) async {
    int _webSocketResponseNumber = 0;
    _socketData = socketData;

    try {
      _channel = await WebSocket.connect('ws://${socketData['host']}');
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
      return _webSocketResponseNumber;
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
      _webSocket = await WebSocket.connect('ws://${socketData['host']}');
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

  void buildValueMessage(
      accelerationValue, gyroscopeValue, temperatureValue, batteryState) {
    var buildMessage = {
      "t": "m",
      "a": accelerationValue,
      "r": gyroscopeValue,
      "tp": temperatureValue,
      "b": batteryState
    };
    if (accelerationValue != null &&
        gyroscopeValue != null &&
        temperatureValue != null &&
        batteryState != null) {
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

  messageDecoderReturnType messageDecoder(message) {
    var decodedJSON;
    bool decodeSucceeded = false;
    try {
      decodedJSON = json.decode(message) as Map<String, dynamic>;
      decodeSucceeded = true;
    } on FormatException {
      return messageDecoderReturnType(false, 'w', 0);
    }

    if (decodeSucceeded && decodedJSON["t"] != null) {
      switch (decodedJSON["t"]) {
        case "r":
          return messageDecoderReturnType(
              true, 'r', int.parse(decodedJSON['i']));
        case "s":
          return messageDecoderReturnType(true, 's', int.parse(message));
        default:
          return messageDecoderReturnType(true, 'u', 0);
      }
    } else {
      return messageDecoderReturnType(false, 'w', 0);
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
          deviceSettings
              .writeNewDeviceSettingsToInternalStorage(decodedMessage);
          break;
        default:
        //TODO: Handle unknown response via errorhandler package
      }
    } else {
      //channel.close();
    }
  }

  _handleResponseMessages(message) {
    switch (message.webSocketResponseNumber) {
      case 8:
        successfullyLoggedOut = false;
        break;
      case 9:
        successfullyRegistered.value = false;
        successfullyLoggedOut = true;
        _channel.close();
        isWebsocketRunning = false;
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

  void dispose() {
    _channel.close();
  }

  _checkServerAvailable() {
    //TODO: Implement the argument socketData into ping
    Socket.connect("192.168.178.69", 8080, timeout: Duration(seconds: 5))
        .then((socket) {
      isWebsocketRunning = true;
      socket.destroy();
    }).catchError((error) {
      successfullyRegistered.value = false;
      isWebsocketRunning = false;
      _channel.close;
      connectWebSocket(_socketData);
    });
  }

  _startPingInterval() {
    // Intervall for websocketconnection available test
    if (timer == null || !timer!.isActive) {
      timer = Timer.periodic(const Duration(seconds: 10), (_) {
        _checkServerAvailable();
      });
    }
  }
}
