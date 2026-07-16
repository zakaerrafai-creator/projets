// === TransCare — app.js (Parte 1) ==========================
// Imports Firebase
import { initializeApp } from "https://www.gstatic.com/firebasejs/11.0.1/firebase-app.js";
import {
  getFirestore, collection, doc, getDocs, getDoc,
  setDoc, updateDoc, addDoc, deleteDoc
} from "https://www.gstatic.com/firebasejs/11.0.1/firebase-firestore.js";

// === Configuración Firebase ===
const firebaseConfig = {
  apiKey: "AIzaSyD1PCQIHzXilinNnyTmX52KrQuQfXKBYT8",
  authDomain: "transcare-91e67.firebaseapp.com",
  projectId: "transcare-91e67",
  storageBucket: "transcare-91e67.appspot.com",
  messagingSenderId: "206117063939",
  appId: "1:206117063939:web:b84a145a3eb76f1b61ed36"
};

// Inicialización
const app = initializeApp(firebaseConfig);
const db = getFirestore(app);

let currentUser = null;
let currentRole = null;

// === Navegación entre pantallas ===
function showScreen(id) {
  document.querySelectorAll(".screen").forEach(s => s.classList.remove("active"));
  const el = document.getElementById(id);
  if (el) el.classList.add("active");
  if (id === "historique") afficherHistorique();
  if (id === "stock") afficherStock();
  if (id === "suivi" && window._leafletMap)
    setTimeout(() => window._leafletMap.invalidateSize(), 100);
}

// === Login ===
async function login() {
  const id = document.getElementById("userId").value.trim();
  const pass = document.getElementById("userPass").value.trim();
  const err = document.getElementById("loginError");
  err.textContent = "";

  try {
    const snap = await getDocs(collection(db, "users"));
    const users = snap.docs.map(d => ({ id: d.id, ...d.data() }));
    const user = users.find(u => u.id === id && u.pass === pass);
    if (!user) return err.textContent = "Identifiant ou mot de passe incorrect.";

    currentUser = id;
    currentRole = (user.role || "").toLowerCase();
    document.getElementById("connectedUser").textContent = `${id} (${currentRole})`;
    document.querySelectorAll(".admin-only").forEach(b => {
      b.style.display = currentRole === "admin" ? "inline-block" : "none";
    });

    populateMedicaments();
    populateServices();
    chargerProfil();
    showScreen("menu");
  } catch (e) {
    console.error("Erreur login:", e);
    err.textContent = "Erreur de connexion. Vérifiez Firestore.";
  }
}

function logout() {
  currentUser = null;
  currentRole = null;
  showScreen("login");
}

// === Gestión de usuarios ===
async function addUser() {
  if (currentRole !== "admin") return alert("Accès refusé");
  const id = document.getElementById("newId").value.trim();
  const pass = document.getElementById("newPass").value.trim();
  const role = document.getElementById("newRole").value;
  if (!id || !pass) return alert("Champs manquants");
  await setDoc(doc(db, "users", id), { pass, role, email: "" });
  alert("✅ Utilisateur créé !");
}

async function afficherUtilisateurs() {
  if (currentRole !== "admin") return alert("Accès refusé");
  const ul = document.getElementById("listeUtilisateurs");
  ul.innerHTML = "";
  const snap = await getDocs(collection(db, "users"));

  snap.forEach(d => {
    const u = d.data();
    const li = document.createElement("li");
    li.innerHTML = `<strong>${d.id}</strong> — ${u.role} — ${u.email || "sans email"}`;
    if (d.id !== "admin") {
      const edit = document.createElement("button");
      edit.textContent = "✏️";
      edit.onclick = async () => {
        const np = prompt("Nouveau mot de passe", u.pass);
        const ne = prompt("Nouvel email", u.email || "");
        if (!np) return;
        await updateDoc(doc(db, "users", d.id), { pass: np, email: ne });
        afficherUtilisateurs();
      };
      const del = document.createElement("button");
      del.textContent = "🗑️";
      del.onclick = async () => {
        if (confirm("Supprimer " + d.id + " ?")) {
          await deleteDoc(doc(db, "users", d.id));
          afficherUtilisateurs();
        }
      };
      li.append(edit, del);
    }
    ul.appendChild(li);
  });
}

