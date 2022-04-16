import { ContentManager } from "./ContentManager.js";

export class Device {
  static events;
  static content;

  constructor(message) {
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

    this.isConnected = false;
    this.measurements = {
      temperature: [],
      battery: [],
      acceleration: [],
      rotation: [],
    };

    this.alarmState = 0;
    this.isSelected = false;

    this.addMeasurement(message);

    console.log("CONVERT MEASUREMENTS");
    console.log(JSON.stringify(this.measurements));
  }

  activateContent() {
    console.log("GET EVENTLIST");
    console.log(JSON.stringify(this.getEventList()));
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

  addMeasurement(message) {
    var timestamps = message.d.map((item) => item.t);
    var temperatures = message.d.map((item) => item.tp);
    var batterys = message.d.map((item) => item.b);
    var accelerations = message.d.map((item) => item.a);
    var rotations = message.d.map((item) => item.r);

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
    // update chart
  }

  getEventList() {
    // filter events that match to the device id
    var eventsMatchingDeviceId = Device.events.filter((event) => event.i == this.id);

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
      var timestamps = eventsOfEventId.map((item) => item.t);
      var isTriggereds = eventsOfEventId.map((item) => item.a);

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
  }
}
