const dataTnputNames = ["acceleration", "rotation", "temperature", "battery"];
var textboxes = [];

var websocket;

// get server ip
var serverIP = $.get("../debug/getServerIP.php").done(function (data) {
  // create a new WebSocket.
  websocket = new WebSocket("ws://" + data + ":8080");

  // socket message callback
  websocket.onmessage = function (e) {
    outputField.append(e.data);
    console.log(e.data);
  };
});

// generate textboxes
for (var i = 0; i < dataTnputNames.length; i++) {
  newTextbox = document.createElement("input");
  newTextbox.setAttribute("name", dataTnputNames[i]);
  newTextbox.setAttribute("placeholder", dataTnputNames[i] + " value");
  if (i > 0) {
    newTextbox.style.display = "none";
  }
  $(".inputContainer").append(newTextbox);
}

// reference objects
var textboxes = [];
for (var i = 0; i < dataTnputNames.length; i++) {
  textboxes.push(document.getElementsByName(dataTnputNames[i])[0]);
}

var dropdown = document.getElementById("dropdown");
var outputField = document.getElementById("outputField");

$(document).ready(function () {
  textboxes[0].placeholder = "enter api key";
});

// dropdown change
function onChange() {
  textboxes[0].value = "";
  switch (dropdown.value) {
    case "login":
      textboxes[0].placeholder = "enter api key";
      showAccGyrTextbox(false);
      break;
    case "logout":
      textboxes[0].placeholder = "enter pin";
      showAccGyrTextbox(false);
      break;
    case "subscribe":
      textboxes[0].placeholder = "enter device id";
      textboxes[1].placeholder = "ture or false";
      showAccGyrTextbox(false);
      textboxes[1].style.display = "block";
      break;
    case "data":
      textboxes[0].placeholder = dataTnputNames[0] + " value";
      showAccGyrTextbox(true);
      break;
    case "event":
      textboxes[0].placeholder = "enter event data";
      showAccGyrTextbox(false);
      break;
  }
}

function showAccGyrTextbox(state) {
  for (var i = 0; i < dataTnputNames.length - 1; i++) {
    textboxes[i + 1].style.display = state ? "block" : "none";
  }
}

var message = {};

function onClick() {
  if (textboxes[0].value != "") {
    //set value
    switch (dropdown.value) {
      case "login":
        message.t = "i"; // login
        message.a = textboxes[0].value;
        console.log("login");
        break;
      case "logout":
        message.t = "o"; // logout
        message.p = textboxes[0].value;
        console.log("logout");
        break;
      case "subscribe":
        message.t = "s"; // subscribe
        message.i = textboxes[0].value;
        message.s = textboxes[1].value;
        console.log("subscribe");
        break;
      case "data":
        message.t = "d"; // tracking data
        message.a = [];
        message.r = [];
        message.tp = [];
        message.b = [];

        console.log("data");
        break;
      case "event":
        message.t = "e"; // event
        message.value = textboxes[0].value;
        console.log("event");
        break;
    }
    websocket.send(JSON.stringify(message));
  } else {
    alert("no value");
  }
}

// Get the modal
var modal = document.getElementById("qrCodeWindow");

function generateQRCode() {
  var message = {};
  message.apikey =
    "cceb996336b98f2c9cb6136d96f47457b3dc8b301012d468a4634c8fefafe002";
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
