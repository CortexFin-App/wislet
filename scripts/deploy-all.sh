#!/usr/bin/env bash
set -euo pipefail

# Autodeploy all Edge Functions for CortexFin (Supabase)
# Prereqs: supabase CLI logged in (`supabase login`) and project ref present in supabase/config.toml

cd "$(dirname "$0")/.."

# Optional: set secrets from supabase/.env.local (KEY=VALUE lines)
if [[ -f supabase/.env.local ]]; then
  echo "Applying secrets from supabase/.env.local ..."
  # shellcheck disable=SC2046
  supabase secrets set $(grep -E '^[A-Za-z_][A-Za-z0-9_]*=' supabase/.env.local | xargs) || true
fi

echo "Deploying functions..."
for fn in accept-invite admin-export admin-holds-to-chase admin-manual-convert admin-mark-chased admin-mark-chased-bulk admin-mint-founder admin-ping-timeline admin-stats admin-update-hold cancel confirm-checkout create-checkout create-invite fondy-webhook founders-hall generate-health-advice invitations lemon-webhook login mono-webhook ocr pay-fondy pay-mono public-metrics register stripe-webhook thanks; do
  echo "→ $fn"
  supabase functions deploy "$fn" --no-verify-jwt
done

echo "Done."
