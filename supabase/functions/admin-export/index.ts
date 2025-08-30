// @ts-nocheck
import { serve } from "https://deno.land/std@0.224.0/http/server.ts";

const ADMIN_TOKEN  = Deno.env.get("ADMIN_TOKEN") ?? "";
const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SRV_KEY =
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ??
  Deno.env.get("SERVICE_ROLE_KEY") ?? "";

const CORS = {
  "access-control-allow-origin": "*",
  "access-control-allow-methods": "GET,OPTIONS",
  "access-control-allow-headers": "authorization,apikey,content-type,x-admin-token",
};

function J(txt: string, status=200, extra: Record<string,string> = {}) {
  return new Response(txt, { status, headers: { ...CORS, ...extra }});
}
function json(x: unknown, status=200){ return J(JSON.stringify(x), status, { "content-type":"application/json" }); }

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

const tierFromBatch = (b?: number|null) => b===1?"PF":b===2?"GF":b===5?"SE":"";
const isoStart=(d:string)=> new Date(`${d}T00:00:00.000Z`).toISOString();
const isoEnd  =(d:string)=> new Date(`${d}T23:59:59.999Z`).toISOString();
const dayKey=(iso:string)=> new Date(iso).toISOString().slice(0,10);
function weekKey(iso: string){
  const d = new Date(iso);
  const day = (d.getUTCDay()+6)%7;
  const mon = new Date(Date.UTC(d.getUTCFullYear(), d.getUTCMonth(), d.getUTCDate()-day));
  return mon.toISOString().slice(0,10);
}

serve(async (req) => {
  if (req.method === "OPTIONS") return new Response(null, { headers: CORS });
  if (!ADMIN_TOKEN || req.headers.get("x-admin-token") !== ADMIN_TOKEN) {
    return new Response("forbidden", { status: 403, headers: CORS });
  }

  try{
    const u = new URL(req.url);
    const toY   = (new Date()).toISOString().slice(0,10);
    const fromY = new Date(Date.now()-30*24*3600*1000).toISOString().slice(0,10);
    const fromISO = isoStart(u.searchParams.get("from") || fromY);
    const toISO   = isoEnd  (u.searchParams.get("to")   || toY);
    const group   = (u.searchParams.get("group")||"day").toLowerCase()==="week" ? "week" : "day";
    const metric  = (u.searchParams.get("metric")||"orders").toLowerCase()==="revenue" ? "revenue" : "orders";
    const tierQ   = (u.searchParams.get("tier")||"all").toUpperCase(); // PF|GF|SE|ALL

    const orders = await pg(`orders?select=id,tier,batch_id,amount_cents,created_at,is_test&created_at=gte.${fromISO}&created_at=lte.${toISO}&is_test=eq.false`);
    const rows = orders.map((o:any)=>({created_at:o.created_at, amount_cents:Number(o.amount_cents||0), tier:(o.tier || tierFromBatch(o.batch_id) || "")}))
                       .filter((o:any)=> !["PF","GF","SE"].includes(tierQ) ? true : (o.tier===tierQ));

    const key = group==="week" ? weekKey : dayKey;
    const agg = new Map<string,{PF:number;GF:number;SE:number}>();
    for(const r of rows){
      const k = key(r.created_at);
      const bucket = agg.get(k) ?? {PF:0,GF:0,SE:0};
      const plus = metric==="revenue" ? r.amount_cents/100 : 1;
      if(r.tier==="PF") bucket.PF += plus; else if(r.tier==="GF") bucket.GF += plus; else if(r.tier==="SE") bucket.SE += plus;
      agg.set(k, bucket);
    }
    const keys = Array.from(agg.keys()).sort();

    const single = ["PF","GF","SE"].includes(tierQ);
    const header = single ? `period,${metric}\n` : `period,PF_${metric},GF_${metric},SE_${metric}\n`;
    const body = keys.map(k=>{
      const b = agg.get(k) || {PF:0,GF:0,SE:0};
      if(single){ const v=(b as any)[tierQ]||0; return `${k},${Math.round(v*100)/100}`; }
      return `${k},${Math.round(b.PF*100)/100},${Math.round(b.GF*100)/100},${Math.round(b.SE*100)/100}`;
    }).join("\n");

    const filename = `export_${metric}_${group}_${(tierQ||'all').toLowerCase()}.csv`;
    return J(header+body, 200, {
      "content-type":"text/csv; charset=utf-8",
      "content-disposition":`attachment; filename="${filename}"`
    });
  }catch(e){
    console.error('admin-export error:', e?.message||e);
    return json({ok:false,error:String(e?.message||e)}, 500);
  }
});
