# 🔄 MOCK MODE vs REAL MODE

## 📊 Visual Comparison

### ❌ MOCK MODE (Current - Data Tidak Masuk N8N)

```
┌─────────────────┐
│   User Submit   │
│      Form       │
└────────┬────────┘
         │
         ▼
┌─────────────────────────────────────┐
│   Next.js API (/api/submit)         │
│                                     │
│   ❌ DATABASE_URL not configured    │
│   ❌ N8N_PRODUCTION_WEBHOOK empty   │
│                                     │
│   🎭 MOCK MODE ACTIVATED            │
└────────┬────────────────────────────┘
         │
         ▼
┌─────────────────┐
│  Console.log()  │ ✅ Data muncul di terminal
│  (Terminal)     │
└─────────────────┘
         │
         ▼
┌─────────────────┐
│  Return Success │ ✅ User lihat "success"
│   (Mock Mode)   │
└─────────────────┘

❌ Data TIDAK dikirim ke N8N
❌ Data TIDAK disimpan ke database
❌ Workflow TIDAK berjalan
```

---

### ✅ REAL MODE (After Setup - Data Masuk N8N)

```
┌─────────────────┐
│   User Submit   │
│      Form       │
└────────┬────────┘
         │
         ▼
┌─────────────────────────────────────┐
│   Next.js API (/api/submit)         │
│                                     │
│   ✅ DATABASE_URL configured        │
│   ✅ N8N_PRODUCTION_WEBHOOK set     │
│                                     │
│   🚀 REAL MODE ACTIVATED            │
└────────┬────────────────────────────┘
         │
         ├──────────────────┬──────────────────┐
         │                  │                  │
         ▼                  ▼                  ▼
┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│  Database   │    │  N8N        │    │  Console    │
│  (Neon)     │    │  Webhook    │    │  Log        │
└─────────────┘    └──────┬──────┘    └─────────────┘
                          │
                          ▼
                   ┌─────────────┐
                   │  N8N        │
                   │  Workflow   │
                   └──────┬──────┘
                          │
                          ├──────────────┬──────────────┐
                          │              │              │
                          ▼              ▼              ▼
                   ┌──────────┐   ┌──────────┐   ┌──────────┐
                   │  AI      │   │  Google  │   │  Email   │
                   │  Process │   │  Sheets  │   │  Notif   │
                   └──────────┘   └──────────┘   └──────────┘

✅ Data dikirim ke N8N
✅ Data disimpan ke database
✅ Workflow berjalan lengkap
✅ Team dapat kolaborasi
```

---

## 🔍 Detail Perbedaan

### MOCK MODE

**Environment Variables:**
```bash
# .env.local KOSONG atau tidak ada
# DATABASE_URL=
# N8N_PRODUCTION_WEBHOOK=
```

**Kode yang Dijalankan:**
```typescript
// src/app/api/submit/route.ts
const MOCK_MODE = !process.env.DATABASE_URL || !process.env.N8N_PRODUCTION_WEBHOOK

if (MOCK_MODE) {
  console.log('🎭 MOCK MODE: Backend not configured')
  console.log('Submission payload:', JSON.stringify(payload, null, 2))
  
  return NextResponse.json({
    submissionId: payload.submissionId,
    status: 'queued',
    message: '✅ Form submitted successfully (Mock Mode)',
    mockMode: true
  })
}
```

**Yang Terjadi:**
1. ✅ Form validation berhasil
2. ✅ Data di-log ke console
3. ❌ **SKIP** database save
4. ❌ **SKIP** N8N webhook dispatch
5. ❌ **SKIP** audit logging
6. ✅ Return success response

**Terminal Output:**
```
🎭 MOCK MODE: Backend not configured, returning mock response
Submission payload: {
  "submissionId": "a8fdd455-2f5f-497e-b3b9-327e78a3a16b",
  "brand": { "name": "GlowLab", ... },
  ...
}
```

---

### REAL MODE

**Environment Variables:**
```bash
# .env.local
DATABASE_URL=postgresql://user:password@host/database?sslmode=require
N8N_PRODUCTION_WEBHOOK=https://n8n-gczfssttvtzs.nasgor.sumopod.my.id/webhook/lbf_skincare
```

**Kode yang Dijalankan:**
```typescript
// src/app/api/submit/route.ts
const MOCK_MODE = !process.env.DATABASE_URL || !process.env.N8N_PRODUCTION_WEBHOOK

if (MOCK_MODE) {
  // SKIP - karena env vars sudah ada
}

// REAL MODE: Full backend processing
const submission = await createSubmission({ ... })
await createSubmissionPayload({ ... })

const webhookUrl = process.env.N8N_PRODUCTION_WEBHOOK!
const workflowRun = await createWorkflowRun({ ... })

const webhookResponse = await dispatchToWebhook(payload, 'production')

await createAuditLog({ ... })
logSubmission(submission.id, 'production')

return NextResponse.json({
  submissionId: submission.id,
  status: 'queued',
  message: '✅ Submission queued successfully',
  webhookStatus: 'dispatched'
})
```