// === Perfil ===
async function chargerProfil() {
  if (!currentUser) return;
  const ref = doc(db, "users", currentUser);
  const snap = await getDoc(ref);
  if (!snap.exists()) return;
  const data = snap.data();
  document.getElementById("profilId").textContent = currentUser;
  document.getElementById("profilRole").textContent = currentRole;
  document.getElementById("profilEmail").value = data.email || "";

  const histSnap = await getDocs(collection(db, "historique"));
  const missions = histSnap.docs.map(d => d.data())
    .filter(m => m.user === currentUser)
    .sort((a, b) => (b.startedAt || 0) - (a.startedAt || 0))
    .slice(0, 3);

  const ul = document.getElementById("profilMissions");
  ul.innerHTML = missions.length
    ? missions.map(m => `<li>${m.medicament} ×${m.quantite} — ${m.service} (${m.etat})</li>`).join("")
    : "<li>Aucune mission récente.</li>";
}

async function updateProfil() {
  if (!currentUser) return alert("Non connecté");
  const email = document.getElementById("profilEmail").value.trim();
  const pass = document.getElementById("profilPass").value.trim();
  const ref = doc(db, "users", currentUser);
  const updates = {};
  if (email) updates.email = email;
  if (pass) updates.pass = pass;
  await updateDoc(ref, updates);
  alert("✅ Profil mis à jour !");
  document.getElementById("profilPass").value = "";
}

console.log("✅ Partie 1 chargée");
// === TransCare — app.js (Parte 2) ==========================

const SERVICES = [
  "Urgences","Réanimation","Cardiologie","Pneumologie",
  "Chirurgie Digestive","Chirurgie Orthopédique","Gynécologie",
  "Néonatologie","Urologie","Neurologie","Dermatologie",
  "Endocrinologie","Hépato-Gastro-Entérologie","Néphrologie",
  "Gériatrie","Psychiatrie","Radiologie","Pharmacie",
  "Laboratoire","Bloc opératoire"
];

async function populateMedicaments() {
  const sel = document.getElementById("medicament");
  if (!sel) return;
  sel.innerHTML = "";
  const snap = await getDocs(collection(db, "stock"));
  const meds = snap.docs.map(d => d.id).sort((a, b) => a.localeCompare(b, "fr"));
  meds.forEach(n => {
    const o = document.createElement("option");
    o.value = n; o.textContent = n;
    sel.appendChild(o);
  });
}

function populateServices() {
  const sel = document.getElementById("service");
  if (!sel) return;
  sel.innerHTML = "";
  SERVICES.forEach(s => {
    const o = document.createElement("option");
    o.value = s; o.textContent = s;
    sel.appendChild(o);
  });
}

function filtrerMedicaments() {
  const term = (document.getElementById("searchMed")?.value || "").toLowerCase();
  const sel = document.getElementById("medicament");
  if (!sel) return;
  Array.from(sel.options).forEach(opt => {
    opt.hidden = !opt.textContent.toLowerCase().includes(term);
  });
}

// === Stock ===
let stockChart = null;

