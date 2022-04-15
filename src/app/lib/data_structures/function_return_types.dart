class WebSocketTestResultReturnType {
  bool isWebSocketConnected;
  bool isApiKeyValid;
  int webSocketResponseNumber;
  WebSocketTestResultReturnType(this.isWebSocketConnected, this.isApiKeyValid,
      this.webSocketResponseNumber);
}

class messageDecoderReturnType {
  bool hasMessageRightFormat;
  String webSocketResponseType;
  int webSocketResponseNumber;
  messageDecoderReturnType(this.hasMessageRightFormat,
      this.webSocketResponseType, this.webSocketResponseNumber);
}
