// Простий SW без кешування POST та без втручання в /admin і крос-оріджин
const CACHE = 'app-v1';

self.addEventListener('install', (e) => {
  e.waitUntil(
    caches.open(CACHE)
      .then(c => c.addAll([
        '/', '/index.html', '/assets/app-icon.png'
        // тільки локальні GET-ресурси
      ]))
      .then(() => self.skipWaiting())
  );
});

self.addEventListener('activate', (e) => {
  e.waitUntil(self.clients.claim());
});

// ЄДИНИЙ fetch-handler
self.addEventListener('fetch', (event) => {
  const req = event.request;
  const url = new URL(req.url);

  // 1) не чіпаємо не-GET
  if (req.method !== 'GET') return;

  // 2) не чіпаємо /admin і взагалі будь-що не з нашого origin (supabase functions тощо)
  if (url.pathname.startsWith('/admin') || url.origin !== self.location.origin) return;

  event.respondWith((async () => {
    const cache = await caches.open(CACHE);
    const cached = await cache.match(req);
    if (cached) return cached;

    const res = await fetch(req).catch(()=> null);
    if (res && res.ok) {
      try { await cache.put(req, res.clone()); } catch(_){}
      return res;
    }
    // якщо мережа впала й кешу немає — просто фейл
    return res || new Response('Offline', { status: 503 });
  })());
});
