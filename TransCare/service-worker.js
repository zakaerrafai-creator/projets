// === service-worker.js ===
// Permet à TransCare de fonctionner hors-ligne et d'être installable

const CACHE_NAME = "transcare-cache-v1";
const urlsToCache = [
  "/",
  "/index.html",
  "/app.js",
  "/manifest.json",
  "/icons/EPISEN.png"
];

// 📦 Installer le cache
self.addEventListener("install", (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => {
      console.log("📦 Mise en cache des fichiers...");
      return cache.addAll(urlsToCache);
    })
  );
});

// 🔁 Répondre avec le cache si offline
self.addEventListener("fetch", (event) => {
  event.respondWith(
    caches.match(event.request).then((response) => {
      return response || fetch(event.request);
    })
  );
});

// 🧹 Mise à jour du cache
self.addEventListener("activate", (event) => {
  event.waitUntil(
    caches.keys().then((cacheNames) =>
      Promise.all(
        cacheNames.map((name) => {
          if (name !== CACHE_NAME) {
            console.log("🧹 Suppression ancien cache :", name);
            return caches.delete(name);
          }
        })
      )
    )
  );
});
