# 🔗 Setup Webhook - LunarAI Beauty

## ✅ Status Kode

Kode Next.js **sudah benar** dan siap menerima webhook URLs dari environment variables:

```typescript
// src/app/api/submit/route.ts (Line 62-65)
const webhookUrl =
  payload.targetEnvironment === 'test'
    ? process.env.N8N_TEST_WEBHOOK!      // ← Ambil dari .env.local
    : process.env.N8N_PRODUCTION_WEBHOOK! // ← Ambil dari .env.local
```

---

## 🎯 Yang Perlu Dilakukan

### Step 1: Buat File `.env.local`

Di root project (folder `lbf_techno_windsurf`), buat file `.env.local`:

```bash
# Windows PowerShell
New-Item -Path .env.local -ItemType File

# Atau manual: Klik kanan di VS Code → New File → .env.local
```

### Step 2: Copy Paste Ini ke `.env.local`

```bash
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
```

### Step 3: Restart Dev Server

```bash
# Stop server (Ctrl+C di terminal)
# Start lagi
npm run dev
```

---

## 🧪 Testing

### Test 1: Cek Environment Variables Loaded

```bash
# Di terminal development, cek log saat server start
# Seharusnya tidak ada "🎭 MOCK MODE" lagi
```

### Test 2: Submit Form

1. Buka browser: `http://localhost:3000`
2. Isi form lengkap
3. Klik **"Buat Brief Produk"**
4. Cek **Network tab** → `submit` request
5. **Expected Response**:

```json
{
  "submissionId": "uuid-here",
  "mode": "test",  // atau "production" tergantung mode
  "status": "queued",
  "message": "✅ Submission queued successfully",
  "webhookStatus": "dispatched"
}
```

### Test 3: Cek Webhook Dipanggil

Di **Network tab**, seharusnya ada request ke:
```
POST https://n8n-gczfssttvtzs.nasgor.sumopod.my.id/webhook-test/lbf_skincare
```

Dengan payload yang sama seperti di screenshot Anda.

---

## 📊 Flow Data

```
User klik "Buat Brief Produk"
    ↓
Frontend: POST /api/submit
    ↓
Backend: Validate payload
    ↓
Backend: Check targetEnvironment
    ↓
If targetEnvironment === "test":
  → Call N8N_TEST_WEBHOOK
    https://n8n-gczfssttvtzs.nasgor.sumopod.my.id/webhook-test/lbf_skincare
    
If targetEnvironment === "production":
  → Call N8N_PRODUCTION_WEBHOOK
    https://n8n-gczfssttvtzs.nasgor.sumopod.my.id/webhook/lbf_skincare
    ↓
n8n receives payload:
{
  "submissionId": "...",
  "targetEnvironment": "test",
  "brand": {...},
  "productBlueprint": {...},
  "collaboration": {...},
  "concept": {...},
  "ingredients": [...],
  "systemMetadata": {...}
}
```

---

## 🔍 Troubleshooting

### Issue: Masih Mock Mode

**Symptom**:
```
✅ Form Submitted (Demo Mode)
```

**Solution**:
1. Pastikan file `.env.local` ada di root project
2. Pastikan `N8N_PRODUCTION_WEBHOOK` tidak kosong
3. Restart dev server

### Issue: Webhook Error

**Symptom**:
```
✅ Submission saved (workflow will process shortly)
```

**Possible Causes**:
1. n8n workflow belum di-import
2. Webhook path salah
3. n8n instance down

**Check**:
```bash
# Test webhook manually
curl -X POST https://n8n-gczfssttvtzs.nasgor.sumopod.my.id/webhook-test/lbf_skincare \
  -H "Content-Type: application/json" \
  -d '{"test": true}'
```

### Issue: CORS Error

**Solution**: n8n webhook seharusnya tidak ada CORS issue karena dipanggil dari backend (bukan browser).

---

## 📝 Payload Structure

Payload yang dikirim ke n8n webhook sama persis dengan yang di screenshot:

```json
{
  "submissionId": "bcd3cfff-3048-4ec1-8a35-f8197abb98b8",
  "submittedAt": "2025-10-18T16:24:00.574Z",
  "targetEnvironment": "test",
  "brand": {
    "name": "cayah",
    "voice": "friendly",
    "values": "aalskdjsalkdjjadaskldjfsfsdfds"
  },
  "productBlueprint": {
    "functions": ["anti-aging"],
    "formType": "Cream",
    "packagingPrimer": {
      "type": "dropper",
      "finish": "matte",
      "materialNotes": "plastik"
    },
    "netto": {
      "value": 40,
      "unit": "ml"
    },
    "colorProfile": {
      "description": "Light Pink",
      "hex": "#854c4c"
    },
    "gender": "female",
    "ageRanges": ["Child", "50+"],
    "location": {
      "country": "ID",
      "region": "SB",
      "city": "PYK"
    },
    "launchTimeline": "Q2",
    "targetRetailPrice": 123777,
    "pilotBatchSize": 500,
    "moqExpectation": 2000,
    "distributionFocus": "Domestic Retail",
    "sustainabilityPriority": 70,
    "regulatoryPriority": ["BPOM Indonesia"],
    "texturePreference": "dadadasdas",
    "fragranceProfile": "asdsadsadsaa",
    "claimEmphasis": ["Reef Safe"],
    "aiImageStyle": "adaadadadadada",
    "requiresClinicalStudy": true,
    "needsHalalCertification": true
  },
  "collaboration": {
    "preferredChannels": ["Email"],
    "requestedDeliverables": [
      "Regulatory dossier",
      "Market analysis",
      "Formula development",
      "Packaging mockups"
    ],
    "notesForDesignTeam": "daeqweqweeq"
  },
  "concept": {
    "formulaNarrative": "asddasdaaddadadada",
    "benchmark": "Benchmark XYZ",
    "additionalNotes": ""
  },
  "ingredients": [
    {
      "name": "Hyaluronic Acid",
      "inciName": "Sodium Hyaluronate",
      "purpose": "Hydrating, Plumping"
    }
  ],
  "systemMetadata": {
    "formVersion": "1.0.0",
    "appVersion": "1.0.0",
    "language": "id"
  }
}
```

---

## ✅ Checklist

- [ ] File `.env.local` created
- [ ] `N8N_TEST_WEBHOOK` configured
- [ ] `N8N_PRODUCTION_WEBHOOK` configured
- [ ] Dev server restarted
- [ ] Form submission tested
- [ ] Network tab checked
- [ ] Webhook received in n8n

---

## 🎯 Summary

**Kode sudah benar!** Yang perlu dilakukan:

1. ✅ Buat file `.env.local`
2. ✅ Copy paste webhook URLs
3. ✅ Restart dev server
4. ✅ Test form submission

**Setelah itu, payload akan otomatis dikirim ke webhook n8n sesuai mode (test/production)!** 🚀

---

*Last Updated: October 18, 2025*
