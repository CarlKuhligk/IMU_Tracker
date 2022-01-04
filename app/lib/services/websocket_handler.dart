import 'dart:convert';
import 'package:imu_tracker/services/localstorage_service.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:imu_tracker/services/login_data_handling.dart';

String apikey =
    "23b651a79c9a5136d4751e6df9659ea15ed9df4768c211ede558d1ebd3b0c5bd";

class WebSocketService {
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

/*
  Future<WebSocketService> getInstance() async {
    _instance = WebSocketService();

    _channel = WebSocketChannel.connect(Uri.parse('ws://192.168.178.42:8080'));

    return _instance;
  }
*/
  void sendMessage(messageString) {
    if (messageString.isNotEmpty) {
      channel.sink.add(jsonEncode(messageString));
    }
  }

  void registerAsSender() {
    channel.sink.add(jsonEncode(_loginMessage));
    print(_loginMessage);
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

  void buildValueMessage() {
    var buildMessage = {
      "type": "data",
      "value": [
        accelerationX,
        accelerationY,
        accelerationZ,
        gyroscopeX,
        gyroscopeY,
        gyroscopeZ,
        "0",
        "0",
        "0"
      ],
      "apikey": apikey
    };
    sendMessage(buildMessage);
  }

  void dispose() {
    channel.sink.close();
  }
}
