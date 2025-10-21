// @ts-nocheck
/// <reference lib="deno.ns" />

// Приймає callback від monobank і викликає admin-manual-convert
const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const ADMIN_KEY    = Deno.env.get("ADMIN_EXPORT_KEYS")!;
const FUNCTIONS_BASE = `${SUPABASE_URL.replace(".supabase.co","")}.functions.supabase.co`;

// TODO: валідація X-Signature за докою mono (якщо ввімкнена)
function verifyMono(_req:Request, _body:any){ return true; }

Deno.serve(async (req) => {
  try {
    const body = await req.json();
    if (!verifyMono(req, body)) return new Response("bad signature", { status: 400 });

    const orderId = body?.invoiceId || body?.orderId || "";
    const status  = body?.status || body?.state || "";
    const amount  = Number(body?.amount || 0);
    const currency= (body?.ccyName || "USD").toLowerCase();

    // ти передавав hold_id у comment/reference: "hold_21_GF"
    let hold_id = null, tier = null;
    try {
      const c = String(body?.merchantPaymInfo?.comment || body?.reference || "");
      const m = c.match(/hold_(\d+)_([A-Z]{2})/);
      if (m) { hold_id = Number(m[1]); tier = m[2]; }
    } catch {}

    if (!hold_id || status.toLowerCase() !== "success") return new Response("ignored", { status: 200 });

    const r = await fetch(`${FUNCTIONS_BASE}/admin-manual-convert`, {
      method: "POST",
      headers: { "content-type":"application/json", "x-admin-key": ADMIN_KEY },
      body: JSON.stringify({
        hold_id,
        tier: tier || "GF",
        provider: "monobank",
        tx_id: orderId,
        amount_cents: amount,
        currency
      })
    });

    if (!r.ok) {
      console.error("convert failed", await r.text());
      return new Response("convert failed", { status: 500 });
    }
    return new Response("ok", { status: 200 });

  } catch (e) {
    console.error("mono-webhook fatal", e);
    return new Response("err", { status: 500 });
  }
});
