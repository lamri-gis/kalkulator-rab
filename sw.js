/* ACC-RAB service worker - Kalkulator RAB Desa by Lamri, S.P. */
const CACHE = "acc-rab-v1";
const SHELL = ["/", "/manifest.json", "/icon-192.png", "/icon-512.png", "/icon-maskable-512.png", "/apple-touch-icon.png"];

self.addEventListener("install", (e) => {
  e.waitUntil(caches.open(CACHE).then((c) => c.addAll(SHELL)).then(() => self.skipWaiting()));
});

self.addEventListener("activate", (e) => {
  e.waitUntil(
    caches.keys().then((keys) => Promise.all(keys.filter((k) => k !== CACHE).map((k) => caches.delete(k))))
      .then(() => self.clients.claim())
  );
});

self.addEventListener("fetch", (e) => {
  const req = e.request;
  const url = new URL(req.url);
  /* hanya GET dari situs ini; Supabase, admin, dan lainnya selalu langsung ke internet */
  if (req.method !== "GET" || url.origin !== location.origin || url.pathname.startsWith("/admin")) return;

  if (req.mode === "navigate") {
    /* halaman: utamakan versi terbaru, pakai cache hanya jika offline */
    e.respondWith(
      fetch(req).then((res) => {
        const copy = res.clone();
        caches.open(CACHE).then((c) => c.put("/", copy));
        return res;
      }).catch(() => caches.match("/"))
    );
    return;
  }
  /* ikon & berkas statis: cache dulu */
  e.respondWith(caches.match(req).then((hit) => hit || fetch(req)));
});
