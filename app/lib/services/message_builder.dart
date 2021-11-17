import 'dart:convert';

String apikey =
    "23b651a79c9a5136d4751e6df9659ea15ed9df4768c211ede558d1ebd3b0c5bd";

var gyroMessage = {
  "type": "data",
  "value": ["4", "4", "44", "4", "4", "4", "55"],
  "apikey": apikey
};

var message = {"type": "", "value": [], "apikey": ""};
var loginMessage = {"type": "sender", "value": [], "apikey": apikey};
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