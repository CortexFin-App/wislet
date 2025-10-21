// @ts-nocheck
/// <reference lib="deno.ns" />

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const FONDY_MERCHANT_ID = Deno.env.get("FONDY_MERCHANT_ID")!;
const FONDY_SECRET = Deno.env.get("FONDY_SECRET")!;
const PUBLIC_BASE = Deno.env.get("PUBLIC_BASE") || "https://cortexfinapp.com";

// ✅ Fixed alert #22: safe FUNCTIONS_BASE
const FUNCTIONS_BASE = `${SUPABASE_URL.replace(".supabase.co", "")}.functions.supabase.co`;

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST,OPTIONS",
  "Access-Control-Allow-Headers": "content-type",
};

async function getPriceCents(tier: "PF" | "GF" | "SE") {
  if (tier === "PF") return 150000;
  if (tier === "GF") return 75000;
  return 6900;
}

function signFondy(payload: any, secret: string) {
  return "TODO_SIGNATURE"; // placeholder
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  if (req.method !== "POST")
    return new Response("Method Not Allowed", { status: 405, headers: cors });

  try {
    const { hold_id, tier, email } = await req.json();
    if (!hold_id || !tier || !email)
      return new Response(
        JSON.stringify({ error: "Bad request" }),
        { status: 400, headers: { ...cors, "Content-Type": "application/json" } }
      );

    const amount = await getPriceCents(tier);
    const order_id = `hold-${hold_id}-${Date.now()}`;

    const request: any = {
      merchant_id: FONDY_MERCHANT_ID,
      order_id,
      amount,
      currency: "USD",
      order_desc: `${tier} Founder`,
      response_url: `${PUBLIC_BASE}/thanks.html`,
      server_callback_url: `https://${FUNCTIONS_BASE}/fondy-webhook`,
      sender_email: email,
      merchant_data: JSON.stringify({ hold_id, tier }),
    };
    request.signature = signFondy(request, FONDY_SECRET);

    const res = await fetch("https://api.fondy.eu/api/checkout/url/", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ request }),
    });

    const json = await res.json();

    if (!json?.response?.checkout_url) {
      console.error("Fondy error", json);
      return new Response(
        JSON.stringify({ error: "Fondy error" }),
        { status: 400, headers: { ...cors, "Content-Type": "application/json" } }
      );
    }

    return new Response(
      JSON.stringify({ checkout_url: json.response.checkout_url }),
      { headers: { ...cors, "Content-Type": "application/json" } }
    );
  } catch (err) {
    console.error("pay-fondy fatal", err);
    return new Response(
      JSON.stringify({ error: String(err) }),
      { status: 500, headers: { ...cors, "Content-Type": "application/json" } }
    );
  }
});
