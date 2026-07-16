/**
 * consultation.js – Visioconsultation WebRTC + chat Socket.IO
 * ECUE 424 – Communication temps réel / Télémédecine
 *
 * Flux WebRTC :
 *  1. Les deux pairs rejoignent la même salle (webrtc-join)
 *  2. Le second pair déclenche webrtc-peer-joined sur le premier
 *  3. Le premier crée une offre SDP → envoyée via Socket.IO
 *  4. Le second répond avec une réponse SDP
 *  5. Les candidats ICE sont échangés bilatéralement
 */

const SOCKET_BASE = "http://localhost:4000";

const STUN_SERVERS = {
  iceServers: [
    { urls: "stun:stun.l.google.com:19302" },
    { urls: "stun:stun1.l.google.com:19302" }
  ]
};

// ── État global ────────────────────────────────────────────────────────────────
const socket = io(SOCKET_BASE);
let peerConnection = null;
let localStream = null;
let consultationId = "";
let displayName = "";
let micEnabled = true;
let camEnabled = true;

// ── Références DOM ─────────────────────────────────────────────────────────────
const joinScreen = document.getElementById("joinScreen");
const roomScreen = document.getElementById("roomScreen");
const localVideo = document.getElementById("localVideo");
const remoteVideo = document.getElementById("remoteVideo");
const statusBadge = document.getElementById("statusBadge");
const remoteName = document.getElementById("remoteName");
const localName = document.getElementById("localName");
const chatMessages = document.getElementById("chatMessages");

// ── Rejoindre une salle ────────────────────────────────────────────────────────
document.getElementById("joinForm").addEventListener("submit", async (event) => {
  event.preventDefault();
  consultationId = document.getElementById("consultationId").value.trim();
  displayName = document.getElementById("displayName").value.trim();

  if (!consultationId || !displayName) {
    return;
  }

  try {
    localStream = await navigator.mediaDevices.getUserMedia({ video: true, audio: true });
    localVideo.srcObject = localStream;
    localName.textContent = displayName;
  } catch (error) {
    alert("Impossible d'accéder à la caméra/micro : " + error.message);
    return;
  }

  joinScreen.hidden = true;
  roomScreen.hidden = false;
  document.getElementById("roomIdLabel").textContent = consultationId;

  socket.emit("webrtc-join", consultationId);
  // Rejoindre aussi la salle de chat
  socket.emit("join-consultation", consultationId);
});

// ── Créer la PeerConnection ────────────────────────────────────────────────────
function createPeerConnection() {
  if (peerConnection) {
    peerConnection.close();
  }

  peerConnection = new RTCPeerConnection(STUN_SERVERS);

  // Ajouter les pistes locales
  localStream.getTracks().forEach((track) => {
    peerConnection.addTrack(track, localStream);
  });

  // Recevoir les pistes distantes
  peerConnection.ontrack = (event) => {
    if (remoteVideo.srcObject !== event.streams[0]) {
      remoteVideo.srcObject = event.streams[0];
    }
  };

  // Echanger les candidats ICE via Socket.IO
  peerConnection.onicecandidate = (event) => {
    if (event.candidate) {
      socket.emit("webrtc-ice", { consultationId, candidate: event.candidate });
    }
  };

  peerConnection.onconnectionstatechange = () => {
    const state = peerConnection.connectionState;
    if (state === "connected") {
      setStatus("Connecté", true);
      remoteName.textContent = "Pair distant";
    } else if (state === "disconnected" || state === "failed") {
      setStatus("Déconnecté");
    }
  };

  return peerConnection;
}

// ── Signalisation Socket.IO ────────────────────────────────────────────────────

// Un nouveau pair vient de rejoindre la salle → on crée l'offre
socket.on("webrtc-peer-joined", async () => {
  setStatus("Pair présent – connexion en cours…");
  const pc = createPeerConnection();

  const offer = await pc.createOffer();
  await pc.setLocalDescription(offer);
  socket.emit("webrtc-offer", { consultationId, offer });
});

// On reçoit une offre → on crée la réponse
socket.on("webrtc-offer", async ({ offer }) => {
  setStatus("Offre reçue – connexion en cours…");
  const pc = createPeerConnection();

  await pc.setRemoteDescription(new RTCSessionDescription(offer));
  const answer = await pc.createAnswer();
  await pc.setLocalDescription(answer);
  socket.emit("webrtc-answer", { consultationId, answer });
});

// On reçoit la réponse
socket.on("webrtc-answer", async ({ answer }) => {
  if (!peerConnection) {
    return;
  }
  await peerConnection.setRemoteDescription(new RTCSessionDescription(answer));
});

// On reçoit un candidat ICE
socket.on("webrtc-ice", async ({ candidate }) => {
  if (!peerConnection || !candidate) {
    return;
  }
  try {
    await peerConnection.addIceCandidate(new RTCIceCandidate(candidate));
  } catch (error) {
    // Candidat ICE ignore si PC pas encore pret
  }
});

// Le pair distant a quitté
socket.on("webrtc-peer-left", () => {
  setStatus("Le pair a quitté la consultation");
  remoteVideo.srcObject = null;
  remoteName.textContent = "En attente du pair…";
});

// ── Chat intégré ───────────────────────────────────────────────────────────────
socket.on("chat-message", (msg) => {
  const isMe = msg.senderId === displayName;
  appendChatLine(msg.senderId, msg.text, isMe);
});

document.getElementById("chatForm").addEventListener("submit", (event) => {
  event.preventDefault();
  const input = document.getElementById("chatInput");
  const text = input.value.trim();

  if (!text || !consultationId) {
    return;
  }

  socket.emit("chat-message", {
    consultationId,
    senderId: displayName,
    text
  });

  input.value = "";
});

function appendChatLine(sender, text, isMe) {
  const line = document.createElement("div");
  line.className = `chat-line ${isMe ? "chat-line-me" : "chat-line-other"}`;
  line.innerHTML = `<strong>${sender}:</strong> ${text}`;
  chatMessages.appendChild(line);
  chatMessages.scrollTop = chatMessages.scrollHeight;
}

// ── Contrôles micro / caméra ───────────────────────────────────────────────────
document.getElementById("btnMute").addEventListener("click", () => {
  micEnabled = !micEnabled;
  localStream.getAudioTracks().forEach((t) => (t.enabled = micEnabled));
  document.getElementById("btnMute").classList.toggle("active", !micEnabled);
  document.getElementById("btnMute").textContent = micEnabled ? "🎙️" : "🔇";
});

document.getElementById("btnCamera").addEventListener("click", () => {
  camEnabled = !camEnabled;
  localStream.getVideoTracks().forEach((t) => (t.enabled = camEnabled));
  document.getElementById("btnCamera").classList.toggle("active", !camEnabled);
  document.getElementById("btnCamera").textContent = camEnabled ? "📷" : "🚫";
});

// ── Terminer la consultation ───────────────────────────────────────────────────
document.getElementById("btnEnd").addEventListener("click", endCall);

function endCall() {
  socket.emit("webrtc-leave", consultationId);

  if (peerConnection) {
    peerConnection.close();
    peerConnection = null;
  }

  if (localStream) {
    localStream.getTracks().forEach((t) => t.stop());
    localStream = null;
  }

  window.location.href = "index.html";
}

// ── Helpers ────────────────────────────────────────────────────────────────────
function setStatus(text, isConnected = false) {
  statusBadge.textContent = text;
  statusBadge.classList.toggle("connected", isConnected);
}
