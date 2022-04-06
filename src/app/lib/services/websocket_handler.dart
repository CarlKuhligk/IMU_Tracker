//dart packages
// ignore_for_file: prefer_typing_uninitialized_variables

import 'dart:convert';
import 'dart:async';
import 'dart:io';
//project specific types
import 'package:imu_tracker/data_structures/function_return_types.dart';
import 'package:imu_tracker/data_structures/response_numbers.dart';

class WebSocketHandler {
//Websocket Variables
  var successfullyRegistered = false;
  late WebSocket channel; //initialize a websocket channel
  final streamController = StreamController.broadcast();
  bool isWebsocketRunning = false; //status of a websocket
  int retryLimit = 3;
  var _apiKey;

  Future<int> connectWebSocket(socketData) async {
    int _webSocketMessageNumber = 0;

    var _registrationMessage = buildRegistrationMessage(socketData);
    _apiKey = socketData['apikey'];

    StreamSubscription? streamSubscription;

    try {
      channel = await WebSocket.connect('ws://${socketData['host']}');
      isWebsocketRunning = true;
      streamController.addStream(channel);
      channel.add(jsonEncode(_registrationMessage));

      streamSubscription = streamController.stream.listen(
        (message) {
          var handledMessage = messageHandler(message);
          if (handledMessage.hasMessageRightFormat &&
              handledMessage.webSocketResponseNumber ==
                  responseList['deviceRegistered']!.responseNumber) {
            isWebsocketRunning = true;
            successfullyRegistered = true;
          } else {
            //channel.close();
          }
          _webSocketMessageNumber = handledMessage.webSocketResponseNumber;
        },
        onError: (err) {
          isWebsocketRunning = false;
        },
      );
    } catch (e) {
      isWebsocketRunning = false;
      return _webSocketMessageNumber;
    }

    return await Future.delayed(const Duration(seconds: 1), () {
      if (streamSubscription != null) {
        streamSubscription.cancel();
      }
      return _webSocketMessageNumber;
    });
  }

  void sendMessage(messageString) {
    if (messageString.isNotEmpty) {
      channel.add(jsonEncode(messageString));
    }
  }

  void registerAsSender(socketData) {
    var _registrationMessage = buildRegistrationMessage(socketData);
    channel.add(jsonEncode(_registrationMessage));
    print(_registrationMessage);
  }

  MessageHandlerReturnType messageHandler(message) {
    var decodedJSON;
    bool decodeSucceeded = false;
    try {
      decodedJSON = json.decode(message) as Map<String, dynamic>;
      decodeSucceeded = true;
    } on FormatException {
      return MessageHandlerReturnType(false, 'w', 0);
    }

    if (decodeSucceeded && decodedJSON["t"] != null) {
      switch (decodedJSON["t"]) {
        case "r":
          return MessageHandlerReturnType(
              true, 'r', int.parse(decodedJSON['i']));
        case "s":
          return MessageHandlerReturnType(true, 's', int.parse(message));
        default:
          return MessageHandlerReturnType(true, 'u', 0);
      }
    } else {
      return MessageHandlerReturnType(false, 'w', 0);
    }
  }

  void buildValueMessage(
      accelerationValue, gyroscopeValue, temperatureValue, batteryState) {
    var buildMessage = {
      "t": "d",
      "a": accelerationValue,
      "r": gyroscopeValue,
      "tp": temperatureValue,
      "b": batteryState
    };
    sendMessage(buildMessage);
  }

  void dispose() {
    channel.close();
  }

  Future<WebSocketTestResultReturnType> testWebSocketConnection(
      socketData) async {
    bool _isWebsocketRunning = false;

    bool _isApiKeyValid = false;
    var _webSocketMessageNumber = 0;

    var _apiKeyTestMessage = buildApiKeyTestMessage(socketData);

    var _webSocket;

    try {
      _webSocket = await WebSocket.connect('ws://${socketData['host']}');
      _isWebsocketRunning = true;
      _webSocket.add(jsonEncode(_apiKeyTestMessage));

      _webSocket.listen(
        (message) {
          var handledMessage = messageHandler(message);
          if (handledMessage.hasMessageRightFormat &&
              handledMessage.webSocketResponseNumber ==
                  responseList['validApiKey']!.responseNumber) {
            _isApiKeyValid = true;
          }
          _webSocketMessageNumber = handledMessage.webSocketResponseNumber;
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
          _isWebsocketRunning, _isApiKeyValid, _webSocketMessageNumber);
    }

    return await Future.delayed(const Duration(milliseconds: 500), () {
      if (_webSocket != null) {
        _webSocket.close();
      }
      return WebSocketTestResultReturnType(
          _isWebsocketRunning, _isApiKeyValid, _webSocketMessageNumber);
    });
  }

  buildRegistrationMessage(socketData) {
    var _registrationMessage = {"t": "i", "a": ""};
    _registrationMessage['a'] = socketData['apikey'];

    return _registrationMessage;
  }

  buildApiKeyTestMessage(socketData) {
    var _apiKeyTestMessage = {"t": "i", "a": "", "c": true};
    _apiKeyTestMessage['a'] = socketData['apikey'];

    return _apiKeyTestMessage;
  }

  buildLogOutMessage(personalPin) {
    var _logOutMessage = {"t": "o"};
    _logOutMessage['p'] = personalPin;

    return _logOutMessage;
  }
}