async function afficherStock() {
  const ul = document.getElementById("stockList");
  const canvas = document.getElementById("stockChart");
  if (!ul || !canvas) return;
  ul.innerHTML = "";
  const snap = await getDocs(collection(db, "stock"));
  const meds = snap.docs.map(d => ({ id: d.id, ...d.data() }))
    .sort((a, b) => a.id.localeCompare(b.id, "fr"));

  meds.forEach(m => {
    const li = document.createElement("li");
    const warn = m.qte < m.stockMin ? " ⚠️" : "";
    li.innerHTML = `<strong>${m.id}</strong> — ${m.qte} unités (min ${m.stockMin})${warn}`;
    if (currentRole === "admin") {
      const editBtn = document.createElement("button");
      editBtn.textContent = "✏️";
      editBtn.onclick = async () => {
        const newQte = parseInt(prompt("Nouvelle quantité :", m.qte), 10);
        if (!isNaN(newQte)) await updateDoc(doc(db, "stock", m.id), { qte: newQte });
        afficherStock();
      };
      li.append(editBtn);
    }
    ul.appendChild(li);
  });

  if (window.Chart && currentRole === "admin") {
    const ctx = canvas.getContext("2d");
    if (stockChart) stockChart.destroy();
    stockChart = new Chart(ctx, {
      type: "bar",
      data: { labels: meds.map(m => m.id),
        datasets: [{ label: "Quantité disponible", data: meds.map(m => m.qte), backgroundColor: "#2ecc71aa" }] },
      options: { responsive: true, scales: { y: { beginAtZero: true } } }
    });
  }
}

async function reapprovisionnementAuto() {
  if (currentRole !== "admin") return alert("Accès réservé");
  const snap = await getDocs(collection(db, "stock"));
  for (const d of snap.docs) {
    const data = d.data();
    if (data.qte < data.stockMin)
      await updateDoc(doc(db, "stock", d.id), { qte: data.stockMin });
  }
  alert("🚚 Réapprovisionnement simulé !");
  afficherStock();
}


// === Envoyer une mission (pour tous les rôles) ===
// === Envoyer une mission (pour tous les rôles) ===
async function envoyerMission() {
  if (!currentUser) return alert("Connectez-vous d'abord");

  const med = document.getElementById("medicament").value;
  const q = parseInt(document.getElementById("quantite").value, 10) || 0;
  const serv = document.getElementById("service").value;
  const type = document.getElementById("tipoPedido").value;

  if (!med || !q || !serv) return alert("Champs manquants");

  const ref = doc(db, "stock", med);
  const snap = await getDoc(ref);
  if (!snap.exists()) return alert("Médicament introuvable");
  const data = snap.data();

  if (data.qte < q) return alert("Stock insuffisant !");
  await updateDoc(ref, { qte: data.qte - q });

  // 💰 Récupère le prix et calcule le total
  const prix = Number(data.prix || 0);
  const total = prix * q;

  // ⏱️ Temps estimé selon le type
  const tempsEstime =
    type === "tresUrgent" ? 4 :
    type === "urgent" ? 8 : 15;

  // 📦 Structure de la mission
  missionActive = {
    user: currentUser,
    medicament: med,
    quantite: q,
    prix,
    total,
    service: serv,
    type,
    etat: "en cours",
    tempsEstime,
    startedAt: Date.now()
  };

  // 🔄 Enregistre la mission dans l’historique
  await addDoc(collection(db, "historique"), missionActive);

  alert(`Mission envoyée (${type}) — ETA estimé ${tempsEstime} min`);
  showScreen("suivi");
  initMap(); // dessine la route
}

// === Historique ===
async function afficherHistorique() {
  const ul = document.getElementById("historiqueList");
  ul.innerHTML = "";
  const snap = await getDocs(collection(db, "historique"));
  let arr = snap.docs.map(d => ({ id: d.id, ...d.data() }));
  arr = arr.filter(h => (h.etat || "").toLowerCase() === "livré");
  if (currentRole !== "admin") arr = arr.filter(h => h.user === currentUser);
  arr.sort((a, b) => (b.startedAt || 0) - (a.startedAt || 0));

  document.getElementById("deleteNotice").textContent =
    currentRole === "admin" ? "🛠️ Vous pouvez supprimer ou vider l’historique." : "";
  if (!arr.length) return ul.innerHTML = "<li>Aucune mission livrée.</li>";

  arr.forEach(h => {
    const d = new Date(h.startedAt);
    const li = document.createElement("li");
    li.textContent = `${d.toLocaleString()} — ${h.user} — ${h.medicament} ×${h.quantite} — ${h.service} (${h.etat})`;
    if (currentRole === "admin") {
      const delBtn = document.createElement("button");
      delBtn.textContent = "🗑️";
      delBtn.onclick = async () => {
        if (confirm("Supprimer cette mission ?")) {
          await deleteDoc(doc(db, "historique", h.id));
          afficherHistorique();
        }
      };
      li.append(delBtn);
    }
    ul.appendChild(li);
  });
}

