import 'dart:convert';
import 'package:imu_tracker/services/localstorage_service.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:imu_tracker/services/login_data_handling.dart';

import 'package:web_socket_channel/io.dart';
import 'package:imu_tracker/data_structures/function_return_types.dart';
import 'package:imu_tracker/data_structures/response_types.dart';

class WebSocketHandler {
//Websocket Variables
  var sucessfullyRegistered = false;
  late WebSocketChannel channel; //initialize a websocket channel
  bool isWebsocketRunning = false; //status of a websocket
  int retryLimit = 3;

  //static late WebSocketService _instance;
  static WebSocketChannel channel =
      WebSocketChannel.connect(Uri.parse('ws://192.168.178.42:8080'));

  var gyroMessage = {
    "type": "data",
    "value": ["4", "4", "44", "4", "4", "4", "55"],
    "apikey": apikey
  };

  var message = {"type": "", "value": [], "apikey": ""};
  var _loginMessage = {"type": "sender", "value": [], "apikey": apikey};

  bool sucessfullyRegistered = false;
//Gyroscope Variables

  var accelerationX,
      accelerationY,
      accelerationZ,
      gyroscopeX,
      gyroscopeY,
      gyroscopeZ;
  void connectWebSocket(socketData) async {
    if (isWebsocketRunning) return; //check if its already running
    this.channel = IOWebSocketChannel.connect(
      Uri.parse('ws://${socketData['ServerIp']}'),
    );
    channel.stream.listen(
      (message) {
        var handledMessage = messageHandler(message);
        if (handledMessage.hasMessageRightFormat &&
            handledMessage.webSocketResponseType ==
                responseList['deviceRegistered']!.responseNumber) {
          isWebsocketRunning = true;
        } //pass a function to use the recieved JSON data and parse it
      },
      onDone: () {
        isWebsocketRunning = false;
      },
      onError: (err) {
        isWebsocketRunning = false;
        if (retryLimit > 0) {
          retryLimit--;
          connectWebSocket(socketData);
        }
      },
    );
  }

  void sendMessage(messageString) {
    if (messageString.isNotEmpty) {
      channel.sink.add(jsonEncode(messageString));
    }
  }

  void registerAsSender(socketData) {
    var _registrationMessage = buildRegistrationMessage(socketData);
    channel.sink.add(jsonEncode(_registrationMessage));
    print(_registrationMessage);
  }

  MessageHandlerReturnType messageHandler(message) {
    var decodedJSON;
    bool decodeSucceeded = false;
    try {
      decodedJSON = json.decode(message) as Map<String, dynamic>;
      decodeSucceeded = true;
    } on FormatException catch (e) {
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

  void buildValueMessage(values, apiKey) {
    var buildMessage = {
      "type": "data",
      "value": [
        values.accelerationX,
        values.accelerationY,
        values.accelerationZ,
        values.gyroscopeX,
        values.gyroscopeY,
        values.gyroscopeZ,
        "0",
        "0",
        "0"
      ],
      "apikey": apiKey
    };
    sendMessage(buildMessage);
  }

  void dispose() {
    if (channel != null) {
      channel.sink.close();
    }
  }
  buildRegistrationMessage(socketData) {
    var _registrationMessage = {"type": "sender", "value": [], "apikey": ""};
    _registrationMessage['apikey'] = socketData['apiKey'];

    return _registrationMessage;
  }
}
