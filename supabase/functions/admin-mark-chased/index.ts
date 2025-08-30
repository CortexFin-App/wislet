// @ts-nocheck
import { serve } from "https://deno.land/std@0.224.0/http/server.ts";

const ADMIN_TOKEN  = Deno.env.get("ADMIN_TOKEN") ?? "";
const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SRV_KEY =
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ??
  Deno.env.get("SERVICE_ROLE_KEY") ?? "";

const CORS = {
  "access-control-allow-origin":"*",
  "access-control-allow-methods":"POST,OPTIONS",
  "access-control-allow-headers":"authorization,apikey,content-type,x-admin-token",
  "content-type":"application/json",
};

function J(x: unknown, status=200){ return new Response(JSON.stringify(x), {status, headers:CORS}); }

async function pg(path: string, init: RequestInit = {}) {
  if (!SUPABASE_URL || !SRV_KEY) throw new Error("env-missing SUPABASE_URL/SERVICE_ROLE_KEY");
  const r = await fetch(`${SUPABASE_URL}/rest/v1/${path}`, {
    ...init,
    headers:{
      ...(init.headers||{}),
      apikey: SRV_KEY,
      authorization:`Bearer ${SRV_KEY}`,
      "content-type":"application/json",
      prefer:"return=representation",
    }
  });
  const txt=await r.text();
  if(!r.ok) throw new Error(`postgrest ${r.status}: ${txt}`);
  try{ return JSON.parse(txt); }catch{ return txt; }
}

/** rate-limit: до 30 запитів за 10s по токену/IP */
const RL_WINDOW = 10_000, RL_MAX = 30;
const bucket = new Map<string, {n:number, t:number}>();
const kReq = (r:Request)=> (r.headers.get("x-admin-token")||"")+":"+(r.headers.get("x-forwarded-for")||"");
const okRate = (r:Request)=>{ const k=kReq(r), now=Date.now(), cur=bucket.get(k); if(!cur||now-cur.t>RL_WINDOW){bucket.set(k,{n:1,t:now});return true;} if(cur.n>=RL_MAX)return false; cur.n++; return true; };

serve(async (req) => {
  if (req.method === "OPTIONS") return new Response(null, { headers: CORS });
  if (!ADMIN_TOKEN || req.headers.get("x-admin-token") !== ADMIN_TOKEN) {
    return J({ok:false,error:"forbidden"}, 403);
  }
  if (!okRate(req)) return J({ok:false,error:"rate_limited"}, 429);
  try{
    const body = await req.json();
    const id = Number(body.hold_id);
    const mark = !!body.mark;
    if(!id) throw new Error("hold_id required");

    const patch:any = mark ? { chased:true, chased_at: new Date().toISOString() } : { chased:false, chased_at: null };
    const res = await pg(`holds?id=eq.${id}`, { method:"PATCH", body: JSON.stringify(patch) });
    return J({ok:true, updated: res?.length ?? 0});
  }catch(e){
    console.error("admin-mark-chased error", e?.message||e);
    return J({ok:false,error:String(e?.message||e)}, 500);
  }
});
