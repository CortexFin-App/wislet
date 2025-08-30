// @ts-nocheck
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
const J = (x:unknown, status=200)=> new Response(JSON.stringify(x), {status, headers:CORS});

async function pg(path: string, init: RequestInit = {}) {
  if (!SUPABASE_URL || !SRV_KEY) throw new Error("env-missing SUPABASE_URL/SERVICE_ROLE_KEY");
  const r = await fetch(`${SUPABASE_URL}/rest/v1/${path}`, {
    ...init,
    headers: { ...(init.headers||{}), apikey: SRV_KEY, authorization:`Bearer ${SRV_KEY}`, "content-type":"application/json", prefer:"return=representation" },
  });
  const t = await r.text();
  if (!r.ok) throw new Error(`postgrest ${r.status}: ${t}`);
  try { return JSON.parse(t); } catch { return t as unknown; }
}

const tierFromBatch = (b?:number|null)=> b===1?'PF':b===2?'GF':b===5?'SE':'';
const isoStart = (ymd: string) => new Date(`${ymd}T00:00:00.000Z`).toISOString();
const isoEnd   = (ymd: string) => new Date(`${ymd}T23:59:59.999Z`).toISOString();
const dayKey   = (iso: string) => new Date(iso).toISOString().slice(0,10);
function makeDayRange(fromISO: string, toISO: string){
  const days:string[]=[]; const d0=new Date(fromISO), d1=new Date(toISO);
  let d=new Date(Date.UTC(d0.getUTCFullYear(), d0.getUTCMonth(), d0.getUTCDate()));
  const end=new Date(Date.UTC(d1.getUTCFullYear(), d1.getUTCMonth(), d1.getUTCDate()));
  while(d.getTime()<=end.getTime()){ days.push(d.toISOString().slice(0,10)); d=new Date(d.getTime()+86400000); }
  return days;
}

