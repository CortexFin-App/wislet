
// navbar highlight
const path = location.pathname.replace(/\/index\.html$/, '/').replace(/\/$/, '') || '/';
document.querySelectorAll('.nav a').forEach(a=>{
  const href = a.getAttribute('href');
  if (href && path.includes(href.replace('.html',''))) a.classList.add('active');
});
// Analytics bootstrap from config (set in assets/config.js)
(function(){
  const cfg = window.__CFIN_CONFIG || {};
  if (cfg.GA_MEASUREMENT_ID){
    (function(w,d,s,l,i){w[l]=w[l]||[];w[l].push({'gtm.start':
      new Date().getTime(),event:'gtm.js'});var f=d.getElementsByTagName(s)[0],
      j=d.createElement(s),dl=l!='dataLayer'?'&l='+l:'';j.async=true;j.src=
      'https://www.googletagmanager.com/gtm.js?id='+i+dl;f.parentNode.insertBefore(j,f);
    })(window,document,'script','dataLayer', cfg.GA_MEASUREMENT_ID);
  }
  if (cfg.FB_PIXEL_ID){
    !function(f,b,e,v,n,t,s){if(f.fbq)return;n=f.fbq=function(){n.callMethod?
    n.callMethod.apply(n,arguments):n.queue.push(arguments)};if(!f._fbq)f._fbq=n;
    n.push=n;n.loaded=!0;n.version='2.0';n.queue=[];t=b.createElement(e);t.async=!0;
    t.src=v;s=b.getElementsByTagName(e)[0];s.parentNode.insertBefore(t,s)}(window, document,'script',
    'https://connect.facebook.net/en_US/fbevents.js');
    fbq('init', cfg.FB_PIXEL_ID); fbq('track', 'PageView');
  }
})();
// ---- Auto-wire FORM_ENDPOINT on forms and YouTube embed on hero ----
document.addEventListener('DOMContentLoaded', () => {
  const cfg = window.__CFIN_CONFIG || {};
  // Form endpoint (Mailchimp/Formspree/etc.)
  if (cfg.FORM_ENDPOINT) {
    document.querySelectorAll('form[data-endpoint], form[action="#"]').forEach(form => {
      form.setAttribute('action', cfg.FORM_ENDPOINT);
      if (!form.getAttribute('method')) form.setAttribute('method', 'POST');
    });
  }
  // YouTube hero embed
  if (cfg.YT_VIDEO_ID) {
    const hero = document.querySelector('.hero .hero-media');
    if (hero) {
      const id = String(cfg.YT_VIDEO_ID).trim();
      hero.innerHTML = `<iframe width="100%" height="100%" style="aspect-ratio:16/9;border:0;border-radius:12px" src="https://www.youtube.com/embed/${id}" title="CortexFin demo" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" allowfullscreen></iframe>`;
    }
  }
});
