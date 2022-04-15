import { Device } from "./Device.js";
import { MessageManager } from "./MessageManager.js";
import { NavigationManager } from "./NavigationManager.js";
<<<<<<< Updated upstream

var messageManager = new MessageManager();
var navigationManager;
=======
import { ContentManager } from "./ContentManager.js";

var messageManager = new MessageManager();
var navigationManager;
var content;
>>>>>>> Stashed changes

var deviceList = [];

function bodyLoad() {
  messageManager.connect();
  navigationManager = new NavigationManager();
}

function handleAddDevice(deviceAddMessage) {
  console.log("%o", deviceAddMessage);
  var newDevice = new Device(deviceAddMessage);
  deviceList[newDevice.id] = newDevice;
  navigationManager.addDeviceEntity(newDevice);
  console.log("Devicelist: %o", deviceList);
}

function handleUpdateConnection(updateMessage) {
  console.log("%o", updateMessage);
  deviceList[updateMessage.i].isConnected = updateMessage.c;
  console.log("Updated Device %o", deviceList[updateMessage.i]);
  navigationManager.updateDeviceEntity(deviceList[updateMessage.i]);
}

messageManager.addEventListener("handleAddDevice", (event) => {
  handleAddDevice(event);
});

messageManager.addEventListener("handleUpdateConnection", (event) => {
  handleUpdateConnection(event);
});

window.addEventListener("load", bodyLoad());