async function viderHistorique() {
  if (currentRole !== "admin") return alert("Accès refusé");
  if (!confirm("Voulez-vous vraiment vider tout l’historique ?")) return;

  try {
    // 🧹 1️⃣ Suppression de tous les documents de l’historique
    const snap = await getDocs(collection(db, "historique"));
    for (const d of snap.docs) {
      await deleteDoc(doc(db, "historique", d.id));
    }

    // 📊 2️⃣ Réinitialisation des statistiques
    const statsRef = doc(db, "statistiques", "global");
    await setDoc(statsRef, {
      totalMissions: 0,
      totalLivrées: 0,
      chiffreAffaires: 0,
      dernierMedicament: "-",
      dernierType: "-",
      dateMaj: new Date().toISOString()
    });

    alert("🧹 Historique vidé et statistiques réinitialisées !");
    afficherHistorique();
  } catch (e) {
    console.error("Erreur lors du vidage :", e);
    alert("❌ Une erreur est survenue lors du vidage de l’historique.");
  }
}

// === Statistiques ===
let statsChart = null;
async function genererStats() {
  if (currentRole !== "admin") return alert("Accès réservé");
  const snap = await getDocs(collection(db, "historique"));
  const meds = {};
  snap.docs.forEach(d => {
    const m = d.data().medicament;
    meds[m] = (meds[m] || 0) + (d.data().quantite || 1);
  });
  const top = Object.entries(meds).sort((a, b) => b[1] - a[1]).slice(0, 8);
  const labels = top.map(t => t[0]), values = top.map(t => t[1]);
  const canvas = document.getElementById("statsChart");
  if (!canvas || !window.Chart) return;
  const ctx = canvas.getContext("2d");
  if (statsChart) statsChart.destroy();
  statsChart = new Chart(ctx, {
    type: "bar",
    data: { labels, datasets: [{ label: "Quantité utilisée", data: values, backgroundColor: "#2ecc71aa" }] },
    options: { responsive: true, scales: { y: { beginAtZero: true } } }
  });
}

console.log("✅ Partie 2 chargée");
// === TransCare — app.js (Parte 3) ==========================
// === TransCare — app.js (Partie 3 : Simulation Drone + Rapport PDF) ==========================

// État global du drone
let map, droneMarker, routeLine;
let path = [], stepIndex = 0, timer = null;
let missionActive = null;

// Base (pharmacie)
const BASE = { lat: 48.8389, lng: 2.3676 };

// Points fixes du CHU
const POINTS = {
  "Pharmacie": [48.8391, 2.3689],
  "Urgences": [48.8397, 2.3655],
  "Bloc opératoire": [48.8382, 2.3661],
  "Réanimation": [48.8402, 2.3668],
  "Radiologie": [48.8389, 2.3639],
  "Cardiologie": [48.8406, 2.3647],
  "Gériatrie": [48.8413, 2.3691],
  "Laboratoire": [48.8393, 2.3695],
  "Neurologie": [48.8408, 2.3674],
  "Psychiatrie": [48.8415, 2.3660],
  "Pneumologie": [48.8399, 2.3635]
};

// Routes principales
const ROUTES = {
  "Urgences": ["Pharmacie", "Urgences"],
  "Réanimation": ["Pharmacie", "Réanimation"],
  "Cardiologie": ["Pharmacie", "Cardiologie"]
};

