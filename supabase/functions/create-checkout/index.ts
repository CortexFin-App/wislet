// @ts-nocheck
/// <reference lib="deno.ns" />
import Stripe from "npm:stripe@14.25.0";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const stripe = new Stripe(Deno.env.get("STRIPE_SECRET_KEY")!, {
  apiVersion: "2024-06-20",
});

const supabase = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
);

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST,OPTIONS",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });

  try {
    const { hold_id } = await req.json();
    if (!hold_id) {
      return new Response(JSON.stringify({ error: "hold_id_required" }), {
        status: 400,
        headers: { "content-type": "application/json", ...cors },
      });
    }

    // 1) Перевіряємо hold
    const { data: hold, error: hErr } = await supabase
      .from("holds")
      .select("id,status,expires_at,batch_id,email")
      .eq("id", hold_id)
      .single();

    if (hErr) {
      return new Response(JSON.stringify({ error: hErr.message }), {
        status: 400,
        headers: { "content-type": "application/json", ...cors },
      });
    }
    if (hold.status !== "active") {
      return new Response(JSON.stringify({ error: "hold_not_active" }), {
        status: 400,
        headers: { "content-type": "application/json", ...cors },
      });
    }
    if (new Date(hold.expires_at).getTime() <= Date.now()) {
      return new Response(JSON.stringify({ error: "hold_expired" }), {
        status: 400,
        headers: { "content-type": "application/json", ...cors },
      });
    }

    // 2) Дані батчу
    const { data: batch, error: bErr } = await supabase
      .from("sell_batches")
      .select("id,name,price_cents,currency,tier")
      .eq("id", hold.batch_id)
      .single();

    if (bErr) {
      return new Response(JSON.stringify({ error: bErr.message }), {
        status: 400,
        headers: { "content-type": "application/json", ...cors },
      });
    }

    // 3) Stripe Checkout — редірект на статичні сторінки сайту
    //    (важливо: без будь-яких зайвих параметрів у success_url)
    const successUrl = "https://cortexfinapp.com/thanks.html?session_id={CHECKOUT_SESSION_ID}";
    const cancelUrl  = "https://cortexfinapp.com/cancel.html";

    const session = await stripe.checkout.sessions.create({
      mode: "payment",
      payment_method_types: ["card"],
      customer_email: hold.email,
      metadata: {
        hold_id: String(hold.id),
        batch_id: String(batch.id),
        tier: String(batch.tier),
        buyer_email: hold.email,
      },
      line_items: [
        {
          price_data: {
            currency: batch.currency,
            unit_amount: batch.price_cents,
            product_data: { name: batch.name },
          },
          quantity: 1,
        },
      ],
      success_url: successUrl, // ✅
      cancel_url: cancelUrl,   // ✅
      allow_promotion_codes: false,
    });

    return new Response(JSON.stringify({ url: session.url }), {
      headers: { "content-type": "application/json", ...cors },
    });
  } catch (e) {
    return new Response(JSON.stringify({ error: String(e) }), {
      status: 500,
      headers: { "content-type": "application/json", ...cors },
    });
  }
});
