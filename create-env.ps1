# PowerShell script to create .env.local file

Write-Host "🔧 Creating .env.local file..." -ForegroundColor Cyan

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

# Create .env.local file
$envContent | Out-File -FilePath ".env.local" -Encoding UTF8

Write-Host "✅ .env.local file created successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "📝 Next steps:" -ForegroundColor Yellow
Write-Host "1. Edit .env.local and set N8N_WEBHOOK_SECRET" -ForegroundColor White
Write-Host "2. Restart dev server: npm run dev" -ForegroundColor White
Write-Host "3. Test form submission" -ForegroundColor White
Write-Host ""
Write-Host "🔗 Webhook URLs configured:" -ForegroundColor Cyan
Write-Host "   Test: https://n8n-gczfssttvtzs.nasgor.sumopod.my.id/webhook-test/lbf_skincare" -ForegroundColor Gray
Write-Host "   Prod: https://n8n-gczfssttvtzs.nasgor.sumopod.my.id/webhook/lbf_skincare" -ForegroundColor Gray