// Point pseudo-aléatoire pour services non listés
function pseudoPoint(name) {
  let h = 0;
  for (let i = 0; i < name.length; i++) h = (h * 31 + name.charCodeAt(i)) >>> 0;
  const dx = ((h % 100) - 50) / 4000;
  const dy = ((Math.floor(h / 100) % 100) - 50) / 4000;
  return [BASE.lat + dy, BASE.lng + dx];
}

// === Initialiser la carte ===
function initMap() {
  const svc = missionActive?.service || "Urgences";
  const dest = POINTS[svc] || pseudoPoint(svc);

  if (!map) {
    map = L.map("map").setView([BASE.lat, BASE.lng], 16);
    window._leafletMap = map;
    L.tileLayer("https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png", {
      attribution: "© OpenStreetMap"
    }).addTo(map);
  }

  // Nettoyer ancienne route
  if (droneMarker) map.removeLayer(droneMarker);
  if (routeLine) map.removeLayer(routeLine);

  const leg = ROUTES[svc] || ["Pharmacie", svc];
  path = [POINTS["Pharmacie"], ...leg.map(n => POINTS[n] || pseudoPoint(n)), dest];

  routeLine = L.polyline(path, { color: "#27ae60", weight: 3 }).addTo(map);

  // Marqueurs visibles pour tous les rôles
  path.forEach((pt, i) => {
    const label =
      i === 0 ? "🏠 Base" :
      i === path.length - 1 ? `🏁 ${svc}` :
      `🚩 Étape ${i}/${path.length - 1}`;
    L.marker(pt).addTo(map).bindPopup(label);
  });

  droneMarker = L.marker(path[0]).addTo(map).bindPopup("🚁 Drone prêt").openPopup();
  stepIndex = 0;
  map.setView(path[0], 16);

  document.getElementById("suiviStatus").textContent =
    "Itinéraire prêt. Appuyez sur ▶️ Lancer la simulation.";
}

// === Déplacement du drone ===
function moveOneStep() {
  if (!path.length) return;
  const total = path.length - 1;

  if (stepIndex >= total) return finishMission();

  stepIndex++;
  const next = path[stepIndex];
  droneMarker.setLatLng(next)
    .bindPopup(`🚁 Étape ${stepIndex}/${total}`).openPopup();
  map.setView(next, 16);
  document.getElementById("suiviStatus").textContent =
    `En route… Étape ${stepIndex}/${total}`;
}

// === Fin de mission ===
async function finishMission() {
  stopSim();
  if (!missionActive) return;

  // Calcul du temps écoulé (en minutes)
  const elapsed = Math.max(
    1,
    Math.round((Date.now() - (missionActive.startedAt || Date.now())) / 60000)
  );

  // Marquer la mission comme livrée
  missionActive.etat = "livré";
  missionActive.tempsReel = elapsed;

  try {
    // Récupère la mission "en cours" dans Firestore
    const snap = await getDocs(collection(db, "historique"));
    const docs = snap.docs.filter(
      d =>
        d.data().user === missionActive.user &&
        d.data().medicament === missionActive.medicament &&
        d.data().etat === "en cours"
    );

    if (docs.length) {
      // ✅ Met à jour la mission existante
      await updateDoc(doc(db, "historique", docs[0].id), {
        etat: "livré",
        tempsReel: elapsed,
        prix: missionActive.prix || 0,
        total: missionActive.total || (missionActive.quantite * (missionActive.prix || 0))
      });
    } else {
      // ✅ Sinon, ajoute une nouvelle entrée livrée
      await addDoc(collection(db, "historique"), {
        ...missionActive,
        etat: "livré",
        tempsReel: elapsed,
        prix: missionActive.prix || 0,
        total: missionActive.total || (missionActive.quantite * (missionActive.prix || 0))
      });
    }

    // 🔹 Met à jour les statistiques globales
    await majStatistiques(missionActive);

    // 🔹 Message de confirmation
    document.getElementById("suiviStatus").textContent =
      `✅ Livraison terminée en ${elapsed} min (estimé ${missionActive.tempsEstime})`;

    missionActive = null;
    afficherHistorique();
    showScreen("historique");
  } catch (e) {
    console.error("Erreur finishMission:", e);
    alert("Erreur lors de la mise à jour de la mission.");
  }
}

