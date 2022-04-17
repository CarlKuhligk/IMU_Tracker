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

messageManager.addEventListener("handleAddDevice", (event) => {
  handleAddDevice(event);
});

function handleAddDevice(deviceAddMessage) {
  console.log("create device %o", deviceAddMessage);
  var device = new Device(deviceAddMessage);
  device.addEventListener("updateNewSettings", (device) => {
    messageManager.sendNewSettings(device);
  });

  navigationManager.addDeviceEntity(device);
  console.log("Devicelist: %o", Device.list);
}

messageManager.addEventListener("handleUpdateConnection", (event) => {
  handleUpdateConnection(event);
});

function handleUpdateConnection(updateMessage) {
  console.log("%o", updateMessage);
  Device.list[updateMessage.i].isConnected = updateMessage.c;
  console.log("Updated Device %o", Device.list[updateMessage.i]);
  navigationManager.updateDeviceEntity(Device.list[updateMessage.i]);
}

messageManager.addEventListener("handleAddEvent", (event) => {
  handleAddEvent(event);
});

function handleAddEvent(addEventMessage) {
  Device.addEvent(addEventMessage);
}

messageManager.addEventListener("handleAddMeasurement", (event) => {
  handleAddMeasurement(event);
});

function handleAddMeasurement(addMeasurementMessage) {
  addMeasurementMessage.d.forEach((newMeasurement) => {
    var message = {
      d: [newMeasurement],
    };
    Device.list[newMeasurement.i].addMeasurement(message);
  });
}

messageManager.addEventListener("handleSettingsUpdate", (event) => {
  handleUpdateSettings(event);
});

function handleUpdateSettings(settingsUpdateMessage) {
  Device.list[settingsUpdateMessage.i].updateSettings(settingsUpdateMessage);
}

window.addEventListener("load", bodyLoad());
