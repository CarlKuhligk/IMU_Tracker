//import sha256 from "crypto-js/sha256";
//const hash = sha256("Text");

var websocket;
// get server ip
var serverIP = $.get("../debug/getServerIP.php").done(function (data) {
  // create a new WebSocket.
  websocket = new WebSocket("ws://" + data + ":8080");

  // socket message callback
  websocket.onmessage = function (e) {
    outputField.append(e.data);
    console.log(e.data);

    input = JSON.parse(e.data);
    if (input.t === "k") {
      generateQRCode(input.a);
    }
  };
});

function createTextbox(name, placeholder, visible) {
  newTextbox = document.createElement("input");
  newTextbox.setAttribute("name", name);
  newTextbox.setAttribute("placeholder", placeholder);
  if (!visible) newTextbox.style.display = "none";
  $(".textboxes").append(newTextbox);
}

var dropdown = document.getElementById("dropdown1");
var outputField = document.getElementById("outputField");
mainButton = document.getElementById("sendButton");

$(document).ready(function () {
  onDropdownChange();
});

// dropdown change
function onDropdownChange() {
  $(".textboxes").empty();

  switch (dropdown.value) {
    case "login":
      mainButton.firstChild.data = "send";
      createTextbox("input1", "enter apikey", true);
      break;

    case "logout":
      mainButton.firstChild.data = "send";
      createTextbox("input1", "enter pin", true);
      break;

    case "subscribe":
    case "unsubscribe":
      mainButton.firstChild.data = "send";
      break;

    case "transmitData":
      mainButton.firstChild.data = "send";
      createTextbox("input1", "acceleration", true);
      createTextbox("input2", "rotation", true);
      createTextbox("input3", "battery", true);
      createTextbox("input4", "temperature", true);
      break;
    case "settingsUpdate":
      mainButton.firstChild.data = "send";
      createTextbox("input0", "device id", true);
      createTextbox("input1", "idleTimeout", true);
      createTextbox("input2", "batteryWarning", true);
      createTextbox("input3", "connectionTimeout", true);
      createTextbox("input4", "measurementInterval", true);
      createTextbox("input5", "accelerationMin", true);
      createTextbox("input6", "accelerationMax", true);
      createTextbox("input7", "rotationMin", true);
      createTextbox("input8", "rotationMax", true);
      break;

    case "newDevice":
      mainButton.firstChild.data = "add device";
      createTextbox("input0", "employee", true);
      createTextbox("input1", "pin", true);
      createTextbox("input2", "idleTimeout", true);
      createTextbox("input3", "batteryWarning", true);
      createTextbox("input4", "connectionTimeout", true);
      createTextbox("input5", "measurementInterval", true);
      createTextbox("input6", "accelerationMin", true);
      createTextbox("input7", "accelerationMax", true);
      createTextbox("input8", "rotationMin", true);
      createTextbox("input9", "rotationMax", true);
      break;
  }
}

function sendMessage(messageOBJ) {
  message = JSON.stringify(messageOBJ);
  console.log(message);
  websocket.send(message);
}

function onClick() {
  var message = {};
  //set value
  switch (dropdown.value) {
    case "login":
      message.t = "i";
      message.a = document.getElementsByName("input1")[0].value;
      sendMessage(message);
      console.log("login");
      break;
    case "logout":
      message.t = "o";
      pin = hash(document.getElementsByName("input1")[0].value);
      message.p = pin;
      sendMessage(message);
      console.log("logout");
      break;
    case "transmitData":
      message.t = "m";
      message.a = document.getElementsByName("input1")[0].value;
      message.r = document.getElementsByName("input2")[0].value;
      message.tp = document.getElementsByName("input3")[0].value;
      message.b = document.getElementsByName("input4")[0].value;
      sendMessage(message);
      console.log("transmitData");
      break;
    case "settingsUpdate":
      message.t = "S";
      message.i = document.getElementsByName("input0")[0].value;
      message.it = document.getElementsByName("input1")[0].value;
      message.b = document.getElementsByName("input2")[0].value;
      message.c = document.getElementsByName("input3")[0].value;
      message.m = document.getElementsByName("input4")[0].value;
      message.ai = document.getElementsByName("input5")[0].value;
      message.a = document.getElementsByName("input6")[0].value;
      message.ri = document.getElementsByName("input7")[0].value;
      message.r = document.getElementsByName("input8")[0].value;
      sendMessage(message);
      console.log("event");
      break;
    case "subscribe":
      message.t = "s";
      message.s = 1;
      sendMessage(message);
      console.log("subscribe");
      break;
    case "unsubscribe":
      message.t = "s";
      message.s = 0;
      sendMessage(message);
      console.log("subscribe");
      break;
    case "newDevice":
      message.t = "A";
      message.e = document.getElementsByName("input0")[0].value;
      message.p = document.getElementsByName("input1")[0].value;
      message.it = document.getElementsByName("input2")[0].value;
      message.b = document.getElementsByName("input3")[0].value;
      message.c = document.getElementsByName("input4")[0].value;
      message.m = document.getElementsByName("input5")[0].value;
      message.ai = document.getElementsByName("input6")[0].value;
      message.a = document.getElementsByName("input7")[0].value;
      message.ri = document.getElementsByName("input8")[0].value;
      message.r = document.getElementsByName("input9")[0].value;

      sendMessage(message);
      break;
  }
}

// Get the modal
var modal = document.getElementById("qrCodeWindow");

function generateQRCode(apikey) {
  var message = {};
  message.apikey = apikey;
  message.host = serverIP.responseText;
  messageText = JSON.stringify(message);

  $("#qrcode").empty();

  var qrcode = new QRCode(document.getElementById("qrcode"), {
    text: messageText,
    width: 250,
    height: 250,
    colorDark: "#000000",
    colorLight: "#ffffff",
    correctLevel: QRCode.CorrectLevel.H,
  });

  modal.style.display = "block";
}

function closeModal() {
  modal.style.display = "none";
}

// When the user clicks anywhere outside of the modal, close it
window.onclick = function (event) {
  if (event.target == modal) {
    modal.style.display = "none";
  }
};
