// deno-lint-ignore-file no-explicit-any
import { serve } from "https://deno.land/std@0.224.0/http/server.ts";

serve((req) => {
  const url = new URL(req.url);
  const sessionId = url.searchParams.get("session_id") ?? "";
  const html = `<!doctype html><html><head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width,initial-scale=1" />
    <title>Дякуємо — Wislet</title>
    <style>body{font-family:system-ui;margin:0;padding:40px;line-height:1.5}
    .box{max-width:640px;margin:auto}</style></head><body>
    <div class="box">
      <h1>Дякуємо! ✅</h1>
      <p>Платіж прийнято. ${sessionId ? `ID сесії: <code>${sessionId}</code>` : ""}</p>
      <p>Можеш закрити це вікно або повернутися в застосунок.</p>
    </div></body></html>`;
  return new Response(html, { headers: { "content-type": "text/html; charset=utf-8" } });
});
