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

async function pg(path: string, init: RequestInit = {}) {
  const r = await fetch(`${SUPABASE_URL}/rest/v1/${path}`, {
    ...init,
    headers:{
      ...(init.headers||{}),
      apikey: SRV_KEY,
      authorization:`Bearer ${SRV_KEY}`,
      "content-type":"application/json",
      prefer:"return=representation"
    }
  });
  const txt=await r.text();
  if(!r.ok) throw new Error(`postgrest ${r.status}: ${txt}`);
  try{ return JSON.parse(txt); }catch{ return txt; }
}

serve(async (req) => {
  if (req.method === "OPTIONS") return new Response(null, { headers: CORS });
  if (!ADMIN_TOKEN || req.headers.get("x-admin-token") !== ADMIN_TOKEN) {
    return new Response(JSON.stringify({ok:false,error:'forbidden'}), { status:403, headers:CORS });
  }
  try{
    const body = await req.json();
    const ids: number[] = Array.isArray(body.ids)? body.ids.map(Number).filter(Boolean) : [];
    const mark = !!body.mark;
    if(!ids.length) throw new Error('ids required');
    if(ids.length>200)  throw new Error('too many ids (max 200 per request)');

    const now = new Date().toISOString();
    const inList = ids.join(',');

    const patch:any = mark ? { chased:true, chased_at: now } : { chased:false, chased_at: null };
    const res = await pg(`holds?id=in.(${inList})`, { method:'PATCH', body: JSON.stringify(patch) });

    return new Response(JSON.stringify({ok:true, updated: Array.isArray(res)? res.length: 0}), { headers:CORS });
  }catch(e){
    console.error('admin-mark-chased-bulk error', e?.message||e);
    return new Response(JSON.stringify({ok:false,error:String(e?.message||e)}), { status:500, headers:CORS });
  }
});
