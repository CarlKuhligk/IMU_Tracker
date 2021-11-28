import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

//Websocket Variables
String apikey =
    "23b651a79c9a5136d4751e6df9659ea15ed9df4768c211ede558d1ebd3b0c5bd";

var gyroMessage = {
  "type": "data",
  "value": ["4", "4", "44", "4", "4", "4", "55"],
  "apikey": apikey
};

var message = {"type": "", "value": [], "apikey": ""};
var loginMessage = {"type": "sender", "value": [], "apikey": apikey};

var channel = WebSocketChannel.connect(Uri.parse('ws://192.168.0.20:8080'));

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
    //print('sent message');
    //print(messageString);
  }
}

void registerAsSender() {
  channel.sink.add(jsonEncode(loginMessage));
  print(loginMessage);
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


/*
void main() {
  print(message["type"]);
  String rawJson = jsonEncode(message);
  print(rawJson);
  var message2 = jsonDecode(rawJson);
  print(message2["type"]);
  print(message2["value"]);
  print(message2["apikey"]);
}
*/