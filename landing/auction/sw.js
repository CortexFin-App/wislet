const VERSION="auction-v1";
self.addEventListener("install",e=>self.skipWaiting());
self.addEventListener("activate",e=>e.waitUntil(self.clients.claim()));
self.addEventListener("fetch",(e)=>{const u=new URL(e.request.url);if(!u.pathname.startsWith("/auction"))return;if(e.request.method!=="GET")return;if(u.pathname.startsWith("/assets/")){e.respondWith((async()=>{const c=await caches.open(VERSION);const x=await c.match(e.request);if(x)return x;const r=await fetch(e.request);if(r&&r.ok)c.put(e.request,r.clone());return r})())}});
