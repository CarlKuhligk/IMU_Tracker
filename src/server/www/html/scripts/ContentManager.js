export class ContentManager {
<<<<<<< Updated upstream
  constructor() {
    this.navigation = document.createElement("div");
    this.navigation.classList.add("navigation");

    this.navigationHead = document.createElement("div");
    this.navigationHead.classList.add("navigationHead");
    this.navigationHeadLabel1 = document.createElement("label");
    this.navigationHeadLabel1.textContent = "Security Motion Tracker";

    this.navigationEventSection = document.createElement("div");
    this.navigationEventSection.classList.add("navigationSection");
    this.navigationEventSection.id = "eventNavigation";
    this.navigationEventSectionButton1 = document.createElement("button");
    this.navigationEventSectionButton1.innerText = "Events";

    this.navigationDeviceSection = document.createElement("div");
    this.navigationDeviceSection.classList.add("navigationSection");
    this.navigationDeviceSection.id = "deviceNavigation";
    this.navigationDeviceSectionLabel1 = document.createElement("label");
    this.navigationDeviceSectionLabel1.innerText = "Geräte";

    this.navigationDeviceSectionDeviceList = document.createElement("div");
    this.navigationDeviceSectionDeviceList.classList.add(
      "navigationDevicesSubSection"
    );
    this.navigationDeviceSection.id = "deviceList";

    this.buildNavigationHTML();
  }

  buildNavigationHTML() {
    this.navigationHead.appendChild(this.navigationHeadLabel1);
    this.navigation.appendChild(this.navigationHead);

    this.navigationEventSection.appendChild(this.navigationEventSectionButton1);
    this.navigation.appendChild(this.navigationEventSection);

    this.navigationDeviceSection.appendChild(
      this.navigationDeviceSectionLabel1
    );
    this.navigationDeviceSection.appendChild(
      this.navigationDeviceSectionDeviceList
    );

    this.navigation.appendChild(this.navigationDeviceSection);

    $(".rootNavigation").empty();
    $(".rootNavigation").append(this.navigation);
  }

  generateDeviceHTMLObject(device) {
    var newDeviceNavigationObject = document.createElement("div");
    newDeviceNavigationObject.classList.add("device");
    newDeviceNavigationObject.id = device.id;

    // add connection image
    var imgConnection = document.createElement("img");
    imgConnection.classList.add("isConnected");
    if (device.isConnected === 1) {
      imgConnection.src = "./img/circle-green.png";
      imgConnection.alt = "connected";
    } else {
      imgConnection.src = "./img/circle-grey.png";
      imgConnection.alt = "not connected";
    }
    newDeviceNavigationObject.appendChild(imgConnection);

    // add id label
    var labelDeviceIs = document.createElement("label");
    //_____labelChannelName.onclick = onClickModuleLabel;
    labelDeviceIs.innerText = device.id;
    newDeviceNavigationObject.appendChild(labelDeviceIs);

    // add employee label
    var labelEmployee = document.createElement("label");
    //_____labelChannelName.onclick = onClickModuleLabel;
    labelEmployee.innerText = device.employee;
    newDeviceNavigationObject.appendChild(labelEmployee);

    // add battery label
    var labelBattery = document.createElement("label");
    //_____labelChannelName.onclick = onClickModuleLabel;
    labelBattery.innerText = "???";
    newDeviceNavigationObject.appendChild(labelBattery);

    // add event info image
    var imgEventInfo = document.createElement("img");
    imgEventInfo.classList.add("eventInfo");
    imgEventInfo.src = "./img/information-variant.png";
    imgEventInfo.alt = "event information";
    newDeviceNavigationObject.appendChild(imgEventInfo);

    return newDeviceNavigationObject;
  }

  addDeviceEntity(device) {
    $(".navigationDevicesSubSection").append(
      this.generateDeviceHTMLObject(device)
    );
  }

  removeDeviceEntity(device) {
    var selection = "#" + device.id;
    $(selection).remove();
  }

  updateDeviceEntity(device) {
    this.removeDeviceEntity(device);
    $(".navigationDevicesSubSection").prepend(
      this.generateDeviceHTMLObject(device)
    );
=======
  constructor(device) {
    this.content = document.createElement("div");
    this.content.classList.add("content");

    this.contentHeadLabel = document.createElement("label");
    this.contentHeadLabel.classList.add("contentHeadLabel");
    this.contentHeadLabel.textContent = device.employee;

    this.contentAccelerationDiagram = document.createElement("div");
    this.contentAccelerationDiagram.classList.add("accelerationHistory");
    this.contentAccelerationDiagramLabel1 = document.createElement("label");
    this.contentAccelerationDiagramLabel1.textContent = "Bewegungsverlauf";

    this.AccelerationDiagramCollection = document.createElement("div");
    this.AccelerationDiagramCollection.classList.add("diagramCollection");

    this.AccelerationDiagram = document.createElement("div");
    this.AccelerationDiagram.classList.add("diagramContainer");
    this.AccelerationDiagram.id = "accelerationDiagramPlaceholder";

    this.AccelerationDiagramLegend = document.createElement("div");
    this.AccelerationDiagramLegend.classList.add("legend");

    this.AccelerationDiagramWindow = document.createElement("div");
    this.AccelerationDiagramWindow.classList.add("window");
    this.WindowInput = document.createElement("input");
    this.WindowInput.id = "updateInterval";
    this.WindowInput.type = "text";

    this.AccelerationDiagramCurrent = document.createElement("div");
    this.AccelerationDiagramCurrent.classList.add("current");

    this.buildContentHTML();
  }

  buildContentHTML() {
    this.AccelerationDiagramCollection.appendChild(this.AccelerationDiagram);

    this.AccelerationDiagramCollection.appendChild(
      this.AccelerationDiagramLegend
    );

    this.AccelerationDiagramWindow.appendChild(this.WindowInput);
    this.AccelerationDiagramCollection.appendChild(
      this.AccelerationDiagramWindow
    );

    this.AccelerationDiagramCollection.appendChild(
      this.AccelerationDiagramCurrent
    );

    this.contentAccelerationDiagram.appendChild(
      this.contentAccelerationDiagramLabel1
    );

    this.contentAccelerationDiagram.appendChild(
      this.AccelerationDiagramCollection
    );

    this.content.appendChild(this.contentHeadLabel);
    this.content.appendChild(this.contentAccelerationDiagram);

    $(".rootContent").empty();
    $(".rootContent").append(this.content);
>>>>>>> Stashed changes
  }
}
