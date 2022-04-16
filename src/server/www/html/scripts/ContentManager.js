export class ContentManager {
  constructor(device) {
    this.buildContent(device);

    $(".rootContent").empty();
    $(".rootContent").append(this.ContentDIV);
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
    this.ChartRootLabel = document.createElement("label");
    this.ChartRootLabel.textContent = "Ereignisübersicht";
    this.ChartRootDIV.appendChild(this.ChartRootLabel);

    this.ChartComponentsDIV = document.createElement("div");
    this.ChartComponentsDIV.classList.add("chartComponents");

    this.DeviceHistoryChartDIV = document.createElement("div");
    this.DeviceHistoryChartDIV.classList.add("chartPlaceholder");
    this.DeviceHistoryChartDIV.id = "deviceHistoryChart";
    this.ChartComponentsDIV.appendChild(this.DeviceHistoryChartDIV);

    this.DeviceHistoryChartLegendDIV = document.createElement("div");
    this.DeviceHistoryChartLegendDIV.classList.add("legend");
    this.ChartComponentsDIV.appendChild(this.DeviceHistoryChartLegendDIV);

    this.DeviceHistoryChartWindowDIV = document.createElement("div");
    this.DeviceHistoryChartWindowDIV.classList.add("window");
    this.ChartComponentsDIV.appendChild(this.DeviceHistoryChartWindowDIV);

    this.DeviceHistoryChartCurrentDIV = document.createElement("div");
    this.DeviceHistoryChartCurrentDIV.classList.add("current");
    this.ChartComponentsDIV.appendChild(this.DeviceHistoryChartCurrentDIV);
    this.ChartRootDIV.appendChild(this.ChartComponentsDIV);
    this.ContentDIV.appendChild(this.ChartRootDIV);
  }

  buildControlsRoot(device) {
    // settings
    this.ControlsRootDIV = document.createElement("div");
    this.ControlsRootDIV.classList.add("controlsRoot");
    this.ControlsRootLabel = document.createElement("label");
    this.ControlsRootLabel.textContent = "Einstellungen";
    this.ControlsRootDIV.appendChild(ControlsRootLabel);

    this.ControlsDIV = document.createElement("div");
    this.ControlsDIV.classList.add("controls");

    // battery warning
    this.BatteryWarningLabel = document.createElement("label");
    this.BatteryWarningLabel.textContent = "Batterie niedrig Warnung [%]";
    this.BatteryWarningInput = document.createElement("input");
    this.BatteryWarningInput.setAttribute("name", batteryWarning);
    this.BatteryWarningInput.setAttribute("placeholder", device.batteryWarning);
    this.BatteryWarningInput.setAttribute("type", "number");
    this.ControlsDIV.appendChild(BatteryWarningLabel);
    this.ControlsDIV.appendChild(BatteryWarningInput);

    // idle timeout
    this.IdleTimeoutLabel = document.createElement("label");
    this.IdleTimeoutLabel.textContent = "Bewegungslosigkeit [s]";
    this.IdleTimeoutInput = document.createElement("input");
    this.IdleTimeoutInput.setAttribute("name", batteryWarning);
    this.IdleTimeoutInput.setAttribute("placeholder", device.idleTimeout);
    this.IdleTimeoutInput.setAttribute("type", "number");
    this.ControlsDIV.appendChild(IdleTimeoutLabel);
    this.ControlsDIV.appendChild(IdleTimeoutInput);

    // connection timeout
    this.ConnectionTimeoutLabel = document.createElement("label");
    this.ConnectionTimeoutLabel.textContent = "Verbindungsverlust [s]";
    this.ConnectionTimeoutInput = document.createElement("input");
    this.ConnectionTimeoutInput.setAttribute("name", batteryWarning);
    this.ConnectionTimeoutInput.setAttribute("placeholder", device.connectionTimeout);
    this.ConnectionTimeoutInput.setAttribute("type", "number");
    this.ControlsDIV.appendChild(ConnectionTimeoutLabel);
    this.ControlsDIV.appendChild(ConnectionTimeoutInput);

    // measurement interval
    this.MeasurementIntervalLabel = document.createElement("label");
    this.MeasurementIntervalLabel.textContent = "Messinterval [ms]";
    this.MeasurementIntervalInput = document.createElement("input");
    this.MeasurementIntervalInput.setAttribute("name", batteryWarning);
    this.MeasurementIntervalInput.setAttribute("placeholder", device.measurementInterval);
    this.MeasurementIntervalInput.setAttribute("type", "number");
    this.ControlsDIV.appendChild(MeasurementIntervalLabel);
    this.ControlsDIV.appendChild(MeasurementIntervalInput);

    // acceleration min
    this.AccelerationMinLabel = document.createElement("label");
    this.AccelerationMinLabel.textContent = "max. Beschleunigung [m/s²]";
    this.AccelerationMinInput = document.createElement("input");
    this.AccelerationMinInput.setAttribute("name", batteryWarning);
    this.AccelerationMinInput.setAttribute("placeholder", device.accelerationMin);
    this.AccelerationMinInput.setAttribute("type", "number");
    this.ControlsDIV.appendChild(AccelerationMinLabel);
    this.ControlsDIV.appendChild(AccelerationMinInput);

    // acceleration max
    this.AccelerationMaxLabel = document.createElement("label");
    this.AccelerationMaxLabel.textContent = "min. Beschleunigung [m/s²]";
    this.AccelerationMaxInput = document.createElement("input");
    this.AccelerationMaxInput.setAttribute("name", batteryWarning);
    this.AccelerationMaxInput.setAttribute("placeholder", battery.accelerationMax);
    this.AccelerationMaxInput.setAttribute("type", "number");
    this.ControlsDIV.appendChild(AccelerationMaxLabel);
    this.ControlsDIV.appendChild(AccelerationMaxInput);

    // rotation min
    this.RotationMinLabel = document.createElement("label");
    this.RotationMinLabel.textContent = "max. Rotationsbeschleunigung [rad/s²]";
    this.RotationMinInput = document.createElement("input");
    this.RotationMinInput.setAttribute("name", batteryWarning);
    this.RotationMinInput.setAttribute("placeholder", device.rotationMin);
    this.RotationMinInput.setAttribute("type", "number");
    this.ControlsDIV.appendChild(RotationMinLabel);
    this.ControlsDIV.appendChild(RotationMinInput);

    // rotation max
    this.RotationMaxLabel = document.createElement("label");
    this.RotationMaxLabel.textContent = "min. Rotationsbeschleunigung [rad/s²]";
    this.RotationMaxInput = document.createElement("input");
    this.RotationMaxInput.setAttribute("name", batteryWarning);
    this.RotationMaxInput.setAttribute("placeholder", device.rotationMax);
    this.RotationMaxInput.setAttribute("type", "number");
    this.ControlsDIV.appendChild(RotationMaxLabel);
    this.ControlsDIV.appendChild(RotationMaxInput);
  }

  buildChart(device) {
    this.chart = new CanvasJS.Chart("chartContainer", {
      zoomEnabled: true,
      title: {
        text: "Überschrift",
      },
      axisX: {
        title: "x-beschriftung",
      },
      axisY: {
        title: "Beschleunigung",
        suffix: " m/s²",
        includeZero: false,
      },
      toolTip: {
        shared: true,
      },
      axisY2: {
        title: "Winkelbeschleunigung",
        suffix: " rad/s²",
        includeZero: false,
      },
      legend: {
        cursor: "pointer",
        verticalAlign: "top",
        fontSize: 22,
        fontColor: "dimGrey",
        itemclick: this.toggleDataSeries,
      },
      data: [
        {
          type: "line",
          xValueType: "dateTime",
          yValueFormatString: "$####.00",
          xValueFormatString: "hh:mm:ss TT",
          showInLegend: true,
          name: "WERT A",
          dataPoints: device.measurements.acceleration,
        },
        {
          type: "line",
          xValueType: "dateTime",
          yValueFormatString: "$####.00",
          showInLegend: true,
          name: "WERT B",
          dataPoints: device.measurements.rotation,
        },
      ],
    });
    renderChart();
  }

  toggleDataSeries(e) {
    if (typeof e.dataSeries.visible === "undefined" || e.dataSeries.visible) {
      e.dataSeries.visible = false;
    } else {
      e.dataSeries.visible = true;
    }
    renderChart();
  }

  renderChart() {
    this.chart.render();
  }
}
