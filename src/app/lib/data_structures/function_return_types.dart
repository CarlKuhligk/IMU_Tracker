class WebSocketTestResultReturnType {
  bool isWebSocketConnected;
  bool isApiKeyValid;
  int webSocketResponseNumber;
  WebSocketTestResultReturnType(this.isWebSocketConnected, this.isApiKeyValid,
      this.webSocketResponseNumber);
}

class MessageHandlerReturnType {
  bool hasMessageRightFormat;
  String webSocketResponseType;
  int webSocketResponseNumber;
  MessageHandlerReturnType(this.hasMessageRightFormat,
      this.webSocketResponseType, this.webSocketResponseNumber);
}
