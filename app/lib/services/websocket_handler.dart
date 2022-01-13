//dart packages
import 'dart:convert';
import 'dart:async';
//additional packages
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
//project specific types
import 'package:imu_tracker/data_structures/function_return_types.dart';
import 'package:imu_tracker/data_structures/response_types.dart';

class WebSocketHandler {
//Websocket Variables
  var sucessfullyRegistered = false;
  late WebSocketChannel channel; //initialize a websocket channel
  bool isWebsocketRunning = false; //status of a websocket
  int retryLimit = 3;

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

  Future<WebSocketTestResultReturnType> testWebSocketConnection(
      socketData) async {
    bool _isWebsocketRunning = false;

    var _webSocketMessageNumber = 0;

    var _registrationMessage = buildRegistrationMessage(socketData);

    var _webSocket = IOWebSocketChannel.connect(
      Uri.parse('ws://${socketData['ServerIp']}'),
    );

    return await Future.delayed(Duration(seconds: 1), () async {
      if (_webSocket.innerWebSocket != null) {
        _webSocket.sink.add(jsonEncode(_registrationMessage));

        _webSocket.stream.listen(
          (message) {
            var handledMessage = messageHandler(message);
            if (handledMessage.hasMessageRightFormat &&
                handledMessage.webSocketResponseType ==
                    responseList['deviceRegistered']!.responseNumber) {
              _isWebsocketRunning = true;
              _webSocket.sink.close();
            } else {
              _webSocket.sink.close();
            }
            _webSocketMessageNumber = handledMessage.webSocketResponseType;
          },
          onError: (err) {
            _isWebsocketRunning = false;
          },
        );
      } else {
        if (_webSocket.innerWebSocket != null) {
          _webSocket.sink.close();
        }
      }

      return await Future.delayed(Duration(seconds: 1), () {
        return WebSocketTestResultReturnType(
            _isWebsocketRunning, _webSocketMessageNumber);
      });
    });
  }

  buildRegistrationMessage(socketData) {
    var _registrationMessage = {"type": "sender", "value": [], "apikey": ""};
    _registrationMessage['apikey'] = socketData['apiKey'];

    return _registrationMessage;
  }
}
