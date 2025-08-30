self.addEventListener("install",e=>self.skipWaiting());
self.addEventListener("activate",e=>{e.waitUntil((async()=>{try{const k=await caches.keys();await Promise.all(k.map(caches.delete));await self.registration.unregister()}finally{const cs=await self.clients.matchAll({type:"window"});for(const c of cs)c.navigate(c.url)}})())});
