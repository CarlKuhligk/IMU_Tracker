import { Device } from "./Device.js";
import { MessageManager } from "./MessageManager.js";
import { NavigationManager } from "./NavigationManager.js";

var messageManager = new MessageManager();
var navigationManager;

Device.list = [];
Device.events = [];
Device.content = "";

function bodyLoad() {
  messageManager.connect();
  navigationManager = new NavigationManager();
}

function handleAddDevice(deviceAddMessage) {
  console.log("create device %o", deviceAddMessage);
  navigationManager.addDeviceEntity(new Device(deviceAddMessage));
  console.log("Devicelist: %o", Device.list);
}

function handleUpdateConnection(updateMessage) {
  console.log("%o", updateMessage);
  Device.list[updateMessage.i].isConnected = updateMessage.c;
  console.log("Updated Device %o", Device.list[updateMessage.i]);
  navigationManager.updateDeviceEntity(Device.list[updateMessage.i]);
}

function handleAddEvent(addEventMessage) {
  Device.addEvent(addEventMessage);
}

function handleAddMeasurement(addMeasurementMessage) {
  Device.list[addMeasurementMessage.i].addMeasurement(addMeasurementMessage);
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

messageManager.addEventListener("handleAddMeasurement", (event) => {
  handleAddMeasurement(event);
});

window.addEventListener("load", bodyLoad());
