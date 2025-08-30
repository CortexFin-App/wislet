// @ts-nocheck
// Публічні утиліти (без дублювання createHold/buy)

function emailLooksValid(email) {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(String(email).trim());
}

function disableButton(btn, v = true) {
  if (!btn) return;
  btn.disabled = v;
  btn.style.opacity = v ? 0.6 : 1;
  btn.style.pointerEvents = v ? "none" : "auto";
}

function money(u) { return '$' + (Number(u||0)/100).toLocaleString('en-US', {maximumFractionDigits:2}); }
function skuToTierKey(s){ return String(s).startsWith('PF') ? 'PF' : String(s); }

const EDGE_HEADERS = () => ({
  "Authorization": `Bearer ${window.SUPABASE_ANON}`,
  "apikey": window.SUPABASE_ANON
});

// UTM helpers
const UTM_SS_KEY = "__utm__";
(function parseAndStoreUTM(){
  try{
    const u = new URL(location.href);
    const utm = {
      source:   u.searchParams.get("utm_source"),
      medium:   u.searchParams.get("utm_medium"),
      campaign: u.searchParams.get("utm_campaign"),
      content:  u.searchParams.get("utm_content"),
      term:     u.searchParams.get("utm_term"),
    };
    if (Object.values(utm).some(Boolean)){
      sessionStorage.setItem(UTM_SS_KEY, JSON.stringify(utm));
    }
  }catch(_){}
})();
window.getUTM = function(){
  try{ return JSON.parse(sessionStorage.getItem(UTM_SS_KEY) || "{}"); }
  catch(_){ return {}; }
};

// Нічого платіжного тут не лишаємо — вся логіка в index.html
