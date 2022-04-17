import { ContentManager } from "./ContentManager.js";

export class Device {
  static events;
  static content;
  static list = [];

  constructor(message) {
    this.listeners = {};

    this.id = message.i;
    this.employee = message.e;
    this.idleTimeout = message.it;
    this.batteryWarning = message.b;
    this.connectionTimeout = message.c;
    this.measurementInterval = message.m;
    this.accelerationMin = message.ai;
    this.accelerationMax = message.a;
    this.rotationMin = message.ri;
    this.rotationMax = message.r;

    this.measurements = {
      temperature: [],
      battery: [],
      acceleration: [],
      rotation: [],
    };
    this.events = {};

    this.isConnected = false;
    this.alarmState = 0;
    this.isSelected = false;

    console.log("Device builded");

    this.addMeasurement(message);

    console.log("measurements imprted");

    Device.list[this.id] = this;
  }

  select() {
    Device.unselectAll();
    this.isSelected = true;
    this.updateEventList();
    console.log(JSON.stringify(this.events));
    var content = new ContentManager(this);
  }

  updateConnectionState(message) {
    this.isConnected = message.c;
  }

  updateSettings(newSettings) {
    this.idleTimeout = newSettings.it;
    this.batteryWarning = newSettings.b;
    this.connectionTimeout = newSettings.c;
    this.measurementInterval = newSettings.m;
    this.accelerationMin = newSettings.ai;
    this.accelerationMax = newSettings.a;
    this.rotationMin = newSettings.ri;
    this.rotationMax = newSettings.r;
  }

  updateEventList() {
    this.events = this.getEventList();
    this.callback("updateEvent");
    this.callback("update");
  }

  addMeasurement(message) {
    var timestamps = message.d.map((item) => new Date(item.t));
    var temperatures = message.d.map((item) => parseFloat(item.tp));
    var batterys = message.d.map((item) => parseFloat(item.b));
    var accelerations = message.d.map((item) => parseFloat(item.a));
    var rotations = message.d.map((item) => parseFloat(item.r));

    Array.prototype.push.apply(
      this.measurements.temperature,
      this.convertToChartDataPoints(timestamps, temperatures)
    );
    Array.prototype.push.apply(
      this.measurements.battery,
      this.convertToChartDataPoints(timestamps, batterys)
    );
    Array.prototype.push.apply(
      this.measurements.acceleration,
      this.convertToChartDataPoints(timestamps, accelerations)
    );
    Array.prototype.push.apply(
      this.measurements.rotation,
      this.convertToChartDataPoints(timestamps, rotations)
    );
    this.callback("updateMeasurement");
    this.callback("update");
  }

  getEventList(deviceSpecific = true) {
    var eventsMatchingDeviceId;
    if (deviceSpecific) {
      // filter events that match to the device id
      eventsMatchingDeviceId = Device.events.filter((event) => event.i == this.id);
    } else {
      eventsMatchingDeviceId = Device.events;
    }

    var eventIdFilter = [11, 10, 12, 21, 22, 30, 31];

    var result = {
      batteryEmpty: [],
      batteryWarning: [],
      idleTimeout: [],
      connectionLost: [],
      connectionTimeout: [],
      accelerationExceeded: [],
      rotationExceeded: [],
    };
    var resultKeys = Object.keys(result);

    // split the array of event objects in to single arrays
    eventIdFilter.forEach(function (eventId, index) {
      var eventsOfEventId = eventsMatchingDeviceId.filter((event) => event.e == eventId);

      // extracting event data
      var timestamps = eventsOfEventId.map((item) => new Date(item.t));
      var isTriggereds = eventsOfEventId.map((item) => (item.a ? 1 : 0));

      // convert and insert to result
      result[resultKeys[index]] = this.convertToChartDataPoints(timestamps, isTriggereds);
    }, this);

    return result;
  }

  convertToChartDataPoints(xData, yData) {
    return xData.map(function (x, i) {
      return { x: x, y: yData[i] };
    });
  }

  static addEvent(message) {
    Array.prototype.push.apply(Device.events, message.d);

    Device.list.forEach((device) => {
      if (device.isSelected) {
        // reload event list
        device.updateEventList();
      }
    });
  }

  static unselectAll() {
    Device.list.forEach((device) => {
      device.isSelected = false;
    });
  }

  addEventListener(method, callback) {
    this.listeners[method] = callback;
  }

  removeEventListener(method) {
    delete this.listeners[method];
  }

  callback(method, payload = null) {
    const callback = this.listeners[method];
    if (typeof callback === "function") {
      callback(payload);
    }
  }
}
