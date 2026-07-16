const API_BASE = "http://localhost:4000/api";
const SOCKET_BASE = "http://localhost:4000";

let token = localStorage.getItem("tm_token") || "";
let user = JSON.parse(localStorage.getItem("tm_user") || "null");
let currentConsultationId = "";

const socket = io(SOCKET_BASE, { autoConnect: true });

const authStatus = document.getElementById("authStatus");
const appointmentsBox = document.getElementById("appointments");
const fhirOutput = document.getElementById("fhirOutput");
const chatMessages = document.getElementById("chatMessages");

function setStatus(text, isError = false) {
  authStatus.textContent = text;
  authStatus.style.color = isError ? "#ff9f9f" : "#b8f9e8";
}

async function api(path, options = {}) {
  const headers = {
    "Content-Type": "application/json",
    ...(options.headers || {})
  };

  if (token) {
    headers.Authorization = `Bearer ${token}`;
  }

  const response = await fetch(`${API_BASE}${path}`, {
    ...options,
    headers
  });

  const data = await response.json();

  if (!response.ok) {
    throw new Error(data.message || "Erreur API");
  }

  return data;
}

document.getElementById("registerForm").addEventListener("submit", async (event) => {
  event.preventDefault();
  const formData = new FormData(event.currentTarget);
  const payload = Object.fromEntries(formData.entries());

  try {
    await api("/auth/register", {
      method: "POST",
      body: JSON.stringify(payload)
    });
    setStatus("Inscription reussie. Connecte-toi.");
    event.currentTarget.reset();
  } catch (error) {
    setStatus(error.message, true);
  }
});

document.getElementById("loginForm").addEventListener("submit", async (event) => {
  event.preventDefault();
  const payload = Object.fromEntries(new FormData(event.currentTarget).entries());

  try {
    const result = await api("/auth/login", {
      method: "POST",
      body: JSON.stringify(payload)
    });

    token = result.token;
    user = result.user;
    localStorage.setItem("tm_token", token);
    localStorage.setItem("tm_user", JSON.stringify(user));
    setStatus(`Connecte: ${user.fullName} (${user.role})`);
    event.currentTarget.reset();
    await refreshAppointments();
  } catch (error) {
    setStatus(error.message, true);
  }
});

async function refreshAppointments() {
  if (!token) {
    return;
  }

  try {
    const list = await api("/appointments/mine");
    appointmentsBox.innerHTML = "";

    list.forEach((item) => {
      const el = document.createElement("div");
      el.className = "list-group-item bg-transparent text-light border-light-subtle";
      const person = user.role === "doctor" ? item.patientId?.fullName : item.doctorId?.fullName;
      el.textContent = `${new Date(item.scheduledAt).toLocaleString()} | ${person || "-"} | ${item.status} | ${item.reason || ""}`;
      appointmentsBox.appendChild(el);
    });
  } catch (error) {
    setStatus(error.message, true);
  }
}

document.getElementById("refreshAppointments").addEventListener("click", refreshAppointments);

document.getElementById("appointmentForm").addEventListener("submit", async (event) => {
  event.preventDefault();

  if (!token) {
    setStatus("Connecte-toi d'abord", true);
    return;
  }

  const payload = Object.fromEntries(new FormData(event.currentTarget).entries());

  try {
    await api("/appointments", {
      method: "POST",
      body: JSON.stringify(payload)
    });
    setStatus("Rendez-vous cree");
    event.currentTarget.reset();
    await refreshAppointments();
  } catch (error) {
    setStatus(error.message, true);
  }
});

document.getElementById("fhirForm").addEventListener("submit", async (event) => {
  event.preventDefault();

  if (!token) {
    setStatus("Connecte-toi d'abord", true);
    return;
  }

  const patientId = new FormData(event.currentTarget).get("patientId");

  try {
    const bundle = await api(`/fhir/patients/${patientId}/bundle`);
    fhirOutput.textContent = JSON.stringify(bundle, null, 2);
  } catch (error) {
    fhirOutput.textContent = error.message;
  }
});

document.getElementById("chatJoinForm").addEventListener("submit", (event) => {
  event.preventDefault();
  currentConsultationId = new FormData(event.currentTarget).get("consultationId");
  socket.emit("join-consultation", currentConsultationId);
  const line = document.createElement("div");
  line.className = "chat-line";
  line.textContent = `Canal rejoint: ${currentConsultationId}`;
  chatMessages.appendChild(line);
});

document.getElementById("chatForm").addEventListener("submit", (event) => {
  event.preventDefault();

  if (!currentConsultationId || !user) {
    setStatus("Connecte-toi et rejoins une consultation", true);
    return;
  }

  const text = new FormData(event.currentTarget).get("text");
  socket.emit("chat-message", {
    consultationId: currentConsultationId,
    senderId: user.id,
    text
  });

  event.currentTarget.reset();
});

socket.on("chat-message", (msg) => {
  const line = document.createElement("div");
  line.className = "chat-line";
  line.textContent = `[${new Date(msg.sentAt).toLocaleTimeString()}] ${msg.senderId}: ${msg.text}`;
  chatMessages.appendChild(line);
  chatMessages.scrollTop = chatMessages.scrollHeight;
});
