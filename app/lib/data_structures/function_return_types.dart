class WebSocketTestResultReturnType {
  bool isWebSocketConnected;
  int webSocketResponseType;
  WebSocketTestResultReturnType(
      this.isWebSocketConnected, this.webSocketResponseType);
}

class MessageHandlerReturnType {
  bool hasMessageRightFormat;
  int webSocketResponseType;
  MessageHandlerReturnType(
      this.hasMessageRightFormat, this.webSocketResponseType);
}
