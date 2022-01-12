import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:convert';


checkQrCode(qrCode) {
  bool _success = false;
  var _qrObject = jsonDecode(qrCode);

  return _success;
}

/*
  print(message["type"]);
  String rawJson = jsonEncode(message);
  print(rawJson);
  var message2 = jsonDecode(rawJson);
  print(message2["type"]);
  print(message2["value"]);
  print(message2["apikey"]);
  */