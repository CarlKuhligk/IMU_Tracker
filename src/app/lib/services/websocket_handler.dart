//dart packages
// ignore_for_file: prefer_typing_uninitialized_variables

import 'dart:convert';
import 'dart:async';
import 'dart:io';
//project specific types
import 'package:imu_tracker/data_structures/function_return_types.dart';
import 'package:imu_tracker/data_structures/response_types.dart';

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
              handledMessage.webSocketResponseType ==
                  responseList['deviceRegistered']!.responseNumber) {
            isWebsocketRunning = true;
            successfullyRegistered = true;
          } else {
            //channel.close();
          }
          _webSocketMessageNumber = handledMessage.webSocketResponseType;
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
      print('The provided string is not valid JSON');
      return MessageHandlerReturnType(false, 0);
    }

    if (decodeSucceeded &&
        decodedJSON["type"] != null &&
        decodedJSON["id"] != null) {
      print("Right message format");
      return MessageHandlerReturnType(true, int.parse(decodedJSON['id']));
    } else {
      return MessageHandlerReturnType(false, 0);
    }
  }

  void buildValueMessage(accelerationValues, gyroscopeValues, batteryState) {
    var buildMessage = {
      "type": "data",
      "value": [
        accelerationValues.x,
        accelerationValues.y,
        accelerationValues.z,
        gyroscopeValues.x,
        gyroscopeValues.y,
        gyroscopeValues.z,
        "0",
        batteryState,
      ],
      "apikey": _apiKey
    };
    sendMessage(buildMessage);
  }

  void dispose() {
    channel.close();
  }

  Future<WebSocketTestResultReturnType> testWebSocketConnection(
      socketData) async {
    bool _isWebsocketRunning = false;

    var _webSocketMessageNumber = 0;

    var _registrationMessage = buildRegistrationMessage(socketData);

    try {
      var _webSocket = await WebSocket.connect('ws://${socketData['host']}');
      _isWebsocketRunning = true;
      _webSocket.add(jsonEncode(_registrationMessage));

      _webSocket.listen(
        (message) {
          var handledMessage = messageHandler(message);
          if (handledMessage.hasMessageRightFormat &&
              handledMessage.webSocketResponseType ==
                  responseList['deviceRegistered']!.responseNumber) {
            _isWebsocketRunning = true;
            _webSocket.close();
          } else {
            _webSocket.close();
          }
          _webSocketMessageNumber = handledMessage.webSocketResponseType;
        },
        onError: (err) {
          _isWebsocketRunning = false;
        },
      );
    } catch (e) {
      _isWebsocketRunning = false;
      return WebSocketTestResultReturnType(
          _isWebsocketRunning, _webSocketMessageNumber);
    }

    return await Future.delayed(const Duration(milliseconds: 500), () {
      return WebSocketTestResultReturnType(
          _isWebsocketRunning, _webSocketMessageNumber);
    });
  }

  buildRegistrationMessage(socketData) {
    var _registrationMessage = {"type": "login", "apikey": ""};
    _registrationMessage['apikey'] = socketData['apikey'];

    return _registrationMessage;
  }
}