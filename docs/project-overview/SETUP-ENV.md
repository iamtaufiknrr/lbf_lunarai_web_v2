# 🔧 Setup Environment Variables

## Quick Fix untuk Error "Unexpected token '<'"

Error ini terjadi karena **webhook n8n belum di-setup**. Ada 2 solusi:

---

## ✅ Solusi 1: Mock Mode (Recommended untuk Development)

Biarkan tanpa environment variables, aplikasi akan otomatis masuk **Mock Mode**.

### Cara Kerja Mock Mode:
1. Form submission akan **berhasil**
2. Data akan di-log ke console
3. **Tidak ada** koneksi ke database atau n8n
4. User akan melihat pesan: "✅ Form submitted successfully (Mock Mode)"

### Cek Mock Mode:
```bash
# Di terminal development
npm run dev

# Lihat console log saat submit form
# Akan muncul: "🎭 MOCK MODE: Backend not configured"
```

---

## ✅ Solusi 2: Setup Backend (Untuk Production)

### Step 1: Buat file `.env.local`

```bash
# Di root project
touch .env.local
```

### Step 2: Copy template ini ke `.env.local`

```bash
# ============================================
# LUNARAI BEAUTY - LOCAL DEVELOPMENT
# ============================================

# ============================================
# DATABASE (Optional - untuk mock mode biarkan kosong)
# ============================================
# DATABASE_URL="postgresql://user:password@host/db?sslmode=require"

# ============================================
# N8N WEBHOOK (Optional - untuk mock mode biarkan kosong)
# ============================================
# N8N_PRODUCTION_WEBHOOK="https://your-n8n.app.n8n.cloud/webhook/lunarai-production"
# N8N_WEBHOOK_SECRET="your-secret-key-min-32-chars"

# ============================================
# AI API KEYS (Optional - untuk mock mode biarkan kosong)
# ============================================
# GOOGLE_AI_API_KEY="your-gemini-api-key"
# TAVILY_API_KEY="your-tavily-key"
```

### Step 3: Restart development server

```bash
# Stop server (Ctrl+C)
# Start again
npm run dev
```

---

## 🔍 Troubleshooting

### Error: "Unexpected token '<'"

**Penyebab**: Webhook n8n return HTML error page (bukan JSON)

**Solusi**:
1. **Biarkan kosong** (Mock Mode) ✅ Recommended
2. **Atau** setup n8n webhook dulu

### Error: "Internal Server Error"

**Penyebab**: Database connection failed

**Solusi**:
1. **Biarkan kosong** (Mock Mode) ✅ Recommended
2. **Atau** setup Neon database dulu

### Form tidak submit

**Cek**:
1. Browser console untuk error
2. Network tab untuk request/response
3. Terminal untuk server logs

---

## 📊 Cek Status Mode

### Mock Mode (Default)
```
✅ Form submitted successfully (Mock Mode - No backend configured)
```

### Real Mode (Backend Configured)
```
✅ Submission queued successfully
```

---

## 🚀 Next Steps

### Untuk Development (Sekarang):
1. **Biarkan Mock Mode** - Tidak perlu setup apapun
2. Focus pada UI/UX development
3. Test form validation

### Untuk Production (Nanti):
1. Setup Neon PostgreSQL database
2. Import n8n workflows
3. Configure environment variables
4. Deploy to Vercel

---

## 💡 Tips

### Mock Mode Advantages:
- ✅ No setup required
- ✅ Fast development
- ✅ No costs (API, database)
- ✅ Easy testing

### When to Switch to Real Mode:
- ✅ Ready to test full workflow
- ✅ Database setup complete
- ✅ n8n workflows imported
- ✅ Ready for production

---

**Untuk sekarang, Mock Mode sudah cukup untuk development! 🎉**
