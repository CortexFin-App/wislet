<script>
// ga-init.js — єдиний підключуваний файл для GA4
(function () {
  var tag = document.currentScript;
  var GA_ID   = (tag && tag.dataset && tag.dataset.gaid) || "";
  var PV      = (tag && tag.dataset && tag.dataset.pageview) === "true";
  var DNT     = (navigator.doNotTrack == "1" || window.doNotTrack == "1" || navigator.msDoNotTrack == "1");
  var isAdmin = /(^|\/)(admin|admin-)/i.test(location.pathname); // не трекаємо адмін URI

  // Стуби, щоб виклики не падали, якщо GA вимкнено
  window.dataLayer = window.dataLayer || [];
  window.gtag = window.gtag || function(){ dataLayer.push(arguments); };
  window.gaTrack = window.gaTrack || function(name, params){ try{ gtag('event', name, params||{}); }catch(e){} };

  if (!GA_ID || DNT || isAdmin) return; // шануємо DNT та не логимо адмін

  var s = document.createElement('script');
  s.async = true;
  s.src = 'https://www.googletagmanager.com/gtag/js?id=' + encodeURIComponent(GA_ID);
  document.head.appendChild(s);

  gtag('consent','default',{
    ad_user_data:'denied',
    ad_personalization:'denied',
    ad_storage:'denied',
    analytics_storage:'granted'
  });
  gtag('js', new Date());
  gtag('config', GA_ID, { send_page_view: PV });
})();
</script>
