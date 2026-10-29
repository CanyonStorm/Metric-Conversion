const cachePrefix = `metric-converter:${self.registration.scope}:`;
const cacheName = `${cachePrefix}v1`;
const assetPaths = [
  "./", "./index.html", "./styles.css", "./app.mjs", "./converter.mjs",
  "./manifest.webmanifest", "./icon.svg", "./icons/apple-touch-icon.png",
  "./icons/icon-192.png", "./icons/icon-512.png",
];
const assetURLs = new Set(assetPaths.map((path) => new URL(path, self.registration.scope).href));

self.addEventListener("install", (event) => {
  event.waitUntil(caches.open(cacheName).then((cache) => cache.addAll([...assetURLs])));
});

self.addEventListener("activate", (event) => {
  event.waitUntil((async () => {
    const names = await caches.keys();
    await Promise.all(names.filter((name) => name.startsWith(cachePrefix) && name !== cacheName)
      .map((name) => caches.delete(name)));
    await self.clients.claim();
  })());
});

self.addEventListener("fetch", (event) => {
  if (event.request.method !== "GET") return;
  const url = new URL(event.request.url);
  // Ignore query strings on app navigations, but never intercept other sites or paths.
  const isAppNavigation = event.request.mode === "navigate"
    && (url.origin + url.pathname === self.registration.scope
      || url.origin + url.pathname === new URL("./index.html", self.registration.scope).href);
  if (!isAppNavigation && !assetURLs.has(url.href)) return;
  event.respondWith((async () => {
    const cache = await caches.open(cacheName);
    const cached = await cache.match(isAppNavigation ? self.registration.scope : event.request);
    return cached || fetch(event.request);
  })());
});
