import "../lib/canvasjs.min.js";

export class ContentManager {
  constructor(device) {
    this.buildContent(device);
    $(".rootContent").empty();
    $(".rootContent").append(this.ContentDIV);
    this.buildChart(device);
  }

  buildContent(device) {
    this.buildChartRoot(device);
    this.buildControlsRoot(device);
  }

  buildChartRoot(device) {
    this.ContentDIV = document.createElement("div");
    this.ContentDIV.classList.add("content");
    this.ContentLabel = document.createElement("label");
    this.ContentLabel.classList.add("contentHeadLabel");
    this.ContentLabel.textContent = device.employee;
    this.ContentDIV.appendChild(this.ContentLabel);

    this.ChartRootDIV = document.createElement("div");
    this.ChartRootDIV.classList.add("chartRoot");

    this.ChartComponentsDIV = document.createElement("div");
    this.ChartComponentsDIV.classList.add("chartComponents");

    this.DeviceHistoryChartDIV = document.createElement("div");
    this.DeviceHistoryChartDIV.classList.add("chartPlaceholder");
    this.DeviceHistoryChartDIV.id = "chartContainer";
    this.ChartComponentsDIV.appendChild(this.DeviceHistoryChartDIV);

    this.ChartRootDIV.appendChild(this.ChartComponentsDIV);
    this.ContentDIV.appendChild(this.ChartRootDIV);
  }

  buildControlsRoot(device) {
    // settings
    this.ControlsRootDIV = document.createElement("div");
    this.ControlsRootDIV.classList.add("controlsRoot");
    this.ControlsRootLabel = document.createElement("label");
    this.ControlsRootLabel.textContent = "Einstellungen";
    this.ControlsRootLabel.id = "controlsRootLabel";
    this.ControlsRootDIV.appendChild(this.ControlsRootLabel);

    this.buildControlContent(device);

    this.ControlsRootDIV.appendChild(this.ControlsContent);

    this.ContentDIV.appendChild(this.ControlsRootDIV);
  }

