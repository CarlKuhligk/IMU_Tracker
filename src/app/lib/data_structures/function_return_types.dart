// ignore_for_file: prefer_typing_uninitialized_variables

class WebSocketTestResultReturnType {
  bool isWebSocketConnected;
  bool isApiKeyValid;
  int webSocketResponseNumber;
  WebSocketTestResultReturnType(this.isWebSocketConnected, this.isApiKeyValid,
      this.webSocketResponseNumber);
}

class MessageDecoderReturnType {
  bool hasMessageRightFormat;
  String webSocketResponseType;
  var webSocketResponseNumber;
  MessageDecoderReturnType(this.hasMessageRightFormat,
      this.webSocketResponseType, this.webSocketResponseNumber);
}
