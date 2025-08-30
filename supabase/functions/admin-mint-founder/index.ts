// @ts-nocheck
// Deno / Supabase Edge Function: admin-mint-founder
// POST { email, tier, order_id? }
// Присвоює наступний founder_id для tier (PF/GF/SE) і створює запис у founder_cards.
// Не вимагає email-поля в таблиці (працює і без email_mask/email/email1).

import { serve } from "https://deno.land/std@0.224.0/http/server.ts";

const ADMIN_TOKEN  = Deno.env.get("ADMIN_TOKEN") ?? "";
const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SRV_KEY =
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ??
  Deno.env.get("SERVICE_ROLE_KEY") ?? "";

const CORS = {
  "access-control-allow-origin": "*",
  "access-control-allow-methods": "GET,POST,OPTIONS",
  "access-control-allow-headers": "authorization,apikey,content-type,x-admin-token",
  "content-type": "application/json",
};

function J(x: unknown, status = 200) {
  return new Response(JSON.stringify(x), { status, headers: CORS });
}

function maskEmail(e: string) {
  const [u, d] = String(e).toLowerCase().split("@");
  if (!u || !d) return e;
  const head = u.slice(0, 2);
  const tail = u.slice(-1);
  return `${head}***${tail}@${d}`;
}

async function pg(path: string, init: RequestInit = {}) {
  if (!SUPABASE_URL || !SRV_KEY) throw new Error("env-missing SUPABASE_URL/SERVICE_ROLE_KEY");
  const r = await fetch(`${SUPABASE_URL}/rest/v1/${path}`, {
    ...init,
    headers: {
      ...(init.headers || {}),
      apikey: SRV_KEY,
      authorization: `Bearer ${SRV_KEY}`,
      "content-type": "application/json",
      prefer: "return=representation",
    },
  });
  const txt = await r.text();
  if (!r.ok) throw new Error(`postgrest ${r.status}: ${txt}`);
  try { return JSON.parse(txt); } catch { return txt as unknown; }
}

serve(async (req) => {
  if (req.method === "OPTIONS") return new Response(null, { headers: CORS });
  if (!ADMIN_TOKEN || req.headers.get("x-admin-token") !== ADMIN_TOKEN) {
    return new Response("forbidden", { status: 403, headers: CORS });
  }

  try {
    const b = await req.json().catch(()=> ({}));
    const emailRaw = String(b.email || "").trim().toLowerCase();
    const tier  = String(b.tier  || "").trim().toUpperCase();
    const order_id = Number.isFinite(Number(b.order_id)) ? Number(b.order_id) : null;

    if (!tier) return J({ ok:false, error:"tier required (PF/GF/SE)" }, 400);

    // 1) Знайти останній founder_id по tier
    const rows = await pg(
      `founder_cards?select=founder_id&tier=eq.${encodeURIComponent(tier)}&order=founder_id.desc&limit=1`
    );
    const last = Array.isArray(rows) && rows[0]?.founder_id ? Number(rows[0].founder_id) : 0;

    // 2) Спроби вставки:
    //    - без timestamp-полів (issued_at/created_at хай ставить БД)
    //    - email-поле необов'язкове: пробуємо email_mask → email → email1 → без email
    const base: any = { tier, founder_id: last + 1 };
    if (order_id !== null) base.order_id = order_id;

    const emailMasked = emailRaw ? maskEmail(emailRaw) : null;
    const emailCandidates = [
      emailMasked ? { email_mask: emailMasked } : null,
      emailRaw    ? { email: emailRaw }        : null,
      emailRaw    ? { email1: emailRaw }       : null,
      {}, // без email взагалі
    ].filter(Boolean) as any[];

    async function tryInsert(payload: any) {
      const ins = await pg("founder_cards", { method: "POST", body: JSON.stringify(payload) });
      return Array.isArray(ins) ? ins[0] : ins;
    }

    let rec: any = null;
    let lastErr: unknown = null;

    // Невеличкий захист від гонок: якщо трапиться 23505, пробуємо наступний founder_id 1-2 рази
    for (let bump = 0; bump < 3; bump++) {
      for (const e of emailCandidates) {
        try {
          rec = await tryInsert({ ...base, founder_id: base.founder_id + bump, ...e });
          if (rec) return J({ ok:true, founder: rec });
        } catch (err: any) {
          lastErr = err;
          // якщо дублікат — пробуємо більший founder_id
          if (String(err).includes("23505")) break;
        }
      }
    }

    throw lastErr ?? new Error("insert failed");
  } catch (e) {
    return J({ ok:false, error: String(e?.message || e) }, 500);
  }
});