  buildControlContent(device) {
    this.ControlsContent = document.createElement("div");
    this.ControlsContent.classList.add("controlsContent");

    this.ControlCollection = document.createElement("div");
    this.ControlCollection.classList.add("controls");

    // battery warning
    this.BatteryWarningLabel = document.createElement("label");
    this.BatteryWarningLabel.textContent = "Batterie niedrig Warnung [%]";
    this.BatteryWarningLabel.id = "batteryWarningLabel";
    this.BatteryWarningInput = document.createElement("input");
    this.BatteryWarningInput.value = device.batteryWarning;
    this.BatteryWarningInput.setAttribute("type", "number");
    this.BatteryWarningInput.id = "batteryWarningInput";
    this.ControlCollection.appendChild(this.BatteryWarningLabel);
    this.ControlCollection.appendChild(this.BatteryWarningInput);

    // idle timeout
    this.IdleTimeoutLabel = document.createElement("label");
    this.IdleTimeoutLabel.textContent = "Bewegungslosigkeit [s]";
    this.IdleTimeoutLabel.id = "idleTimeoutLabel";
    this.IdleTimeoutInput = document.createElement("input");
    this.IdleTimeoutInput.value = device.idleTimeout;
    this.IdleTimeoutInput.setAttribute("type", "number");
    this.IdleTimeoutInput.id = "idleTimeoutInput";
    this.ControlCollection.appendChild(this.IdleTimeoutLabel);
    this.ControlCollection.appendChild(this.IdleTimeoutInput);

    // connection timeout
    this.ConnectionTimeoutLabel = document.createElement("label");
    this.ConnectionTimeoutLabel.textContent = "Verbindungsverlust [s]";
    this.ConnectionTimeoutLabel.id = "connectionTimeoutLabel";
    this.ConnectionTimeoutInput = document.createElement("input");
    this.ConnectionTimeoutInput.value = device.connectionTimeout;
    this.ConnectionTimeoutInput.setAttribute("type", "number");
    this.ConnectionTimeoutInput.id = "connectionTimeoutInput";
    this.ControlCollection.appendChild(this.ConnectionTimeoutLabel);
    this.ControlCollection.appendChild(this.ConnectionTimeoutInput);

    // measurement interval
    this.MeasurementIntervalLabel = document.createElement("label");
    this.MeasurementIntervalLabel.textContent = "Messinterval [ms]";
    this.MeasurementIntervalLabel.id = "measurementIntervalLabel";
    this.MeasurementIntervalInput = document.createElement("input");
    this.MeasurementIntervalInput.value = device.measurementInterval;
    this.MeasurementIntervalInput.setAttribute("type", "number");
    this.MeasurementIntervalInput.id = "measurementIntervalInput";
    this.ControlCollection.appendChild(this.MeasurementIntervalLabel);
    this.ControlCollection.appendChild(this.MeasurementIntervalInput);

    // acceleration min
    this.AccelerationMinLabel = document.createElement("label");
    this.AccelerationMinLabel.textContent = "max. Beschleunigung [m/s²]";
    this.AccelerationMinLabel.id = "accelerationMinLabel";
    this.AccelerationMinInput = document.createElement("input");
    this.AccelerationMinInput.value = device.accelerationMin;
    this.AccelerationMinInput.setAttribute("type", "number");
    this.AccelerationMinInput.id = "accelerationMinInput";
    this.ControlCollection.appendChild(this.AccelerationMinLabel);
    this.ControlCollection.appendChild(this.AccelerationMinInput);

    // acceleration max
    this.AccelerationMaxLabel = document.createElement("label");
    this.AccelerationMaxLabel.textContent = "min. Beschleunigung [m/s²]";
    this.AccelerationMaxLabel.id = "accelerationMaxLabel";
    this.AccelerationMaxInput = document.createElement("input");
    this.AccelerationMaxInput.value = device.accelerationMax;
    this.AccelerationMaxInput.setAttribute("type", "number");
    this.AccelerationMaxInput.id = "accelerationMaxInput";
    this.ControlCollection.appendChild(this.AccelerationMaxLabel);
    this.ControlCollection.appendChild(this.AccelerationMaxInput);

    // rotation min
    this.RotationMinLabel = document.createElement("label");
    this.RotationMinLabel.textContent = "max. Rotationsbeschleunigung [rad/s²]";
    this.RotationMinLabel.id = "rotationMinLabel";
    this.RotationMinInput = document.createElement("input");
    this.RotationMinInput.value = device.rotationMin;
    this.RotationMinInput.setAttribute("type", "number");
    this.RotationMinInput.id = "rotationMinInput";
    this.ControlCollection.appendChild(this.RotationMinLabel);
    this.ControlCollection.appendChild(this.RotationMinInput);

    // rotation max
    this.RotationMaxLabel = document.createElement("label");
    this.RotationMaxLabel.textContent = "min. Rotationsbeschleunigung [rad/s²]";
    this.RotationMaxLabel.id = "rotationMaxLabel";
    this.RotationMaxInput = document.createElement("input");
    this.RotationMaxInput.value = device.rotationMax;
    this.RotationMaxInput.setAttribute("type", "number");
    this.RotationMaxInput.id = "rotationMaxInput";
    this.ControlCollection.appendChild(this.RotationMaxLabel);
    this.ControlCollection.appendChild(this.RotationMaxInput);

    this.ControlsContent.appendChild(this.ControlCollection);

    //update button
    this.UpdateSettingsButton = document.createElement("button");
    this.UpdateSettingsButton.textContent = "Aktualisieren";
    this.UpdateSettingsButton.id = "updateSettingsButton";
    this.UpdateSettingsButton.addEventListener("click", () => {
      device.sendNewSettings();
    });

    this.ControlsContent.appendChild(this.UpdateSettingsButton);
  }

  updateControls(device) {
    document.getElementById("idleTimeoutInput").value = device.idleTimeout;
    document.getElementById("batteryWarningInput").value = device.batteryWarning;
    document.getElementById("connectionTimeoutInput").value = device.connectionTimeout;
    document.getElementById("measurementIntervalInput").value = device.measurementInterval;
    document.getElementById("accelerationMinInput").value = device.accelerationMin;
    document.getElementById("accelerationMaxInput").value = device.accelerationMax;
    document.getElementById("rotationMinInput").value = device.rotationMin;
    document.getElementById("rotationMaxInput").value = device.rotationMax;
  }

