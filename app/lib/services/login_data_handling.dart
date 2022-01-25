//dart packages
import 'dart:convert';

//QRCode String:
//{"host":"192.168.0.20:8080","apikey":"23b651a79c9a5136d4751e6df9659ea15ed9df4768c211ede558d1ebd3b0c5bd"}

checkQrCode(qrCodeType, qrCodeData) {
  var decodedJSON;
  var decodeSucceeded = false;

  if (qrCodeType == 'qrcode') {
    try {
      decodedJSON = json.decode(qrCodeData) as Map<String, dynamic>;
      decodeSucceeded = true;
    } on FormatException catch (e) {
      print('The provided string is not valid JSON');
      return false;
    }

    if (decodeSucceeded &&
        decodedJSON["host"] != null &&
        decodedJSON["apikey"] != null) {
      print("No Null values");
      return true;
    } else {
      return false;
    }
  } else {
    return false;
  }
}
