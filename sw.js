const C='cerita-kita-v14';
const SHELL=['./','index.html','config.js','manifest.webmanifest','apple-touch-icon.png','icon-192.png','icon-512.png','login-bg.jpg'];
self.addEventListener('install',e=>{e.waitUntil(caches.open(C).then(c=>c.addAll(SHELL)));self.skipWaiting()});
self.addEventListener('activate',e=>{e.waitUntil(caches.keys().then(ks=>Promise.all(ks.filter(k=>k!==C).map(k=>caches.delete(k)))));self.clients.claim()});
self.addEventListener('fetch',e=>{
  if(e.request.method!=='GET')return;
  const u=new URL(e.request.url);
  const cacheable=u.origin===location.origin||/fonts\.(googleapis|gstatic)\.com$|cdn\.jsdelivr\.net$/.test(u.hostname);
  if(!cacheable)return; // data & foto Supabase selalu langsung dari server
  // network-first untuk file aplikasi supaya update langsung terpakai, fallback cache saat offline
  e.respondWith(fetch(e.request).then(r=>{if(r.ok||r.type==='opaque'){const cp=r.clone();caches.open(C).then(c=>c.put(e.request,cp))}return r}).catch(()=>caches.match(e.request)));
});