serve(async (req)=>{
  if (req.method==="OPTIONS") return new Response(null, {headers:CORS});
  if (!ADMIN_TOKEN || req.headers.get("x-admin-token")!==ADMIN_TOKEN) return new Response("forbidden", {status:403, headers:CORS});

  try{
    const u=new URL(req.url);
    const toY=(new Date()).toISOString().slice(0,10);
    const fromY=new Date(Date.now()-30*24*3600*1000).toISOString().slice(0,10);
    const fromISO=isoStart(u.searchParams.get("from")||fromY);
    const toISO  =isoEnd  (u.searchParams.get("to")  ||toY);
    const N = Math.max(1, Math.min(200, Number(u.searchParams.get("n")||30)));

    const holdsCreated = await pg(`holds?select=id,email,batch_id,chased,chased_at,created_at&created_at=gte.${fromISO}&created_at=lte.${toISO}`);
    const holdsPinged  = await pg(`holds?select=id,batch_id,chased_at,created_at&chased_at=gte.${fromISO}&chased_at=lte.${toISO}`);
    const orders       = await pg(`orders?select=id,hold_id,tier,batch_id,email,amount_cents,created_at,is_test&created_at=gte.${fromISO}&created_at=lte.${toISO}&is_test=eq.false`);
    const founders     = await pg(`founder_cards?select=id,tier,issued_at,is_test&issued_at=gte.${fromISO}&issued_at=lte.${toISO}&is_test=eq.false`);

    const mk=()=>({ holds:0,pinged:0,orders:0,founders:0,revenue_cents:0,conv_after_ping_count:0,
      avg_minutes_ping_to_convert:null as number|null,_sum_min_ping_to_convert:0,_n_ping_to_convert:0,
      avg_minutes_hold_age_at_convert:null as number|null,_sum_min_hold_age:0,_n_hold_age:0
    });
    const byTier:Record<string,ReturnType<typeof mk>>={PF:mk(),GF:mk(),SE:mk()};

    for(const h of holdsCreated){ const t=tierFromBatch(h.batch_id); if(byTier[t]) byTier[t].holds++; }
    for(const h of holdsPinged){ const t=tierFromBatch(h.batch_id); if(byTier[t]) byTier[t].pinged++; }
    for(const o of orders){ const t=(o.tier || tierFromBatch(o.batch_id) || ""); if(byTier[t]){ byTier[t].orders++; byTier[t].revenue_cents += Number(o.amount_cents||0); } }
    for(const f of founders){ const t=f.tier || ""; if(byTier[t]) byTier[t].founders++; }

    const ordersByHold=new Map<number,any[]>(); const orderHoldIds:number[]=[];
    for(const o of orders){ if(o.hold_id != null){ const arr=ordersByHold.get(o.hold_id) ?? []; arr.push(o); ordersByHold.set(o.hold_id, arr); orderHoldIds.push(o.hold_id); } }

    const holdsMap=new Map<number, any>();
    for (const h of holdsCreated) holdsMap.set(h.id, h);
    for (const h of holdsPinged)  holdsMap.set(h.id, h);
    const missing = Array.from(new Set(orderHoldIds)).filter(id => !holdsMap.has(id));
    for (let i=0;i<missing.length;i+=200){
      const chunk = missing.slice(i,i+200);
      if (!chunk.length) break;
      const rows = await pg(`holds?select=id,batch_id,created_at,chased_at&id=in.(${chunk.join(",")})`);
      for (const h of rows) holdsMap.set(h.id, h);
    }

    const days=makeDayRange(fromISO,toISO);
    const makeTs=()=>({orders:new Array(days.length).fill(0), revenue_cents:new Array(days.length).fill(0), conv_after_ping:new Array(days.length).fill(0)});
    const ts: Record<string, ReturnType<typeof makeTs>> = { PF: makeTs(), GF: makeTs(), SE: makeTs() };
    const dayIndex=(iso:string)=> Math.max(0, Math.min(days.length-1, days.indexOf(dayKey(iso))));

    for(const o of orders){
      const t=(o.tier || tierFromBatch(o.batch_id) || "");
      const idx=dayIndex(o.created_at);
      if(ts[t]){ ts[t].orders[idx]+=1; ts[t].revenue_cents[idx]+=Number(o.amount_cents||0); }
    }

    let totalMinPingConv=0, totalPingConvN=0, totalConvAfterPing=0;
    let totalAgeMin=0, totalAgeN=0;
    const timeline:Array<{hold_id:number,tier:string,email?:string, ping_at:string, convert_at:string, minutes:number, hold_age_minutes:number}>=[];

    const holdAgeSum:number[] = new Array(days.length).fill(0);
    const holdAgeCnt:number[] = new Array(days.length).fill(0);

    for(const h of holdsPinged){
      const arr=(ordersByHold.get(h.id)||[]).sort((a,b)=> new Date(a.created_at).getTime()-new Date(b.created_at).getTime());
      if(!arr.length) continue;
      const pingAt=new Date(h.chased_at).getTime();

      let best:any = null;
      for (const o of arr) { const t = new Date(o.created_at).getTime(); if (t>=pingAt) { best=o; break; } }
      if (best) {
        const tConv=new Date(best.created_at).getTime();
        const min = (tConv - pingAt)/60000;
        totalConvAfterPing++; totalMinPingConv += min; totalPingConvN++;

        const tier=(best.tier ?? tierFromBatch(best.batch_id) ?? tierFromBatch(h.batch_id));
        if(byTier[tier]){ byTier[tier]._sum_min_ping_to_convert += min; byTier[tier]._n_ping_to_convert++; byTier[tier].conv_after_ping_count++; }

        const hold = holdsMap.get(h.id);
        const holdAgeMin = hold?.created_at ? (tConv - new Date(hold.created_at).getTime())/60000 : null;
        if (holdAgeMin != null) { totalAgeMin += holdAgeMin; totalAgeN++; if (byTier[tier]) { byTier[tier]._sum_min_hold_age += holdAgeMin; byTier[tier]._n_hold_age++; } }

        const idx=dayIndex(best.created_at);
        if (ts[tier]) ts[tier].conv_after_ping[idx] += 1;
        if (holdAgeMin != null) { holdAgeSum[idx] += holdAgeMin; holdAgeCnt[idx] += 1; }

        timeline.push({
          hold_id: h.id, tier, email: best.email || "",
          ping_at: new Date(h.chased_at).toISOString(),
          convert_at: new Date(best.created_at).toISOString(),
          minutes: Math.round(min*10)/10,
          hold_age_minutes: holdAgeMin==null?0:Math.round(holdAgeMin*10)/10
        });
      }
    }

    Object.keys(byTier).forEach(t => {
      const b = byTier[t];
      b.avg_minutes_ping_to_convert =
        b._n_ping_to_convert ? Math.round((b._sum_min_ping_to_convert / b._n_ping_to_convert)*10)/10 : null;
      b.avg_minutes_hold_age_at_convert =
        b._n_hold_age ? Math.round((b._sum_min_hold_age / b._n_hold_age)*10)/10 : null;
      delete b._sum_min_ping_to_convert; delete b._n_ping_to_convert;
      delete b._sum_min_hold_age; delete b._n_hold_age;
    });

    const pingedTotal=holdsPinged.length;
    const revenueTotal=Object.values(byTier).reduce((s, v) => s + v.revenue_cents, 0);
    const avgPingToConv = totalPingConvN ? Math.round((totalMinPingConv/totalPingConvN)*10)/10 : null;
    const avgHoldAgeAtConv = totalAgeN ? Math.round((totalAgeMin/totalAgeN)*10)/10 : null;

    const holdAgeAvgByDay = days.map((_,i)=> holdAgeCnt[i]? +(holdAgeSum[i]/holdAgeCnt[i]).toFixed(1) : 0);

    timeline.sort((a,b)=> new Date(b.convert_at).getTime() - new Date(a.convert_at).getTime());
    const recent = timeline.slice(0, N);

    return J({
      ok: true,
      range: { from: fromISO, to: toISO },
      counts: { holds: holdsCreated.length, pinged: pingedTotal, orders: orders.length, founders: founders.length },
      revenue_cents_total: revenueTotal,
      by_tier: byTier,
      conversion_after_ping: {
        total_converted: totalConvAfterPing,
        rate: pingedTotal ? +((totalConvAfterPing*100/pingedTotal).toFixed(1)) : null,
        avg_minutes_ping_to_convert: avgPingToConv,
      },
      kpi_avg_minutes_hold_age_at_convert: avgHoldAgeAtConv,
      recent_conversions: recent,
      series: {
        periods: days,
        conv: { PF: ts.PF.conv_after_ping, GF: ts.GF.conv_after_ping, SE: ts.SE.conv_after_ping },
        rev:  { PF: ts.PF.revenue_cents,   GF: ts.GF.revenue_cents,   SE: ts.SE.revenue_cents   },
        extra:{ avg_hold_age_minutes: holdAgeAvgByDay }
      }
    });
  } catch (e) {
    console.error("admin-stats error:", e?.message || e);
    return J({ ok:false, error:String(e?.message || e) }, 500);
  }
});
