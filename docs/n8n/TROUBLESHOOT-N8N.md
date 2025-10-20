# 🔧 Troubleshooting: Data Tidak Masuk ke N8N

## ❌ Masalah

Saat klik "Buat Brief Produk":
- ✅ Data muncul di VSCode terminal
- ❌ Data **TIDAK** masuk ke N8N
- 🎭 Muncul pesan: `MOCK MODE: Backend not configured, returning mock response`

---

## 🔍 Penyebab

Aplikasi berjalan dalam **MOCK MODE** karena environment variables tidak dikonfigurasi.

### Kode yang Menyebabkan MOCK MODE

File: `src/app/api/submit/route.ts` (baris 13)

```typescript
const MOCK_MODE = !process.env.DATABASE_URL || !process.env.N8N_PRODUCTION_WEBHOOK
```

**Aplikasi masuk MOCK MODE jika:**
- ❌ `DATABASE_URL` tidak ada, **ATAU**
- ❌ `N8N_PRODUCTION_WEBHOOK` tidak ada

### Apa yang Terjadi di MOCK MODE?

```typescript
if (MOCK_MODE) {
  console.log('🎭 MOCK MODE: Backend not configured, returning mock response')
  console.log('Submission payload:', JSON.stringify(payload, null, 2))
  
  return NextResponse.json({
    submissionId: payload.submissionId,
    mode: payload.targetEnvironment,
    status: 'queued',
    message: '✅ Form submitted successfully (Mock Mode - No backend configured)',
    mockMode: true,
    note: 'Configure DATABASE_URL and N8N_PRODUCTION_WEBHOOK to enable real backend'
  })
}
```

**Dalam MOCK MODE:**
- ✅ Data hanya di-log ke console (terminal)
- ❌ **TIDAK** dikirim ke N8N webhook
- ❌ **TIDAK** disimpan ke database
- ✅ User tetap melihat "success" message

---

## ✅ Solusi

### Opsi 1: Setup Otomatis (Recommended)

Jalankan script PowerShell:

```powershell
# Di root project
.\setup-env-n8n.ps1
```

Script akan meminta:
1. **N8N Production Webhook URL** (wajib)
   - Contoh: `https://n8n-gczfssttvtzs.nasgor.sumopod.my.id/webhook/lbf_skincare`
2. **N8N Test Webhook URL** (optional)
   - Contoh: `https://n8n-gczfssttvtzs.nasgor.sumopod.my.id/webhook-test/lbf_skincare`
3. **Database URL** (optional)
   - Contoh: `postgresql://user:password@host/database?sslmode=require`

### Opsi 2: Setup Manual

1. **Buat file `.env.local`** di root project:

```bash
# ============================================
# LUNARAI BEAUTY - ENVIRONMENT CONFIGURATION
# ============================================

# ============================================
# N8N WEBHOOK CONFIGURATION (WAJIB!)
# ============================================
N8N_PRODUCTION_WEBHOOK=https://n8n-gczfssttvtzs.nasgor.sumopod.my.id/webhook/lbf_skincare
N8N_TEST_WEBHOOK=https://n8n-gczfssttvtzs.nasgor.sumopod.my.id/webhook-test/lbf_skincare

# ============================================
# DATABASE CONFIGURATION (Optional)
# ============================================
# DATABASE_URL=postgresql://user:password@host/database?sslmode=require

# ============================================
# APPLICATION CONFIGURATION
# ============================================
NEXT_PUBLIC_APP_VERSION=1.0.0
NEXT_PUBLIC_FORM_VERSION=1.0.0
NEXT_PUBLIC_DEFAULT_LANGUAGE=id
```

2. **Restart development server:**

```bash
# Stop server (Ctrl+C)
npm run dev
```

---

## 🧪 Cara Test

### 1. Cek Mode Aplikasi

Setelah restart server, perhatikan terminal:

**❌ MOCK MODE (Sebelum):**
```
🎭 MOCK MODE: Backend not configured, returning mock response
Submission payload: { ... }
```

**✅ REAL MODE (Sesudah):**
```
✓ Compiled /api/submit in 282ms
Webhook dispatched to: https://n8n-gczfssttvtzs.nasgor.sumopod.my.id/webhook/lbf_skincare
Webhook response: { success: true, ... }
```

### 2. Submit Form

1. Buka aplikasi di browser
2. Isi form "Buat Brief Produk"
3. Klik submit

### 3. Cek N8N

1. Buka N8N dashboard
2. Cek workflow "LBF Skincare"
3. Lihat execution logs
4. Data seharusnya sudah masuk!

---

## 🔍 Troubleshooting Lanjutan

### Problem 1: Masih MOCK MODE setelah setup

**Cek:**
```powershell
# Pastikan file .env.local ada
ls .env.local

# Pastikan isi file benar
cat .env.local
```

**Solusi:**
- Pastikan `N8N_PRODUCTION_WEBHOOK` tidak kosong
- Restart server dengan benar (Ctrl+C lalu `npm run dev`)

### Problem 2: Error "Webhook dispatch error"

**Penyebab:**
- N8N webhook URL salah
- N8N workflow tidak aktif
- Network issue

**Solusi:**
1. Cek N8N webhook URL di `.env.local`
2. Pastikan N8N workflow aktif
3. Test webhook manual:
   ```bash
   curl -X POST https://n8n-gczfssttvtzs.nasgor.sumopod.my.id/webhook/lbf_skincare \
     -H "Content-Type: application/json" \
     -d '{"test": "data"}'
   ```

### Problem 3: Data masuk N8N tapi error di workflow

**Cek:**
1. N8N execution logs
2. Pastikan struktur data sesuai
3. Cek node configuration di N8N

---

## 📊 Perbandingan Mode

| Fitur | MOCK MODE | REAL MODE |
|-------|-----------|-----------|
| Form submission | ✅ Berhasil | ✅ Berhasil |
| Data di terminal | ✅ Ya | ✅ Ya |
| Kirim ke N8N | ❌ Tidak | ✅ Ya |
| Simpan ke database | ❌ Tidak | ✅ Ya (jika configured) |
| Audit logs | ❌ Tidak | ✅ Ya |
| Analytics | ❌ Tidak | ✅ Ya |

---

## 🚀 Next Steps

Setelah setup environment variables:

1. ✅ **Test form submission** - Pastikan data masuk N8N
2. ✅ **Setup database** (optional) - Untuk persistence
3. ✅ **Configure N8N workflow** - Sesuaikan dengan kebutuhan
4. ✅ **Deploy to production** - Vercel + environment variables

---

## 💡 Tips

### Development
- Gunakan **MOCK MODE** untuk UI/UX development
- Gunakan **REAL MODE** untuk integration testing

### Production
- Selalu set `N8N_PRODUCTION_WEBHOOK`
- Gunakan `DATABASE_URL` untuk persistence
- Enable analytics untuk monitoring

### Security
- Jangan commit `.env.local` ke Git
- Gunakan `N8N_WEBHOOK_SECRET` untuk verification
- Rotate secrets secara berkala

---

## 📞 Support

Jika masih ada masalah:
1. Cek terminal logs
2. Cek browser console
3. Cek N8N execution logs
4. Cek network tab di browser DevTools

---

**Selamat mencoba! 🎉**
