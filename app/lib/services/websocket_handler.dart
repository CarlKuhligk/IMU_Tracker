import 'dart:convert';
import 'package:imu_tracker/services/localstorage_service.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:imu_tracker/services/login_data_handling.dart';


class WebSocketHandler {
//Websocket Variables

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

  void messageHandler(message) {
    if (message != null) {
      var incomingMessage = jsonDecode(message);
      //print(message);
      if (incomingMessage['type'] == 'response' &&
          incomingMessage['id'] == '10') {
        //print("Successfully registered as Sender");
        sucessfullyRegistered = true;
      }
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
    channel.sink.close();
  }
}
