// adds an html element to channel section
function appendNewChannel(newChannel) {
  $(".cannelContainer").append(newChannel);
}

// creates an client html element
function createChannel(id, name, state, clientCount) {
  var newHTMLChannel = document.createElement("div");
  newHTMLChannel.classList.add("channel");
  newHTMLChannel.id = id;
  //html_module.setAttribute("moduleId",module.id);

  // add statusimage
  var imgState = document.createElement("img");
  imgState.classList.add("stateImage");
  imgState.setAttribute("state", state);
  if (state === 1) {
    imgState.src = "img/online.png";
    imgState.alt = "online";
  } else {
    imgState.src = "img/offline.png";
    imgState.alt = "offline";
  }
  newHTMLChannel.appendChild(imgState);

  // add channelname
  var labelChannelName = document.createElement("label");
  //_____labelChannelName.onclick = onClickModuleLabel;
  labelChannelName.innerText = name;
  newHTMLChannel.appendChild(labelChannelName);

  // add userimage
  var imgUser = document.createElement("img");
  imgUser.classList.add("userSymbol");
  imgUser.src = "img/user.png";
  imgUser.alt = "client count";
  newHTMLChannel.appendChild(imgUser);

  // add clientcount
  var labelClientCount = document.createElement("label");
  //_____labelClientCount.onclick = onClickModuleLabel;
  labelClientCount.innerText = clientCount;
  newHTMLChannel.appendChild(labelClientCount);

  return newHTMLChannel;
}

// updates an client html element
function updateChannel(id, name, state, clientCount) {
  updateHTMLChannel = document.getElementById(id);

  // update state image
  imgState = updateHTMLChannel.children[0];
  imgState.setAttribute("state", state);
  if (state === 1) {
    imgState.src = "img/online.png";
    imgState.alt = "online";
  } else {
    imgState.src = "img/offline.png";
    imgState.alt = "offline";
  }

  // update name
  labelChannelName = updateHTMLChannel.children[1];
  labelChannelName.innerText = name;

  // update client count
  labelClientCount = updateHTMLChannel.children[3];
  labelClientCount.innerText = clientCount;
}

function deleteChannel() {}

// updates the number of registered channels
function updateChannelOverview(channelCount) {
  channelCountLabel =
    document.getElementsByClassName("channelOverview")[0].children[2];
  channelCountLabel.innerText = channelCount;
}
