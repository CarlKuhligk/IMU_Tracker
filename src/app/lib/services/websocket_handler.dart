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
import 'package:imu_tracker/services/notification_service.dart';

class WebSocketHandler {
//Websocket Variables
  bool isWebsocketRunning = false; //status of a websocket
  ValueNotifier<bool> successfullyRegistered = ValueNotifier<bool>(false);
  ValueNotifier<bool> successfullyLoggedOut = ValueNotifier<bool>(false);
  ValueNotifier<bool> logOutFailed = ValueNotifier<bool>(false);
  late WebSocket _channel; //initialize a websocket channel
  Timer? _pingIntervalTimer;
  Timer? _transmitIntervalTimer;
  var _socketData;

  var _deviceSettings = getIt<DeviceSettingsHandler>();

  var _internalSensors = getIt<InternalSensorService>();

  var _notificationService = getIt<NotificationService>();

  connectWebSocket(socketData) async {
    _socketData = socketData;

    try {
      _channel = await WebSocket.connect(
          'ws://${socketData['host']}:${socketData['port']}');
      isWebsocketRunning = true;
      _notificationService.cancelLostConnectionNotification();
      registerAsSender(socketData);
      _channel.listen(
        (message) {
          _messageHandler(message);
        },
        onDone: () {
          isWebsocketRunning = false;
        },
        onError: (err) {
          isWebsocketRunning = false;
        },
      );
    } catch (e) {
      isWebsocketRunning = false;
    }

    return await Future.delayed(const Duration(seconds: 1), () {});
  }

  Future<WebSocketTestResultReturnType> testWebSocketConnection(
      socketData) async {
    bool _isWebsocketRunning = false;

    bool _isApiKeyValid = false;

    var _webSocketResponseNumber = 0;

    var _apiKeyTestMessage = _buildApiKeyTestMessage(socketData);

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
      "a": _internalSensors.magnitudeAccelerometer,
      "r": _internalSensors.magnitudeGyroscope,
      "tp": _internalSensors.deviceTemperature,
      "b": _internalSensors.batteryLevel
    };
    if (_internalSensors.magnitudeAccelerometer != null &&
        _internalSensors.magnitudeGyroscope != null &&
        _internalSensors.deviceTemperature != null &&
        _internalSensors.batteryLevel != null) {
      _sendMessage(buildMessage);
    }
  }

  _buildRegistrationMessage(socketData) {
    //builds registration message for the websocket connection
    var _registrationMessage = {"t": "i", "a": "", "c": 0};
    _registrationMessage['a'] = socketData['apikey'];

    return _registrationMessage;
  }

  _buildApiKeyTestMessage(socketData) {
    //builds the test Message for api key testing
    var _apiKeyTestMessage = {"t": "i", "a": "", "c": 1};
    _apiKeyTestMessage['a'] = socketData['apikey'];

    return _apiKeyTestMessage;
  }

  _buildLogOutMessage(personalPin) {
    var _logOutMessage = {"t": "o"};
    var bytes = utf8.encode(personalPin);
    var hashedPin = sha256.convert(bytes);
    _logOutMessage['p'] = hashedPin.toString();
    return _logOutMessage;
  }

  logoutDevice(personalPin) {
    var _logOutMessage = _buildLogOutMessage(personalPin);
    _sendMessage(_logOutMessage);
  }

  void _sendMessage(messageString) {
    if (messageString.isNotEmpty) {
      _channel.add(jsonEncode(messageString));
    }
  }

  void registerAsSender(socketData) {
    //sends the registration message via websocket connection
    var _registrationMessage = _buildRegistrationMessage(socketData);
    _channel.add(jsonEncode(_registrationMessage));
  }

  MessageDecoderReturnType messageDecoder(message) {
    //checks incoming websocket messages for right format and returns the decoded json string
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
    //handles all incoming websocket messages with right message format
    var decodedMessage = messageDecoder(message);

    if (decodedMessage.hasMessageRightFormat) {
      switch (decodedMessage.webSocketResponseType) {
        case 'r':
          _handleResponseMessages(decodedMessage);
          break;
        case 's':
          _deviceSettings.writeNewDeviceSettingsToInternalStorage(
              decodedMessage.webSocketResponseNumber);
          _transmitIntervalTimer?.cancel();

          startTransmissionInterval();
          break;
        default:
          break;
      }
    } else {
      //channel.close();
    }
  }

  _handleResponseMessages(message) {
    //handles websocket messages of type response
    switch (message.webSocketResponseNumber) {
      case 8:
        successfullyLoggedOut.value = false;
        logOutFailed.value = true;
        break;
      case 9:
        logOutFailed.value = false;
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
    //Checks, if the received responsenumber equals the responsenumber for a valid api key
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
    //Ping to check, if the websocket server is still available
    Socket.connect(_socketData['host'], int.parse(_socketData['port']),
            timeout: const Duration(seconds: 5))
        .then((socket) {
      isWebsocketRunning = true;
      socket.destroy();
    }).catchError((error) {
      successfullyRegistered.value = false;
      isWebsocketRunning = false;
      _channel.close;
      _notificationService.showLostConnectionNotification();
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
    _internalSensors.startInternalSensors();
    if (_transmitIntervalTimer == null || !_transmitIntervalTimer!.isActive) {
      _transmitIntervalTimer = Timer.periodic(
          Duration(milliseconds: (_deviceSettings.deviceSettings["m"])), (_) {
        if (successfullyRegistered.value) {
          buildValueMessage();
          _internalSensors.getCurrentValues();
        }
      });
    }
  }
}
