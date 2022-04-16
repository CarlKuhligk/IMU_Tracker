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
<<<<<<< Updated upstream
    imgConnection.classList.add("isConnected");
=======
    imgConnection.classList.add("isConnectedImg");
>>>>>>> Stashed changes
    if (device.isConnected === 1) {
      imgConnection.src = "./img/circle-green.png";
      imgConnection.alt = "connected";
    } else {
      imgConnection.src = "./img/circle-grey.png";
      imgConnection.alt = "not connected";
    }
    newDeviceNavigationObject.appendChild(imgConnection);

    // add id label
<<<<<<< Updated upstream
    var labelDeviceIs = document.createElement("label");
    //_____labelChannelName.onclick = onClickModuleLabel;
    labelDeviceIs.innerText = device.id;
    newDeviceNavigationObject.appendChild(labelDeviceIs);
=======
    var labelDeviceId = document.createElement("label");
    //_____labelChannelName.onclick = onClickModuleLabel;
    labelDeviceId.classList.add("deviceIdLabel");
    labelDeviceId.innerText = device.id;
    newDeviceNavigationObject.appendChild(labelDeviceId);
>>>>>>> Stashed changes

    // add employee label
    var labelEmployee = document.createElement("label");
    //_____labelChannelName.onclick = onClickModuleLabel;
<<<<<<< Updated upstream
=======
    labelEmployee.classList.add("employeeLabel");
>>>>>>> Stashed changes
    labelEmployee.innerText = device.employee;
    newDeviceNavigationObject.appendChild(labelEmployee);

    // add battery label
    var labelBattery = document.createElement("label");
    //_____labelChannelName.onclick = onClickModuleLabel;
<<<<<<< Updated upstream
=======
    labelBattery.classList.add("batteryLabel");
>>>>>>> Stashed changes
    labelBattery.innerText = "???";
    newDeviceNavigationObject.appendChild(labelBattery);

    // add event info image
    var imgEventInfo = document.createElement("img");
<<<<<<< Updated upstream
    imgEventInfo.classList.add("eventInfo");
=======
    imgEventInfo.classList.add("eventInfoImg");
>>>>>>> Stashed changes
    imgEventInfo.src = "./img/information-variant.png";
    imgEventInfo.alt = "event information";
    newDeviceNavigationObject.appendChild(imgEventInfo);

<<<<<<< Updated upstream
=======
    newDeviceNavigationObject.addEventListener("click", (event) => {
      alert(device.employee);
    });

>>>>>>> Stashed changes
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