  buildChart(device) {
    this.chart = new CanvasJS.Chart("chartContainer", {
      animationEnabled: false,
      exportEnabled: true,
      zoomEnabled: true,
      theme: "dark1",
      backgroundColor: "#444444",
      title: {
        text: "Ereignisverlauf",
        fontSize: 26,
        fontFamily: "Courier New",
      },
      axisX: {
        title: "",
        fontFamily: "Courier New",
      },
      //acceleration
      //rotation
      //event state
      //temperature
      //battery
      axisY: [
        {
          title: "Acceleration",
          lineColor: "#3A83FF",
          tickColor: "#3A83FF",
          labelFontColor: "#3A83FF",
          titleFontColor: "#3A83FF",
          includeZero: true,
          suffix: " m/s²",
          fontFamily: "Courier New",
        },
        {
          title: "Angular Acceleration",
          lineColor: "#A42EFF",
          tickColor: "#A42EFF",
          labelFontColor: "#A42EFF",
          titleFontColor: "#A42EFF",
          includeZero: true,
          suffix: " rad/s²",
          fontFamily: "Courier New",
        },
        {
          title: "Battery",
          lineColor: "#35FFDE",
          tickColor: "#35FFDE",
          labelFontColor: "#35FFDE",
          titleFontColor: "#35FFDE",
          includeZero: true,
          suffix: " %",
          fontFamily: "Courier New",
        },
        {
          title: "Temperature",
          lineColor: "#7DEB28",
          tickColor: "#7DEB28",
          labelFontColor: "#7DEB28",
          titleFontColor: "#7DEB28",
          includeZero: true,
          suffix: " °C",
          fontFamily: "Courier New",
        },
      ],
      toolTip: {
        shared: true,
      },
      axisY2: {
        title: "Event Trigger",
        lineColor: "#E00930",
        tickColor: "#E00930",
        labelFontColor: "#E00930",
        titleFontColor: "#E00930",
        includeZero: true,
        suffix: "",
        fontFamily: "Courier New",
      },
      legend: {
        cursor: "pointer",
        verticalAlign: "bottom",
        fontSize: 14,
        fontColor: "white",
        fontFamily: "Courier New",
        markerMargin: 4,
        itemWidth: 200,
        itemclick: function (e) {
          if (typeof e.dataSeries.visible === "undefined" || e.dataSeries.visible) {
            e.dataSeries.visible = false;
          } else {
            e.dataSeries.visible = true;
          }

          e.chart.render();
        },
      },
      data: [
        {
          type: "line",
          xValueType: "dateTime",
          yValueFormatString: "####.## m/s²",
          xValueFormatString: "YYYY-MMM-DD hh:mm:ss",
          showInLegend: true,
          name: "Acceleration",
          fontFamily: "Courier New",
          axisYIndex: 0,
          lineColor: "#3A83FF",
          markerColor: "#3A83FF",
          legendMarkerColor: "#3A83FF",

          dataPoints: device.measurements.acceleration,
        },
        {
          type: "line",
          xValueType: "dateTime",
          yValueFormatString: "####.## rad/s²",
          xValueFormatString: "YYYY-MMM-DD hh:mm:ss",
          showInLegend: true,
          name: "Angular Acceleration",
          fontFamily: "Courier New",
          axisYIndex: 1,
          lineColor: "#A42EFF",
          markerColor: "#A42EFF",
          legendMarkerColor: "#A42EFF",

          dataPoints: device.measurements.rotation,
        },
        {
          type: "line",
          xValueType: "dateTime",
          yValueFormatString: "## '%'",
          xValueFormatString: "YYYY-MMM-DD hh:mm:ss",
          showInLegend: true,
          name: "Battery",
          fontFamily: "Courier New",
          axisYIndex: 2,
          lineColor: "#35FFDE",
          markerColor: "#35FFDE",
          legendMarkerColor: "#35FFDE",

          dataPoints: device.measurements.battery,
        },
        {
          type: "line",
          xValueType: "dateTime",
          yValueFormatString: " ##.#°C",
          xValueFormatString: "YYYY-MMM-DD hh:mm:ss",
          showInLegend: true,
          name: "Temperature",
          fontFamily: "Courier New",
          axisYIndex: 3,
          lineColor: "#7DEB28",
          markerColor: "#7DEB28",
          legendMarkerColor: "#7DEB28",

          dataPoints: device.measurements.temperature,
        },
        //###############################//###############################
        //#######  E V E N T S  //#######//###############################
        //###############################//###############################
        {
          type: "stepLine",
          lineDashType: "dash",
          xValueType: "dateTime",
          yValueFormatString: " #",
          xValueFormatString: "YYYY-MMM-DD hh:mm:ss",
          showInLegend: true,
          name: "Battery Empty",
          fontFamily: "Courier New",
          axisYType: "secondary",
          axisYIndex: 0,
          lineColor: "#D80C31",
          markerType: "",
          markerColor: "#D80C31",
          legendMarkerColor: "#D80C31",

          dataPoints: device.events.batteryEmpty,
        },
        {
          type: "stepLine",
          lineDashType: "dash",
          xValueType: "dateTime",
          yValueFormatString: " #",
          xValueFormatString: "YYYY-MMM-DD hh:mm:ss",
          showInLegend: true,
          name: "Battery Warning",
          fontFamily: "Courier New",
          axisYType: "secondary",
          axisYIndex: 0,
          lineColor: "#FF4E0E",
          markerType: "",
          markerColor: "#FF4E0E",
          legendMarkerColor: "#FF4E0E",

          dataPoints: device.events.batteryWarning,
        },
        {
          type: "stepLine",
          lineDashType: "dash",
          xValueType: "dateTime",
          yValueFormatString: " #",
          xValueFormatString: "YYYY-MMM-DD hh:mm:ss",
          showInLegend: true,
          name: "Idle Timeout",
          fontFamily: "Courier New",
          axisYType: "secondary",
          axisYIndex: 0,
          lineColor: "#FF6E0E",
          markerType: "",
          markerColor: "#FF6E0E",
          legendMarkerColor: "#FF6E0E",

          dataPoints: device.events.idleTimeout,
        },
        {
          type: "stepLine",
          lineDashType: "dash",
          xValueType: "dateTime",
          yValueFormatString: " #",
          xValueFormatString: "YYYY-MMM-DD hh:mm:ss",
          showInLegend: true,
          name: "Connection Lost",
          fontFamily: "Courier New",
          axisYType: "secondary",
          axisYIndex: 0,
          lineColor: "#FF8E0E",
          markerType: "",
          markerColor: "#FF8E0E",
          legendMarkerColor: "#FF8E0E",

          dataPoints: device.events.connectionLost,
        },
        {
          type: "stepLine",
          lineDashType: "dash",
          xValueType: "dateTime",
          yValueFormatString: " #",
          xValueFormatString: "YYYY-MMM-DD hh:mm:ss",
          showInLegend: true,
          name: "Connection Timeout",
          fontFamily: "Courier New",
          axisYType: "secondary",
          axisYIndex: 0,
          lineColor: "#FFAE0E",
          markerType: "",
          markerColor: "#FFAE0E",
          legendMarkerColor: "#FFAE0E",

          dataPoints: device.events.connectionTimeout,
        },
        {
          type: "stepLine",
          lineDashType: "dash",
          xValueType: "dateTime",
          yValueFormatString: " #",
          xValueFormatString: "YYYY-MMM-DD hh:mm:ss",
          showInLegend: true,
          name: "Acceleration Exceeded",
          fontFamily: "Courier New",
          axisYType: "secondary",
          axisYIndex: 0,
          lineColor: "#FFAE0E",
          markerType: "",
          markerColor: "#FFAE0E",
          legendMarkerColor: "#FFAE0E",

          dataPoints: device.events.accelerationExceeded,
        },
        {
          type: "stepLine",
          lineDashType: "dash",
          xValueType: "dateTime",
          yValueFormatString: " #",
          xValueFormatString: "YYYY-MMM-DD hh:mm:ss",
          showInLegend: true,
          name: "Rotation Exceeded",
          fontFamily: "Courier New",
          axisYType: "secondary",
          axisYIndex: 0,
          lineColor: "#FFEE0E",
          markerType: "",
          markerColor: "#FFEE0E",
          legendMarkerColor: "#FFEE0E",

          dataPoints: device.events.rotationExceeded,
        },
      ],
    });
    this.renderChart();
  }

  renderChart() {
    this.chart.render();
  }
}
