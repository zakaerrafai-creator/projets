/**
 * Signalisation WebRTC via Socket.IO
 * Echange offre/reponse SDP + candidats ICE entre deux pairs dans une salle de consultation
 */
function registerWebRTCSocket(socket, io) {
  socket.on("webrtc-join", (consultationId) => {
    if (!consultationId) {
      return;
    }
    const room = `rtc:${consultationId}`;
    socket.join(room);

    // Prevenir les autres membres de la salle qu'un nouveau pair vient de rejoindre
    socket.to(room).emit("webrtc-peer-joined");
  });

  socket.on("webrtc-offer", (payload) => {
    const { consultationId, offer } = payload || {};
    if (!consultationId || !offer) {
      return;
    }
    socket.to(`rtc:${consultationId}`).emit("webrtc-offer", { offer });
  });

  socket.on("webrtc-answer", (payload) => {
    const { consultationId, answer } = payload || {};
    if (!consultationId || !answer) {
      return;
    }
    socket.to(`rtc:${consultationId}`).emit("webrtc-answer", { answer });
  });

  socket.on("webrtc-ice", (payload) => {
    const { consultationId, candidate } = payload || {};
    if (!consultationId || !candidate) {
      return;
    }
    socket.to(`rtc:${consultationId}`).emit("webrtc-ice", { candidate });
  });

  socket.on("webrtc-leave", (consultationId) => {
    if (!consultationId) {
      return;
    }
    socket.to(`rtc:${consultationId}`).emit("webrtc-peer-left");
    socket.leave(`rtc:${consultationId}`);
  });
}

module.exports = registerWebRTCSocket;
