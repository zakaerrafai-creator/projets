const registerChatSocket = require("./chatSocket");
const registerWebRTCSocket = require("./webrtcSocket");

function registerSockets(io) {
  io.on("connection", (socket) => {
    registerChatSocket(socket, io);
    registerWebRTCSocket(socket, io);
  });
}

module.exports = registerSockets;
