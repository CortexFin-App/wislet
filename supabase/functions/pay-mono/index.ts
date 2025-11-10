// @ts-nocheck
/// <reference lib="deno.ns" />

// Створення посилання на оплату в monobank: повертає { checkout_url }
const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const MONO_TOKEN   = Deno.env.get("MONO_TOKEN")!;
const PUBLIC_BASE  = Deno.env.get("PUBLIC_BASE") || "https://cortexfinapp.com";
const FUNCTIONS_BASE = `${SUPABASE_URL.replace(".supabase.co","")}.functions.supabase.co`;

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST,OPTIONS",
  "Access-Control-Allow-Headers": "content-type"
};

async function getPriceCents(tier:"PF"|"GF"|"SE"){
  if (tier==='PF') return 150000;
  if (tier==='GF') return 75000;
  return 6900;
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  if (req.method !== "POST") return new Response("Method Not Allowed", { status: 405, headers: cors });

  try {
    const { hold_id, tier, email } = await req.json();
    if (!hold_id || !tier || !email) return new Response("Bad request", { status: 400, headers: cors });

    const amount = await getPriceCents(tier);
    const orderId = `hold-${hold_id}-${Date.now()}`;

    // Дивись актуальний endpoint/структуру в доках mono (invoice/link)
    const payload:any = {
      amount: amount,     // у центах/копійках — перевір у твоєму тарифі
      ccy: 840,           // USD (980 для UAH)
      merchantPaymInfo: {
        reference: orderId,
        destination: `${tier} Founder`,
        comment: `hold_${hold_id}_${tier}`
      },
      redirectUrl: `${PUBLIC_BASE}/thanks.html`,
      webHookUrl: `${FUNCTIONS_BASE}/mono-webhook`
    };

    const r = await fetch("https://api.monobank.ua/api/merchant/invoice/create", {
      method: "POST",
      headers: { "X-Token": MONO_TOKEN, "Content-Type": "application/json" },
      body: JSON.stringify(payload)
    });
    const j = await r.json();
    if (!j?.pageUrl) {
      console.error("mono create error", j);
      return new Response(JSON.stringify({ error: "mono error" }), { status: 400, headers: cors });
    }

    return new Response(JSON.stringify({ checkout_url: j.pageUrl }), {
      headers: { ...cors, "Content-Type": "application/json" }
    });

  } catch (e) {
    console.error("pay-mono fatal", e);
    return new Response(JSON.stringify({ error: String(e) }), { status: 500, headers: cors });
  }
});