// === Mise à jour automatique des statistiques ===
async function majStatistiques(mission) {
  try {
    const statsRef = doc(db, "statistiques", "global");
    const snap = await getDoc(statsRef);
    const data = snap.exists() ? snap.data() : {
      totalMissions: 0,
      totalLivrées: 0,
      chiffreAffaires: 0
    };

    // 🧮 Mise à jour des valeurs
    const nouveauTotal = data.totalMissions + 1;
    const nouveauLivrées =
      (mission.etat === "livré") ? data.totalLivrées + 1 : data.totalLivrées;
    const nouveauCA = data.chiffreAffaires + (mission.total || 0);

    await setDoc(statsRef, {
      totalMissions: nouveauTotal,
      totalLivrées: nouveauLivrées,
      chiffreAffaires: nouveauCA,
      dernierMedicament: mission.medicament || "-",
      dernierType: mission.type || "-",
      dateMaj: new Date().toISOString()
    }, { merge: true });

    console.log("📊 Statistiques mises à jour !");
  } catch (e) {
    console.error("Erreur majStatistiques:", e);
  }
}

// === Simulation du vol ===
function startSim() {
  stopSim();
  document.getElementById("btnSimu").textContent = "⏸️ Pause";
  timer = setInterval(moveOneStep, 2500); // 2,5 s par étape
}

function stopSim() {
  if (timer) clearInterval(timer);
  timer = null;
  document.getElementById("btnSimu").textContent = "▶️ Lancer la simulation";
}

function toggleSimulation() {
  if (!path.length) return alert("Aucun itinéraire défini.");
  timer ? stopSim() : startSim();
}

