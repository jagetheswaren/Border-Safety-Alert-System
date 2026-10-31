// Intentionally do not cache authenticated pages, API results, GPS, AI or map tiles.
self.addEventListener('install', () => self.skipWaiting());
self.addEventListener('activate', event => event.waitUntil(self.clients.claim()));
self.addEventListener('fetch', event => {
  if (event.request.mode !== 'navigate' || new URL(event.request.url).origin !== self.location.origin) return;
  event.respondWith(fetch(event.request).catch(() => new Response('<!doctype html><html lang="en"><meta name="viewport" content="width=device-width,initial-scale=1"><title>BSAS — Offline</title><body style="background:#090d16;color:white;font:18px system-ui;padding:32px"><h1>BSAS is offline</h1><p>Reconnect to load live maps, safety data and AI.</p><p>No current safety status can be confirmed here.</p><button onclick="location.reload()">Retry connection</button></body></html>', { headers: { 'Content-Type': 'text/html; charset=utf-8' } })));
});
