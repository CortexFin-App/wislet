import { serve } from "https://deno.land/std@0.224.0/http/server.ts";

serve(() => {
  const html = `<!doctype html><html><head>
    <meta charset="utf-8" /><meta name="viewport" content="width=device-width,initial-scale=1" />
    <title>Оплату скасовано — Wislet</title>
    <style>body{font-family:system-ui;margin:0;padding:40px;line-height:1.5}
    .box{max-width:640px;margin:auto}</style></head><body>
    <div class="box">
      <h1>Оплату скасовано ❌</h1>
      <p>Ти можеш спробувати ще раз будь-коли.</p>
    </div></body></html>`;
  return new Response(html, { headers: { "content-type": "text/html; charset=utf-8" } });
});
