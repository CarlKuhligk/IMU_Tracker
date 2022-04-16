import { Device } from "./Device.js";
import { MessageManager } from "./MessageManager.js";
import { NavigationManager } from "./NavigationManager.js";

var messageManager = new MessageManager();
var navigationManager;

var deviceList = [];
Device.events = [];
Device.content = "";

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

function handleAddEvent(addEventMessage) {
  Device.addEvent(addEventMessage);
}

messageManager.addEventListener("handleAddDevice", (event) => {
  handleAddDevice(event);
});

messageManager.addEventListener("handleUpdateConnection", (event) => {
  handleUpdateConnection(event);
});

messageManager.addEventListener("handleAddEvent", (event) => {
  handleAddEvent(event);
});

window.addEventListener("load", bodyLoad());
