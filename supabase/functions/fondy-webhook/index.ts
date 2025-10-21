// @ts-nocheck
/// <reference lib="deno.ns" />

// Приймає серверний callback від Fondy і викликає admin-manual-convert
const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const ADMIN_KEY    = Deno.env.get("ADMIN_EXPORT_KEYS")!;
const FONDY_SECRET = Deno.env.get("FONDY_SECRET")!;
const FUNCTIONS_BASE = `${SUPABASE_URL.replace(".supabase.co","")}.functions.supabase.co`;

// TODO: перевірка підпису відповідно до доки Fondy
function verifyFondySignature(_body:any, _secret:string)
{
  return true; // заміни на реальну перевірку
}

Deno.serve(async (req) => 
  {
  try {
    const body = await req.json();
    if (!verifyFondySignature(body, FONDY_SECRET)) return new Response("bad signature", { status: 400 });

    const md = body?.payment?.merchant_data || body?.request?.merchant_data;
    let hold_id = null, tier = null;

    try 
    {
      const obj = typeof md === "string" ? JSON.parse(md) : md;
      hold_id = obj?.hold_id;
      tier = obj?.tier;
    } 
    catch {}

    const tx_id = body?.payment?.order_id || body?.request?.order_id;
    const amount_cents = Number(body?.payment?.amount || body?.request?.amount || 0);
    const currency = (body?.payment?.currency || body?.request?.currency || "USD").toLowerCase();
    const status = body?.payment?.order_status || body?.request?.order_status;

    if (!hold_id || !tier || status !== "approved") return new Response("ignored", { status: 200 });

    const r = await fetch(`${FUNCTIONS_BASE}/admin-manual-convert`, 
      {
      method: "POST",
      headers: { "content-type":"application/json", "x-admin-key": ADMIN_KEY },
      body: JSON.stringify({
        hold_id,
        tier,
        provider: "fondy",
        tx_id,
        amount_cents,
        currency
      })
    });
    if (!r.ok) 
      {
      console.error("convert failed", await r.text());
      return new Response("convert failed", { status: 500 });
    }
    return new Response("ok", { status: 200 });

  } 
  catch (e) 
  {
    console.error("fondy-webhook fatal", e);
    return new Response("err", { status: 500 });
  }
});
