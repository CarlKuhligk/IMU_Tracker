export class Device {
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
    this.alarmState = 0;
    this.measurements = [];
  }

  updateNavigationHTML() {
    // update navigation content
  }

  updateContentHTML() {
    // update device content
  }

  updateHTML() {
    // update navigation content
    // update device content
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

  addMeasurement(message) {}
}
