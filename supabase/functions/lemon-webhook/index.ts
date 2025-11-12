// @ts-nocheck
/// <reference lib="deno.ns" />
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

// ── ENV ────────────────────────────────────────────────────────────────────────
// обов'язково додай в функцію (Dashboard → Edge Functions → lemon-webhook → Env):
// SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, ADMIN_KEY (як у /admin-export),
// ANON_PUBLIC (твій anon jwt), LEMON_SIGNING_SECRET (Secret з Lemon Squeezy)
const SUPABASE_URL  = Deno.env.get("SUPABASE_URL")!;
const ADMIN_KEY     = Deno.env.get("ADMIN_KEY")!;
const ANON          = Deno.env.get("ANON_PUBLIC")!;
const LEMON_SECRET  = Deno.env.get("LEMON_SIGNING_SECRET")!;

// ── helpers ───────────────────────────────────────────────────────────────────
function toHex(buf: ArrayBuffer) {
  return [...new Uint8Array(buf)].map(b => b.toString(16).padStart(2, "0")).join("");
}
async function hmacSha256(secret: string, payload: string) {
  const key = await crypto.subtle.importKey(
    "raw",
    new TextEncoder().encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const sig = await crypto.subtle.sign("HMAC", key, new TextEncoder().encode(payload));
  return toHex(sig);
}
function safeEq(a = "", b = "") {
  if (a.length !== b.length) return false;
  let res = 0;
  for (let i = 0; i < a.length; i++) res |= a.charCodeAt(i) ^ b.charCodeAt(i);
  return res === 0;
}
function inferTier(s: string | null | undefined): "PF" | "GF" | "SE" | null {
  const t = (s || "").toLowerCase();
  if (t.includes("platinum") || t.startsWith("pf")) return "PF";
  if (t.includes("gold")     || t.startsWith("gf")) return "GF";
  if (t.includes("silver")   || t.startsWith("se")) return "SE";
  return null;
}
function centsGuess(att: any): number {
  // Lemon віддає total/subtotal як *cents* або є total_formatted / price... Будь-який безпечний фолбек:
  const cand = [
    att?.total, att?.subtotal, att?.total_in_cents, att?.subtotal_in_cents,
    att?.first_order_item?.price, att?.first_order_item?.price_in_cents,
  ].map(Number).find(x => Number.isFinite(x) && x > 0);
  if (!cand) return 0;
  // якщо схоже на долари (< 1e3) — помножимо на 100
  return cand < 1000 ? Math.round(cand * 100) : cand;
}

// ── server ────────────────────────────────────────────────────────────────────
Deno.serve(async (req) => {
  // CORS
  if (req.method === "OPTIONS") {
    return new Response("ok", {
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Methods": "POST,OPTIONS",
        "Access-Control-Allow-Headers": "content-type,x-signature,x-event-name",
      },
    });
  }
  if (req.method !== "POST") return new Response("Method Not Allowed", { status: 405 });

  const raw = await req.text();
  try {
    // 1) verify signature
    const sig  = req.headers.get("x-signature") || req.headers.get("X-Signature") || "";
    const calc = await hmacSha256(LEMON_SECRET, raw);
    if (!safeEq(sig, calc)) {
      console.warn("lemon-webhook: bad signature");
      return new Response(JSON.stringify({ ok: false, error: "bad signature" }), { status: 401 });
    }

    // 2) parse
    const evt = (req.headers.get("x-event-name") || "").toLowerCase(); // напр.: "order_created"
    const body = JSON.parse(raw || "{}");
    const data = body?.data ?? {};
    const att  = data?.attributes ?? {};

    // працюємо тільки з оплаченими / створеними замовленнями
    if (!evt.includes("order")) {
      return new Response(JSON.stringify({ ok: true, note: "ignored event " + evt }), { status: 200 });
    }

    // 3) дістаємо hold_id, email і tier (із кастомних полів checkout)
    const custom = att?.custom || att?.checkout_data?.custom || body?.meta || {};
    const holdId = Number(
      custom?.hold_id ?? custom?.holdId ?? custom?.HOLD_ID ?? att?.first_order_item?.custom?.hold_id ?? 0,
    );
    // на всякий: спроба інферу з назви варіанту/продукту
    const tier = (custom?.tier as string) || att?.variant_name || att?.product_name;
    const tierKey = inferTier(tier) ?? "GF"; // дефолт — GF (зміниш, якщо треба)

    const email = custom?.email || att?.user_email || att?.customer_email || null;
    const txId  = String(att?.identifier ?? att?.order_number ?? data?.id ?? crypto.randomUUID());
    const amount_cents = centsGuess(att);
    const currency = String(att?.currency || "usd").toLowerCase();

    if (!holdId) {
      console.warn("lemon-webhook: no hold_id in payload", { txId, tierKey, email });
      return new Response(JSON.stringify({ ok: true, note: "no hold_id, ignored" }), { status: 202 });
    }

    // 4) Використаємо існуючий бекенд-конвертер (той, що в адмінці) — ідемпотентність по tx_id
    const base = new URL(req.url); // https://xxx.functions.supabase.co/lemon-webhook
    const convertUrl = `${base.origin}/admin-manual-convert`;

    const r = await fetch(convertUrl, {
      method: "POST",
      headers: {
        "content-type": "application/json",
        "x-admin-key": ADMIN_KEY,
        "Authorization": `Bearer ${ANON}`,
        "apikey": ANON,
      },
      body: JSON.stringify({
        hold_id: holdId,
        tier   : tierKey,
        provider: "lemon",
        tx_id  : txId,
        amount_cents,
        currency,
      }),
    });

    const resp = await r.json().catch(() => ({}));
    if (!r.ok) {
      console.error("manual-convert failed", r.status, resp);
      return new Response(JSON.stringify({ ok: false, error: resp?.error || r.status }), { status: 500 });
    }

    return new Response(JSON.stringify({ ok: true, converted: resp }), { status: 200 });
  } catch (e) {
    console.error("lemon-webhook error", e);
    return new Response(JSON.stringify({ ok: false, error: String(e) }), { status: 500 });
  }
});