// === PDF réservé aux admins — missions livrées uniquement ===
// === PDF réservé aux admins — missions livrées uniquement ===
async function genererPDF() {
  try {
    if (currentRole !== "admin") {
      alert("Accès refusé : seul un administrateur peut générer le rapport PDF.");
      return;
    }

    const snap = await getDocs(collection(db, "historique"));
    if (snap.empty) return alert("Aucune donnée dans l'historique !");

    // Filtrer uniquement les missions livrées
    const data = snap.docs
      .map(d => d.data())
      .filter(h => (h.etat || "").toLowerCase() === "livré");

    if (!data.length) return alert("Aucune mission livrée à inclure !");

    // Calcul du total global
    const totalGlobal = data.reduce(
      (sum, h) => sum + ((h.total ?? (h.quantite * (h.prix ?? 0))) || 0),
      0
    );

    // Contenu du tableau
    const histRows = data
      .sort((a, b) => (b.startedAt || 0) - (a.startedAt || 0))
      .map(h => [
        new Date(h.startedAt || Date.now()).toLocaleString(),
        h.user || "-",
        h.medicament || "-",
        String(h.quantite ?? 0),
        h.service || "-",
        h.type || "-",
        (h.prix ?? 0).toFixed(2) + " €",
        ((h.total ?? (h.quantite * (h.prix ?? 0))) || 0).toFixed(2) + " €",
        h.etat || "-"
      ]);

    // === Définition du PDF ===
    const docDefinition = {
      pageOrientation: "landscape", // ✅ Affichage horizontal
      pageMargins: [40, 100, 40, 70],
      header: {
        margin: [40, 20, 40, 0],
        columns: [
          { text: "EPISEN – TransCare", fontSize: 14, bold: true, color: "#27ae60" },
          { text: "Rapport des Missions Livrées", alignment: "center", fontSize: 13, bold: true },
          { text: new Date().toLocaleDateString("fr-FR"), alignment: "right", fontSize: 10 }
        ]
      },
      footer: (currentPage, pageCount) => ({
        columns: [
          { text: "TransCare © EPISEN – Prototype médical universitaire", alignment: "left", margin: [40, 0, 0, 0], fontSize: 9, color: "#555" },
          { text: `Page ${currentPage} / ${pageCount}`, alignment: "right", margin: [0, 0, 40, 0], fontSize: 9, color: "#555" }
        ]
      }),
      content: [
        { text: "RAPPORT DES MISSIONS LIVRÉES", style: "title" },
        {
          text: `Généré le ${new Date().toLocaleString()}\nAdministrateur : ${currentUser || "-"}`,
          style: "subtitle"
        },
        { text: "📋 Historique des missions livrées", style: "section" },
        {
          table: {
            headerRows: 1,
            // ✅ Largeurs fixes pour éviter la coupure du tableau
            widths: [80, 70, 100, 35, 100, 60, 60, 70, 60],
            body: [
              [
                { text: "Date", style: "tableHeader" },
                { text: "Utilisateur", style: "tableHeader" },
                { text: "Médicament", style: "tableHeader" },
                { text: "Qté", style: "tableHeader" },
                { text: "Service", style: "tableHeader" },
                { text: "Type", style: "tableHeader" },
                { text: "Prix (€)", style: "tableHeader" },
                { text: "Total (€)", style: "tableHeader" },
                { text: "État", style: "tableHeader" }
              ],
              ...histRows,
              [
                { text: "", colSpan: 7 }, {}, {}, {}, {}, {}, {},
                { text: "TOTAL GLOBAL", bold: true },
                { text: totalGlobal.toFixed(2) + " €", bold: true }
              ]
            ]
          },
          layout:"lightHorizontalLines"
        },
        { text: "", margin: [0, 30, 0, 10] },
        { text: "Signature numérique :", style: "section", decoration: "underline" },
        {
          text: "Document généré automatiquement par le système TransCare.\nAucune modification manuelle n’a été apportée.",
          style: "signature"
        },
        {
          text: "Responsable technique : Équipe TransCare – EPISEN 2025",
          style: "footerNote"
        }
      ],
      styles: {
        title: { fontSize: 20, bold: true, alignment: "center", color: "#27ae60", margin: [0, 10, 0, 10] },
        subtitle: { fontSize: 11, italics: true, alignment: "center", margin: [0, 0, 0, 15] },
        section: { fontSize: 14, bold: true, margin: [0, 10, 0, 8], color: "#2c3e50" },
        tableHeader: { bold: true, fillColor: "#ecf0f1" },
        signature: { fontSize: 10, italics: true, color: "#555" },
        footerNote: { fontSize: 9, color: "#888", alignment: "center" }
      }
    };

    // ✅ Génération du fichier PDF
    pdfMake.createPdf(docDefinition).download("TransCare_Rapport_Livrees.pdf");
  } catch (e) {
    console.error("Erreur PDF:", e);
    alert("Erreur lors de la génération du rapport PDF.");
  }
}

// === Exposition globale ===
window.login = login;
window.logout = logout;
window.showScreen = showScreen;
window.updateProfil = updateProfil;
window.addUser = addUser;
window.afficherUtilisateurs = afficherUtilisateurs;
window.genererStats = genererStats;
window.afficherStock = afficherStock;
window.reapprovisionnementAuto = reapprovisionnementAuto;
window.viderHistorique = viderHistorique;
window.envoyerMission = envoyerMission;
window.toggleSimulation = toggleSimulation;
window.initMap = initMap;
window.filtrerMedicaments = filtrerMedicaments;
window.genererPDF = genererPDF;

console.log("✅ TransCare — Simulation et PDF finalisés avec étapes 1/n");
