// @ts-nocheck
/// <reference lib="deno.ns" />
import Stripe from "npm:stripe@14.25.0";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const stripe = new Stripe(Deno.env.get("STRIPE_SECRET_KEY")!, { apiVersion: "2024-06-20" });
const supabase = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);

// CORS (публічний, але тільки POST/OPTIONS)
const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST,OPTIONS",
  "Access-Control-Allow-Headers": "content-type",
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: CORS });
  if (req.method !== "POST") return new Response("Method Not Allowed", { status: 405, headers: CORS });

  try {
    const body = await req.json().catch(() => ({}));
    const session_id = body?.session_id || new URL(req.url).searchParams.get("session_id");
    if (!session_id) return new Response(JSON.stringify({ error: "session_id required" }), { status: 400, headers: CORS });

    const s = await stripe.checkout.sessions.retrieve(session_id);
    const paid = s?.status === "complete" && s?.payment_status === "paid";
    const holdId = Number((s?.metadata as any)?.hold_id || 0);

    if (!paid || !holdId) {
      return new Response(JSON.stringify({ ok: false, error: "not paid or hold not found" }), { status: 200, headers: CORS });
    }

    // дістаємо картку, видану вебхуком
    const { data: card, error } = await supabase
      .from("founder_cards")
      .select("id, founder_id, tier")
      .eq("hold_id", holdId)
      .maybeSingle();

    if (error) {
      console.error("confirm-checkout query error", error);
      return new Response(JSON.stringify({ ok: false, error: error.message }), { status: 200, headers: CORS });
    }

    return new Response(JSON.stringify({ ok: true, card }), { headers: { ...CORS, "Content-Type": "application/json" } });
  } catch (e) {
    console.error("confirm-checkout crash", e);
    return new Response(JSON.stringify({ ok: false, error: String(e) }), { status: 200, headers: CORS });
  }
});
