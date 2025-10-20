# Generates/overwrites apps/bolt-vercel/.env.local with default values

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..\..')
$appEnvPath = Join-Path $repoRoot 'apps\bolt-vercel\.env.local'

Write-Host 'Creating apps\bolt-vercel\.env.local ...' -ForegroundColor Cyan

$envContent = @"
# ============================================
# LUNARAI BEAUTY - LOCAL DEVELOPMENT
# ============================================

# ============================================
# N8N WEBHOOK CONFIGURATION
# ============================================
N8N_WEBHOOK_BASE="https://n8n-gczfssttvtzs.nasgor.sumopod.my.id"
N8N_TEST_WEBHOOK="https://n8n-gczfssttvtzs.nasgor.sumopod.my.id/webhook-test/lbf_skincare"
N8N_PRODUCTION_WEBHOOK="https://n8n-gczfssttvtzs.nasgor.sumopod.my.id/webhook/lbf_skincare"
N8N_WEBHOOK_SECRET="your-secret-key-here-min-32-characters"

# ============================================
# DATABASE (Optional - untuk mock mode biarkan kosong)
# ============================================
# DATABASE_URL="postgresql://user:password@host/db?sslmode=require"

# ============================================
# AI API KEYS (Optional - untuk mock mode biarkan kosong)
# ============================================
# GOOGLE_AI_API_KEY="your-gemini-api-key"
# TAVILY_API_KEY="your-tavily-key"
"@

$envDir = Split-Path $appEnvPath -Parent
if (-not (Test-Path $envDir)) {
    New-Item -ItemType Directory -Path $envDir | Out-Null
}

$envContent | Out-File -FilePath $appEnvPath -Encoding UTF8

Write-Host '.env.local created successfully.' -ForegroundColor Green
Write-Host ''
Write-Host 'Next steps:' -ForegroundColor Yellow
Write-Host '1. Edit apps\bolt-vercel\.env.local and set N8N_WEBHOOK_SECRET.'
Write-Host '2. Restart dev server: npm run dev (from apps\bolt-vercel).'
Write-Host '3. Submit the form to verify the webhook integration.'
Write-Host ''
Write-Host 'Webhook URLs configured:' -ForegroundColor Cyan
Write-Host '  Test: https://n8n-gczfssttvtzs.nasgor.sumopod.my.id/webhook-test/lbf_skincare'
Write-Host '  Prod: https://n8n-gczfssttvtzs.nasgor.sumopod.my.id/webhook/lbf_skincare'