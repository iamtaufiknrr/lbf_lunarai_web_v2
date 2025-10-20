# ⚡ Quick Fix: Data Tidak Masuk N8N

## 🎯 Problem
```
🎭 MOCK MODE: Backend not configured, returning mock response
```
Data hanya muncul di terminal, **TIDAK masuk N8N**.

---

## ✅ Solution (3 Langkah)

### 1️⃣ Jalankan Setup Script
```powershell
.\setup-env-n8n.ps1
```

### 2️⃣ Masukkan N8N Webhook URL
```
https://n8n-gczfssttvtzs.nasgor.sumopod.my.id/webhook/lbf_skincare
```

### 3️⃣ Restart Server
```bash
# Stop: Ctrl+C
npm run dev
```

---

## ✅ Verifikasi

### Terminal SEBELUM (MOCK MODE):
```
🎭 MOCK MODE: Backend not configured
```

### Terminal SESUDAH (REAL MODE):
```
Webhook dispatched to: https://n8n-...
```

---

## 🔧 Manual Setup (Alternatif)

Buat file `.env.local`:
```bash
N8N_PRODUCTION_WEBHOOK=https://n8n-gczfssttvtzs.nasgor.sumopod.my.id/webhook/lbf_skincare
```

Restart server.

---

## 📋 Checklist

- [ ] File `.env.local` ada
- [ ] `N8N_PRODUCTION_WEBHOOK` terisi
- [ ] Server di-restart
- [ ] Terminal tidak ada "MOCK MODE"
- [ ] Data masuk N8N

---

**Done! 🎉**
