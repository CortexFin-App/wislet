// /auction/sw.js — SW тільки для /auction/*
// Нічого не перехоплює поза /auction/, мінімально кешує /assets/

const VERSION = 'auction-v1';

self.addEventListener('install', (e) => self.skipWaiting());
self.addEventListener('activate', (e) => e.waitUntil(self.clients.claim()));

self.addEventListener('fetch', (e) => {
  const url = new URL(e.request.url);

  // Поза /auction — взагалі ігноруємо
  if (!url.pathname.startsWith('/auction')) return;
  if (e.request.method !== 'GET') return;

  // Дуже легкий cache-first лише для статичних ассетів
  if (url.pathname.startsWith('/assets/')) {
    e.respondWith((async () => {
      const cache = await caches.open(VERSION);
      const cached = await cache.match(e.request);
      if (cached) return cached;

      const res = await fetch(e.request);
      if (res && res.ok) cache.put(e.request, res.clone());
      return res;
    })());
  }
});
