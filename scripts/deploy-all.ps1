# Autodeploy all Edge Functions for CortexFin (Supabase)
# Prereqs: supabase CLI logged in (`supabase login`) and project ref present in supabase/config.toml

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location (Join-Path $root "..")

# Optional: apply secrets from supabase/.env.local
$envPath = "supabase/.env.local"
if (Test-Path $envPath) {
  Write-Host "Applying secrets from $envPath ..."
  Get-Content $envPath | ForEach-Object {
    if ($_ -match '^[A-Za-z_][A-Za-z0-9_]*=') {
      $parts = $_ -split '=',2
      supabase secrets set "$($_)"
    }
  }
}

$functions = @("accept-invite", "admin-export", "admin-holds-to-chase", "admin-manual-convert", "admin-mark-chased", "admin-mark-chased-bulk", "admin-mint-founder", "admin-ping-timeline", "admin-stats", "admin-update-hold", "cancel", "confirm-checkout", "create-checkout", "create-invite", "fondy-webhook", "founders-hall", "generate-health-advice", "invitations", "lemon-webhook", "login", "mono-webhook", "ocr", "pay-fondy", "pay-mono", "public-metrics", "register", "stripe-webhook", "thanks")
foreach ($fn in $functions) {
  Write-Host "→ $fn"
  supabase functions deploy $fn --no-verify-jwt
}
Write-Host "Done."
