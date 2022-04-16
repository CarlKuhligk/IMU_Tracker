export class MessageManager {
  constructor() {
    this.listeners = {};
    this.websocket = {};
  }

  connect() {
    $.get("../debug/getServerIP.php").done((serverIp) => {
      // create a new WebSocket.
      this.openWebsocket(serverIp);
    });
  }

  openWebsocket(serverIp) {
    this.websocket = new WebSocket("ws://192.168.212.9:8080");
    //this.websocket = new WebSocket("ws://" + serverIp + ":8080");

    this.websocket.addEventListener("open", (event) => {
      this.onOpen(event);
    });

    this.websocket.addEventListener("message", (event) => {
      this.onMessage(event);
    });

    this.websocket.addEventListener("close", (event) => {
      this.onClose(event);
    });
  }

  onOpen(event) {
    var messageObject = {};
    messageObject.t = "s";
    messageObject.s = 1;
    var subscribeMessage = JSON.stringify(messageObject);
    this.websocket.send(subscribeMessage);
  }

  onMessage(event) {
    var message = JSON.parse(event.data);

    switch (message.t) {
      case "uc":
        console.log("UpdateConnection received: %o", message);
        this.triggerEvent("handleUpdateConnection", message);
        break;

      case "M":
        console.log("Add measurement received: %o", message);
        this.triggerEvent("handleAddEvent", message);
        break;

      case "e":
        console.log("Add event received: %o", message);
        message.d.forEach((element) => {
          this.triggerEvent("handleAddEvent", element);
        });
        break;

      case "su":
        console.log("Settings update received: %o", message);
        this.triggerEvent("handleSettingsUpdate", message);
        break;

      case "ad":
        console.log("Add device received: %o", message);
        message.d.forEach((element) => {
          this.triggerEvent("handleAddDevice", element);
        });
        break;

      case "rd":
        console.log("Remove device received: %o", message);
        this.triggerEvent("handleRemoveDevice", message);
        break;
    }
  }

  onClose(e) {
    console.log("Connection closed!");
  }

  addEventListener(method, callback) {
    this.listeners[method] = callback;
  }

  removeEventListener(method) {
    delete this.listeners[method];
  }

  triggerEvent(method, payload = null) {
    const callback = this.listeners[method];
    if (typeof callback === "function") {
      callback(payload);
    }
  }
}
