// @ts-nocheck
import { serve } from "https://deno.land/std@0.224.0/http/server.ts";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SRV_KEY =
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ??
  Deno.env.get("SERVICE_ROLE_KEY") ?? "";

const CORS = {
  "access-control-allow-origin": "*",
  "access-control-allow-methods": "GET,OPTIONS",
  "access-control-allow-headers": "authorization,apikey,content-type",
  "content-type": "application/json",
};

function J(x: unknown, status = 200) {
  return new Response(JSON.stringify(x), { status, headers: CORS });
}

function maskEmail(e: string) {
  const [u, d] = String(e || "").toLowerCase().split("@");
  if (!u || !d) return "";
  return `${u.slice(0,1)}***@${d}`;
}

async function pg(path: string) {
  const r = await fetch(`${SUPABASE_URL}/rest/v1/${path}`, {
    headers: {
      apikey: SRV_KEY,
      authorization: `Bearer ${SRV_KEY}`,
      "content-type": "application/json",
    },
  });
  const txt = await r.text();
  if (!r.ok) throw new Error(`postgrest ${r.status}: ${txt}`);
  return JSON.parse(txt);
}

serve(async (req) => {
  if (req.method === "OPTIONS") return new Response(null, { headers: CORS });
  try {
    const url = new URL(req.url);
    const offset = Number(url.searchParams.get("offset") ?? "0");
    const limit  = Math.min(100, Math.max(1, Number(url.searchParams.get("limit") ?? "24")));

    // БЕРЕМО лише наявні у твоїй таблиці: id, founder_id, tier, issued_at, email
    const rows = await pg(
      `founder_cards?select=id,founder_id,tier,issued_at,email&order=issued_at.desc,id.desc&offset=${offset}&limit=${limit}`
    );

    const data = rows.map((r: any) => ({
      card_id:    r.id,
      tier:       r.tier,
      founder_id: r.founder_id,
      issued_at:  r.issued_at ?? null,
      email_mask: maskEmail(r.email ?? ""),
    }));

    return J(data);
  } catch (e) {
    return J({ ok:false, error: String(e?.message || e) }, 500);
  }
});