**Yang Terjadi:**
1. ✅ Form validation berhasil
2. ✅ Data disimpan ke database
3. ✅ **DISPATCH** ke N8N webhook
4. ✅ Workflow run tracking
5. ✅ Audit logging
6. ✅ Analytics tracking
7. ✅ Return success response

**Terminal Output:**
```
✓ Compiled /api/submit in 282ms
Webhook dispatched to: https://n8n-gczfssttvtzs.nasgor.sumopod.my.id/webhook/lbf_skincare
Webhook response: { success: true, executionId: "abc123" }
Submission saved: a8fdd455-2f5f-497e-b3b9-327e78a3a16b
```

---

## 🎯 Kapan Menggunakan Mode Apa?

### MOCK MODE - Untuk Development

**Gunakan saat:**
- ✅ Develop UI/UX
- ✅ Test form validation
- ✅ Prototype fitur baru
- ✅ Belum setup backend

**Keuntungan:**
- ⚡ Cepat - tidak ada network call
- 💰 Gratis - tidak pakai API/database
- 🔧 Simple - tidak perlu setup

**Kekurangan:**
- ❌ Tidak test integration
- ❌ Tidak test workflow
- ❌ Data tidak persistent

---

### REAL MODE - Untuk Testing & Production

**Gunakan saat:**
- ✅ Test integration end-to-end
- ✅ Test N8N workflow
- ✅ UAT (User Acceptance Testing)
- ✅ Production deployment

**Keuntungan:**
- ✅ Full integration testing
- ✅ Data persistent
- ✅ Team collaboration
- ✅ Production-ready

**Kekurangan:**
- 🔧 Perlu setup backend
- 💰 Ada biaya (database, API)
- ⏱️ Lebih lambat (network calls)

---

## 🚀 Cara Switch dari MOCK ke REAL MODE

### Step 1: Setup Environment Variables

**Otomatis:**
```powershell
.\setup-env-n8n.ps1
```

**Manual:**
```bash
# Buat .env.local
echo "N8N_PRODUCTION_WEBHOOK=https://n8n-gczfssttvtzs.nasgor.sumopod.my.id/webhook/lbf_skincare" > .env.local
```

### Step 2: Restart Server

```bash
# Stop server
Ctrl+C

# Start again
npm run dev
```

### Step 3: Verify

**Cek terminal:**
- ❌ Jika masih ada "🎭 MOCK MODE" → Setup gagal
- ✅ Jika tidak ada "🎭 MOCK MODE" → Setup berhasil

**Test submit form:**
- Isi form
- Submit
- Cek N8N execution logs

---

## 📋 Checklist Switch Mode

### Pre-Setup
- [ ] N8N workflow sudah dibuat
- [ ] N8N webhook URL sudah ada
- [ ] Database sudah setup (optional)

### Setup
- [ ] File `.env.local` dibuat
- [ ] `N8N_PRODUCTION_WEBHOOK` terisi
- [ ] `DATABASE_URL` terisi (optional)
- [ ] Server di-restart

### Verification
- [ ] Terminal tidak ada "MOCK MODE"
- [ ] Form bisa di-submit
- [ ] Data masuk N8N
- [ ] N8N workflow berjalan
- [ ] Data masuk Google Sheets (jika configured)

---

## 💡 Tips

### Development Workflow

1. **Phase 1: UI Development** → MOCK MODE
   - Focus: Design, layout, UX
   - No backend needed

2. **Phase 2: Integration Testing** → REAL MODE
   - Focus: API, workflow, data flow
   - Backend required

3. **Phase 3: Production** → REAL MODE
   - Focus: Monitoring, optimization
   - Full stack active

### Debugging

**MOCK MODE Issues:**
- Cek browser console
- Cek form validation
- Cek component state

**REAL MODE Issues:**
- Cek terminal logs
- Cek N8N execution logs
- Cek database records
- Cek network tab

---

## 🔗 Related Documentation

- [QUICK-FIX-N8N.md](./QUICK-FIX-N8N.md) - Quick solution
- [TROUBLESHOOT-N8N.md](./TROUBLESHOOT-N8N.md) - Detailed guide
- [SETUP-ENV.md](./SETUP-ENV.md) - Environment setup
- [SETUP-WEBHOOK.md](./SETUP-WEBHOOK.md) - N8N webhook setup

---

**Happy coding! 🎉**
