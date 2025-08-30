// @ts-nocheck
/// <reference lib="deno.ns" />
import Stripe from "npm:stripe@14.25.0";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

// Stripe
const stripe = new Stripe(Deno.env.get("STRIPE_SECRET_KEY")!, {
  apiVersion: "2024-06-20",
});
const endpointSecret = Deno.env.get("STRIPE_WEBHOOK_SECRET")!;

// Supabase (service role)
const supabase = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
);

Deno.serve(async (req) => {
  if (req.method !== "POST") {
    return new Response("Method Not Allowed", { status: 405 });
  }

  // raw body обовʼязковий для перевірки підпису
  const sig = req.headers.get("stripe-signature");
  const raw = await req.text();

  let event;
  try {
    event = stripe.webhooks.constructEvent(raw, sig!, endpointSecret);
  } catch (err) {
    console.error("Stripe signature error:", err);
    return new Response(`Webhook Error: ${err.message}`, { status: 400 });
  }

  try {
    console.log("Stripe event:", event.type);

    switch (event.type) {
      case "checkout.session.completed": {
        const s: any = event.data.object;
        const holdId = Number(s?.metadata?.hold_id);
        const paid = s?.status === "complete" && s?.payment_status === "paid";
        if (!Number.isFinite(holdId) || !paid) break;

        // 1) Фіксуємо оплату в holds (ідемпотентно)
        const { error: updErr } = await supabase
          .from("holds")
          .update({ status: "converted", paid_at: new Date().toISOString() })
          .eq("id", holdId);
        if (updErr) console.error("holds update error", updErr);

        // 2) tx_id — ідентифікатор транзакції (PI або Session id)
        const txId: string | null =
          (typeof s?.payment_intent === "string" && s.payment_intent) ||
          (typeof s?.id === "string" && s.id) ||
          null;

        // 3) Створюємо/гарантуємо order і прикріплюємо tx_id (ідемпотентно)
        const { data: orderId, error: ordErr } = await supabase.rpc(
          "ensure_order_for_hold",
          { p_hold_id: holdId, p_tx_id: txId },
        );
        if (ordErr) console.error("ensure_order_for_hold error", ordErr);
        else console.log("order ensured, id:", orderId);

        // 4) Видаємо Founder-картку (ідемпотентно через unique(hold_id))
        const { error: cardErr } = await supabase.rpc("issue_founder_card", {
          p_hold_id: holdId,
        });
        if (cardErr) console.error("issue_founder_card error", cardErr);

        break;
      }

      case "checkout.session.expired": {
        const s: any = event.data.object;
        const holdId = Number(s?.metadata?.hold_id);
        if (Number.isFinite(holdId)) {
          const { error } = await supabase
            .from("holds")
            .update({ status: "released" })
            .eq("id", holdId);
          if (error) console.error("releaseHold (expired) error", error);
        }
        break;
      }

      case "payment_intent.payment_failed": {
        // якщо PaymentIntent містить metadata.hold_id — відпустити бронь
        const pi: any = event.data.object;
        const holdId = Number(pi?.metadata?.hold_id);
        if (Number.isFinite(holdId)) {
          const { error } = await supabase
            .from("holds")
            .update({ status: "released" })
            .eq("id", holdId);
          if (error) console.error("releaseHold (failed) error", error);
        }
        break;
      }

      default:
        // інші події ігноруємо
        break;
    }

    // Завжди 200 — щоб Stripe не ретраїв безкінечно
    return new Response("ok", { status: 200 });
  } catch (e) {
    // все одно 200, але з текстом — побачиш у Stripe logs
    console.error("Webhook handler error:", e);
    return new Response(`Handler error: ${String(e)}`, { status: 200 });
  }
});
