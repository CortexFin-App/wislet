// @ts-nocheck
import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import postgres from "https://deno.land/x/postgresjs@v3.4.5/mod.js";

const ADMIN_TOKEN = Deno.env.get("ADMIN_TOKEN")!;
const PG_URL = Deno.env.get("SUPABASE_DB_URL")!;

serve(async (req) => {
  if ((req.headers.get("x-admin-token")||"") !== ADMIN_TOKEN)
    return new Response("forbidden", { status: 403 });

  const url = new URL(req.url);
  const N = Math.max(1, Math.min(500, Number(url.searchParams.get("n")||"50")));
  const from = url.searchParams.get("from") || "1970-01-01";
  const to   = url.searchParams.get("to")   || "2100-01-01";

  const sql = postgres(PG_URL, { prepare: true });

  // беремо пінги у діапазоні та перше замовлення після пінгу
  const rows = await sql/*sql*/`
    WITH pinged AS (
      SELECT h.hold_id, lower(h.email) AS email, h.chased_at
      FROM holds h
      WHERE h.chased = true AND h.chased_at IS NOT NULL
        AND h.chased_at::date BETWEEN ${from}::date AND ${to}::date
    ),
    ordered AS (
      SELECT p.hold_id, p.email, p.chased_at,
             min(o.created_at) AS first_order_at,
             min(o.tier) AS tier
      FROM pinged p
      JOIN orders o ON lower(o.email)=p.email AND o.created_at >= p.chased_at
      WHERE o.created_at::date BETWEEN ${from}::date AND ${to}::date
        AND (o.status = 'paid' OR o.status IS NULL)
      GROUP BY p.hold_id, p.email, p.chased_at
    )
    SELECT hold_id, email, tier,
           chased_at, first_order_at,
           round( EXTRACT(epoch FROM (first_order_at - chased_at))/60.0 )::int AS minutes
    FROM ordered
    ORDER BY first_order_at DESC
    LIMIT ${N};
  `;

  await sql.end();
  return new Response(JSON.stringify({ items: rows }), { headers:{ "content-type":"application/json" }});
});
