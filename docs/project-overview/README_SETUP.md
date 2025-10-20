# LunarAI Beauty - Setup Guide

## 🎭 Demo Mode (Current State)

The application currently runs in **DEMO MODE** because backend services are not configured. This allows you to:
- ✅ Fill and submit the form
- ✅ See validation working
- ✅ View submission data in browser console
- ❌ No data persistence (no database)
- ❌ No AI processing (no n8n workflow)
- ❌ No result page (no backend to fetch from)

## 🚀 Full Production Setup

To enable full functionality, you need to configure:

### 1. Database Setup (Neon Postgres)

1. Create a Neon Postgres database at https://neon.tech
2. Copy your connection string
3. Create `.env.local` file:
   ```bash
   DATABASE_URL=postgresql://user:password@host/database?sslmode=require
   ```
4. Run database migrations:
   ```bash
   npm run db:generate
   npm run db:migrate
   ```

### 2. n8n Workflow Setup

1. Deploy n8n instance (self-hosted or cloud)
2. Create workflow with webhook trigger
3. Configure webhook URLs in `.env.local`:
   ```bash
   N8N_TEST_WEBHOOK=https://your-n8n.com/webhook-test/lbf_skincare
   N8N_PRODUCTION_WEBHOOK=https://your-n8n.com/webhook/lbf_skincare
   ```

### 3. Workflow Requirements

Your n8n workflow should:
- Accept POST request with submission payload
- Process AI analysis (formulation, market research, etc.)
- Store results in database
- Optionally sync to Google Sheets
- Return success/error response

### 4. Restart Application

After configuration:
```bash
npm run dev
```

The app will automatically detect backend configuration and switch from DEMO MODE to PRODUCTION MODE.

## 📋 Environment Variables

See `.env.example` for all available configuration options.

### Required for Production:
- `DATABASE_URL` - Neon Postgres connection
- `N8N_PRODUCTION_WEBHOOK` - n8n webhook endpoint

### Optional:
- `N8N_TEST_WEBHOOK` - For testing environment
- `N8N_WEBHOOK_SECRET` - Webhook signature verification
- Analytics and monitoring configs

## 🔍 Checking Current Mode

When you submit a form:
- **Demo Mode**: Toast shows "Form Submitted (Demo Mode)"
- **Production Mode**: Toast shows "Brief produk Anda sedang diproses oleh AI"

Check browser console for detailed logs.

## 📚 Additional Resources

- Database Schema: See `/src/lib/schema.ts`
- API Routes: See `/src/app/api/submit/route.ts`
- Payload Structure: See `/src/types/submission.ts`

## 🆘 Troubleshooting

**Error: "Unexpected token is not valid JSON"**
- This means backend is not configured (expected in demo mode)
- Solution: Configure DATABASE_URL and N8N_PRODUCTION_WEBHOOK

**Form submits but no redirect**
- This is normal in demo mode
- Data is logged to console instead

**Need help with n8n workflow?**
- Check n8n documentation: https://docs.n8n.io
- Example payload structure is logged in console when you submit
