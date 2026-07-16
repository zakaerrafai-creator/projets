function registerChatSocket(socket, io) {
  socket.on("join-consultation", (consultationId) => {
    if (!consultationId) {
      return;
    }
    socket.join(`consultation:${consultationId}`);
  });

  socket.on("chat-message", (payload) => {
    const { consultationId, senderId, text, sentAt } = payload || {};
    if (!consultationId || !senderId || !text) {
      return;
    }

    io.to(`consultation:${consultationId}`).emit("chat-message", {
      consultationId,
      senderId,
      text,
      sentAt: sentAt || new Date().toISOString()
    });
  });
}

module.exports = registerChatSocket;
