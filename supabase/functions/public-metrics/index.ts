// @ts-nocheck
/// <reference lib="deno.ns" />
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const supabase = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
);

// Публічні CORS (дозволяємо і Authorization/apikey — стане в пригоді, якщо verify_jwt=true)
const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET,OPTIONS",
  "Access-Control-Allow-Headers": "content-type,authorization,apikey",
  "Vary": "Origin",
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  if (req.method !== "GET") return new Response("Method Not Allowed", { status: 405, headers: cors });

  try {
    // 1) Базові метрики з admin.v_auction_metrics
    const { data: m, error: mErr } = await supabase
      .schema("admin")
      .from("v_auction_metrics")
      .select("*")
      .single();
    if (mErr) throw mErr;

    // 2) Активні хвилі/ціни з public.sell_batches
    const { data: batches, error: bErr } = await supabase
      .from("sell_batches")
      .select("id,tier,wave,price_cents,quota,is_active")
      .eq("is_active", true)
      .in("tier", ["PF","GF","SE"]);
    if (bErr) throw bErr;

    const pick = (t: string) => (batches || []).filter(x => x.tier === t).sort((a,b)=>a.id-b.id)[0];
    const actPF = pick("PF");
    const actGF = pick("GF");
    const actSE = pick("SE");

    const waveShort = (w?: string|null) => {
      if (!w) return null;
      const m = /Wave\s+([ABC])/i.exec(w);
      return m ? m[1].toUpperCase() : w; // "A/B/C" або залишаємо як є (Early, тощо)
    };

    const payload = {
      // з в’юхи:
      net_cents : Number(m?.net_cents  || 0),
      sold_pf   : Number(m?.sold_pf    || 0),
      sold_gf   : Number(m?.sold_gf    || 0),
      sold_se   : Number(m?.sold_se    || 0),
      quota_pf  : Number(m?.quota_pf   || 0),
      quota_gf  : Number(m?.quota_gf   || 0),
      quota_se  : Number(m?.quota_se   || 0),

      // додатково для фронту:
      gf_wave_raw   : actGF?.wave || null,
      gf_wave_short : waveShort(actGF?.wave) || null,
      gf_price_cents: Number(actGF?.price_cents || 0),

      pf_price_cents: Number(actPF?.price_cents || 0),
      se_price_cents: Number(actSE?.price_cents || 0),
    };

    return new Response(JSON.stringify(payload), {
      headers: { ...cors, "Content-Type": "application/json", "Cache-Control":"public, max-age=15, s-maxage=60" },
    });
  } catch (e) {
    console.error("public-metrics error", e);
    
    // виводимо акуратне повідомлення для користувача
    const msg =
        e instanceof Error
          ? e.message
         : typeof e === "string"
            ? e
            : "Unknown error";

    return new Response(JSON.stringify({ error: msg }), { status: 500, headers: cors });
  }
});
