# Setup environment variables for the N8N integration and write to apps/bolt-vercel/.env.local

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..\..\..')
$appEnvPath = Join-Path $repoRoot 'apps\bolt-vercel\.env.local'

Write-Host 'Setup Environment Variables untuk N8N Integration' -ForegroundColor Cyan
Write-Host ''

if (Test-Path $appEnvPath) {
    Write-Host '.env.local sudah ada di apps\bolt-vercel.' -ForegroundColor Yellow
    $overwrite = Read-Host 'Overwrite file? (y/n)'
    if ($overwrite -ne 'y') {
        Write-Host 'Setup dibatalkan.' -ForegroundColor Red
        exit
    }
}

Write-Host 'Masukkan konfigurasi N8N Webhook:' -ForegroundColor Green
Write-Host ''

$prodWebhook = Read-Host 'N8N Production Webhook URL'
$testWebhook = Read-Host 'N8N Test Webhook URL (optional)'
$databaseUrl = Read-Host 'Database URL (optional - tekan Enter untuk skip)'

$envLines = @()
$envLines += '# ============================================'
$envLines += '# LUNARAI BEAUTY - ENVIRONMENT CONFIGURATION'
$envLines += '# ============================================'
$envLines += "# Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
$envLines += ''
$envLines += '# ============================================'
$envLines += '# N8N WEBHOOK CONFIGURATION'
$envLines += '# ============================================'
$envLines += "N8N_PRODUCTION_WEBHOOK=$prodWebhook"
if ([string]::IsNullOrWhiteSpace($testWebhook) -eq $false) {
    $envLines += "N8N_TEST_WEBHOOK=$testWebhook"
}
if ([string]::IsNullOrWhiteSpace($databaseUrl) -eq $false) {
    $envLines += ''
    $envLines += '# ============================================'
    $envLines += '# DATABASE CONFIGURATION'
    $envLines += '# ============================================'
    $envLines += "DATABASE_URL=$databaseUrl"
}
$envLines += ''
$envLines += '# ============================================'
$envLines += '# APPLICATION CONFIGURATION'
$envLines += '# ============================================'
$envLines += 'NEXT_PUBLIC_APP_VERSION=1.0.0'
$envLines += 'NEXT_PUBLIC_FORM_VERSION=1.0.0'
$envLines += 'NEXT_PUBLIC_DEFAULT_LANGUAGE=id'
$envLines += ''
$envLines += '# ============================================'
$envLines += '# OPTIONAL: N8N WEBHOOK SECURITY'
$envLines += '# ============================================'
$envLines += '# N8N_WEBHOOK_SECRET=your-secret-key-min-32-chars'
$envLines += ''
$envLines += '# ============================================'
$envLines += '# OPTIONAL: ANALYTICS'
$envLines += '# ============================================'
$envLines += '# ANALYTICS_ENDPOINT='

$envDir = Split-Path $appEnvPath -Parent
if (-not (Test-Path $envDir)) {
    New-Item -ItemType Directory -Path $envDir | Out-Null
}

$envLines | Out-File -FilePath $appEnvPath -Encoding UTF8

Write-Host ''
Write-Host '.env.local berhasil dibuat di apps\bolt-vercel.' -ForegroundColor Green
Write-Host ''
Write-Host 'Konfigurasi yang disimpan:' -ForegroundColor Cyan
Write-Host "  - N8N Production Webhook: $prodWebhook"
if ([string]::IsNullOrWhiteSpace($testWebhook) -eq $false) {
    Write-Host "  - N8N Test Webhook: $testWebhook"
}
if ([string]::IsNullOrWhiteSpace($databaseUrl) -eq $false) {
    Write-Host '  - Database URL: [SET]'
}
Write-Host ''
Write-Host 'Langkah selanjutnya:' -ForegroundColor Yellow
Write-Host '  1. Jalankan npm run dev dari apps\bolt-vercel.'
Write-Host '  2. Submit form untuk memastikan data masuk ke N8N.'
Write-Host ''
Write-Host 'Tips:' -ForegroundColor Cyan
Write-Host '  - Pastikan N8N workflow aktif.'
Write-Host '  - Cek logs N8N untuk memantau payload.'
