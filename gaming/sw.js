/* Offline support for walkerwagoner.com/gaming.
   App pages come from the cache instantly and refresh in the background,
   so a new version shows up on the next visit. Campaign data always comes live from Supabase. */
const CACHE = "gaming-v1";
const CORE = ["./", "./manifest.webmanifest", "./icons/icon.svg", "./icons/icon-192.png", "./icons/icon-512.png",
  "./malediction/", "./oak-and-iron/", "./oak-and-iron-solo/", "./firefight/", "./firefight-solo/",
  "./campaign/", "./config.js", "./vendor/supabase.js"];

self.addEventListener("install", e => {
  e.waitUntil(caches.open(CACHE).then(c => c.addAll(CORE)).then(() => self.skipWaiting()));
});
self.addEventListener("activate", e => {
  e.waitUntil(caches.keys().then(keys => Promise.all(keys.filter(k => k.startsWith("gaming-") && k !== CACHE).map(k => caches.delete(k))))
    .then(() => self.clients.claim()));
});
self.addEventListener("fetch", e => {
  const req = e.request, url = new URL(req.url);
  if (req.method !== "GET") return;
  if (url.hostname.endsWith("supabase.co") || url.hostname.endsWith("supabase.in")) return;
  const sameOrigin = url.origin === location.origin;
  const fonts = /fonts\.(googleapis|gstatic)\.com$/.test(url.hostname);
  if (!sameOrigin && !fonts) return;
  if (sameOrigin && !url.pathname.startsWith(new URL(self.registration.scope).pathname)) return;
  // config.js: network first so connection changes apply right away
  if (sameOrigin && url.pathname.endsWith("/config.js")) {
    e.respondWith(fetch(req).then(r => { const copy = r.clone(); caches.open(CACHE).then(c => c.put(req, copy)); return r; })
      .catch(() => caches.match(req)));
    return;
  }
  // everything else: cache first, refresh in the background
  e.respondWith(caches.open(CACHE).then(async c => {
    const hit = await c.match(req, { ignoreSearch: sameOrigin && req.mode === "navigate" });
    const net = fetch(req).then(r => { if (r && (r.ok || r.type === "opaque")) c.put(req, r.clone()); return r; }).catch(() => null);
    if (hit) { e.waitUntil(net); return hit; }
    const r = await net;
    return r || new Response("Offline and not cached yet.", { status: 503, headers: { "Content-Type": "text/plain" } });
  }));
});
