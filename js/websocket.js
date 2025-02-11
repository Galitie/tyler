// let canVibrate = false;

// let playerServerStatus = document.querySelector("h4");
// let hostServerStatus = document.querySelector("h3");

const websocketUrl =
  "wss://13z2e6ro4l.execute-api.us-west-2.amazonaws.com/prod";
const socket = new WebSocket(websocketUrl);

// Connection opened event and check for host
socket.onopen = function (event) {
  console.log("WebSocket connection established.");
  //playerServerStatus.innerText = "\u2705 Connected to Server";

  const packet = {
    action: "messageHost",
    message: "attemptJoin",
  };
  sendMessage(JSON.stringify(packet));
};

// Message received event
socket.onmessage = function (event) {
  const message = JSON.parse(event.data);
  console.log("Received message:", message);

  // if ("vibrate" in navigator) {
  // canVibrate = true;
  // }

  if (message["message"] == "Internal server error") {
    //hostServerStatus.innerText = "\u2717 Disconnected from Host";
    //hostServerStatus.style.color = "red";
    notConnectedScreen();
  } else if (message["message"] == "refuseJoin") {
    gameAlreadyStartedScreen();
  } else {
    //hostServerStatus.innerText = "\u2705 Host sent message!";
    //hostServerStatus.style.color = "white";
    // if (canVibrate) navigator.vibrate(200);
    console.log(JSON.stringify(message));
    promptScreen(
      message["header"],
      message["timer"],
      message["timerType"],
      message["diceEnabled"],
      message["dice"],
      message["inputs"],
      message["style"]
    );
    packageContext = message["context"];
  }
};

// Error event
socket.onerror = function (error) {
  console.error("WebSocket error:", error);
};

// Connection closed event
socket.onclose = function (event) {
  console.log("WebSocket connection closed:", event.code, event.reason);
  //playerServerStatus.innerText = "\u2717 Disconnected from Server";
  //playerServerStatus.style.color = "red";
  notConnectedScreen();
};

// Send a message to the WebSocket API
function sendMessage(message) {
  socket.send(message);
  console.log("Sent message:", message);
}
