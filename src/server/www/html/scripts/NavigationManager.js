export class NavigationManager {
  constructor() {
    this.devices = [];

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
    imgConnection.classList.add("isConnectedImg");
    if (device.isConnected === 1) {
      imgConnection.src = "./img/circle-green.png";
      imgConnection.alt = "connected";
    } else {
      imgConnection.src = "./img/circle-grey.png";
      imgConnection.alt = "not connected";
    }
    newDeviceNavigationObject.appendChild(imgConnection);

    // add id label
    var labelDeviceId = document.createElement("label");
    //_____labelChannelName.onclick = onClickModuleLabel;
    labelDeviceId.classList.add("deviceIdLabel");
    labelDeviceId.innerText = device.id;
    newDeviceNavigationObject.appendChild(labelDeviceId);

    // add employee label
    var labelEmployee = document.createElement("label");
    //_____labelChannelName.onclick = onClickModuleLabel;
    labelEmployee.classList.add("employeeLabel");
    labelEmployee.innerText = device.employee;
    newDeviceNavigationObject.appendChild(labelEmployee);

    // add battery label
    var labelBattery = document.createElement("label");
    //_____labelChannelName.onclick = onClickModuleLabel;
    labelBattery.classList.add("batteryLabel");
    labelBattery.innerText = "???";
    newDeviceNavigationObject.appendChild(labelBattery);

    // add event info image
    var imgEventInfo = document.createElement("img");
    imgEventInfo.classList.add("eventInfoImg");
    imgEventInfo.src = "./img/information-variant.png";
    imgEventInfo.alt = "event information";
    newDeviceNavigationObject.appendChild(imgEventInfo);

    newDeviceNavigationObject.addEventListener("click", (event) => {
      alert(device.employee);
    });

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
  }
}
