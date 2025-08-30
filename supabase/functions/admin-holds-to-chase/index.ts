// @ts-nocheck
// // GET /admin-holds-to-chase?min_age=10&limit=200
// GET /admin-holds-to-chase?min_age=10&limit=200
// Перевіряє x-admin-token, тягне дані з view admin_v_holds_to_chase
import { serve } from "https://deno.land/std@0.224.0/http/server.ts";

const ADMIN_TOKEN = Deno.env.get("ADMIN_TOKEN") ?? "";
const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const ANON = Deno.env.get("SUPABASE_ANON_KEY") ?? "";

function corsHeaders(origin: string | null) {
  return {
    "Access-Control-Allow-Origin": origin || "*",
    "Vary": "Origin",
    "Access-Control-Allow-Methods": "GET,OPTIONS",
    "Access-Control-Allow-Headers": "authorization,apikey,x-admin-token,content-type",
    "Content-Type": "application/json; charset=utf-8",
  };
}

serve(async (req) => {
  const origin = req.headers.get("origin") || null;

  // preflight
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders(origin) });
  }

  // auth
  const token = req.headers.get("x-admin-token") ?? "";
  if (!ADMIN_TOKEN || token !== ADMIN_TOKEN) {
    return new Response(JSON.stringify({ error: "forbidden" }), {
      status: 403, headers: corsHeaders(origin),
    });
  }

  const url = new URL(req.url);
  const minAge = Math.max(0, Number(url.searchParams.get("min_age") ?? "10"));
  const limit  = Math.min(500, Math.max(1, Number(url.searchParams.get("limit") ?? "200")));

  // поріг за created_at
  const threshold = new Date(Date.now() - minAge * 60000).toISOString();

  // REST-запит на view: created_at < threshold, order desc, limit
  const viewUrl =
    `${SUPABASE_URL}/rest/v1/admin_v_holds_to_chase` +
    `?select=hold_id,email,batch_id,created_at,expires_at` +
    `&created_at=lt.${encodeURIComponent(threshold)}` +
    `&order=created_at.desc&limit=${limit}`;

  const resp = await fetch(viewUrl, {
    headers: {
      "apikey": ANON,
      "Authorization": `Bearer ${ANON}`,
      "Accept": "application/json",
    },
  });

  if (!resp.ok) {
    const t = await resp.text().catch(() => "");
    return new Response(JSON.stringify({ error: "db", details: t }), {
      status: 500, headers: corsHeaders(origin),
    });
  }

  const rows = await resp.text(); // вже JSON
  return new Response(rows, { headers: corsHeaders(origin) });
});
