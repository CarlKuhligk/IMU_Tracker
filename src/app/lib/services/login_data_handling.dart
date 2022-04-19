//dart packages
// ignore_for_file: prefer_typing_uninitialized_variables

import 'dart:convert';

//QRCode example String:
//{"host":"192.168.178.70","apikey":"4d7048cbb191d6728ae014accb552d6a1aecc6a1fbd88b5a69e912ca47f6732f", "port":"8080"}

checkQrCode(qrCodeType, qrCodeData) {
  var decodedJSON;
  var decodeSucceeded = false;

  if (qrCodeType == 'qrcode') {
    try {
      decodedJSON = json.decode(qrCodeData) as Map<String, dynamic>;
      decodeSucceeded = true;
    } on FormatException {
      return false;
    }

    if (decodeSucceeded &&
        decodedJSON["host"] != null &&
        decodedJSON["apikey"] != null &&
        decodedJSON["port"] != null) {
      return true;
    } else {
      return false;
    }
  } else {
    return false;
  }
}
