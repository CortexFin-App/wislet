# CortexFin — Supabase Autodeploy Pack

Цей пакет містить вашу папку `supabase/` + скрипти для автодеплою всіх Edge Functions.

## Як використати
1) Встановіть Supabase CLI: https://supabase.com/docs/guides/cli
2) Увійдіть:
   ```bash
   supabase login
   ```
3) Перевірте `supabase/config.toml` — там має бути `project_id`/`project_ref` (воно вже є з вашого архіву).
4) (Опційно) Заповніть `supabase/.env.local` ключами (формат `KEY=VALUE` рядками). Скрипти автоматично залиють їх у Secrets:
   - `SUPABASE_URL=https://<project>.supabase.co`
   - `SUPABASE_SERVICE_ROLE_KEY=...`
   - інші ваші змінні функцій

5) Запустіть деплой **усіх** функцій:
   - Linux/macOS:
     ```bash
     ./scripts/deploy-all.sh
     ```
   - Windows PowerShell:
     ```powershell
     ./scripts/deploy-all.ps1
     ```

Скрипти пройдуться по кожній папці у `supabase/functions/*` (окрім `_shared`) і виконають:
```
supabase functions deploy <name> --no-verify-jwt
```
> Заберіть `--no-verify-jwt`, якщо конкретна функція очікує перевірку JWT (у вас публічні ендпоінти для лендінгу — залишаємо як є).

## CORS
У вас вже є `_shared/cors.ts`. Переконайтесь, що кожна функція імпортує і відповідає на `OPTIONS`:
```ts
import { corsHeaders } from "../_shared/cors.ts";
const headers = corsHeaders(req.headers.get("Origin"));
if (req.method === "OPTIONS") return new Response("ok", { headers });
// ... решта логіки
return new Response(JSON.stringify(data), { headers:{...headers, "Content-Type":"application/json"} });
```

## Тести
Після деплою перевірте:
```bash
curl -i https://<project>.functions.supabase.co/public-metrics -H "Origin: https://cortexfinapp.com"
curl -i https://<project>.functions.supabase.co/founders-hall?offset=0&limit=24 -H "Origin: https://cortexfinapp.com"
```

## Примітка
Я **не можу** виконати деплой за вас напряму тут, але пакет і скрипти роблять це в один клік на вашій машині.
