import { serve } from "std/http/server.ts";
import { createClient } from "@supabase/supabase-js";
import { corsHeaders } from "../_shared/cors.ts";

serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  try {
    const { wallet_id } = await req.json();
    if (!wallet_id) return new Response(JSON.stringify({ error: "wallet_id_required" }), { headers: { ...corsHeaders, "Content-Type": "application/json" }, status: 400 });

    const userClient = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_ANON_KEY")!, { global: { headers: { Authorization: req.headers.get("Authorization")! } } });
    const { data: { user } } = await userClient.auth.getUser();
    if (!user) return new Response(JSON.stringify({ error: "unauthorized" }), { headers: { ...corsHeaders, "Content-Type": "application/json" }, status: 401 });

    const admin = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SERVICE_ROLE_KEY")!);
    const { data: membership, error: mErr } = await admin.from("wallet_users").select("role").eq("wallet_id", wallet_id).eq("user_id", user.id).maybeSingle();
    if (mErr) return new Response(JSON.stringify({ error: mErr.message }), { headers: { ...corsHeaders, "Content-Type": "application/json" }, status: 400 });
    if (!membership || !["owner","editor"].includes(membership.role)) return new Response(JSON.stringify({ error: "forbidden" }), { headers: { ...corsHeaders, "Content-Type": "application/json" }, status: 403 });

    const { data, error } = await admin.from("wallet_invites").insert({ wallet_id, created_by: user.id }).select("token").single();
    if (error) return new Response(JSON.stringify({ error: error.message }), { headers: { ...corsHeaders, "Content-Type": "application/json" }, status: 400 });

    return new Response(JSON.stringify({ token: data.token, invite_token: data.token }), { headers: { ...corsHeaders, "Content-Type": "application/json" }, status: 200 });
  } catch (e) {
    return new Response(JSON.stringify({ error: String(e) }), { headers: { ...corsHeaders, "Content-Type": "application/json" }, status: 500 });
  }
});
