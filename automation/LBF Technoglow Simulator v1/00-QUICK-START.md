# 🚀 Quick Start Guide - LBF Technoglow Simulator v1

## ⚡ Get Started in 15 Minutes

Panduan cepat untuk setup dan menjalankan sistem dalam waktu singkat.

---

## 📋 Prerequisites

Sebelum mulai, pastikan Anda punya:
- ✅ Akun Neon Postgres (gratis di [neon.tech](https://neon.tech))
- ✅ Akun n8n Cloud (gratis di [n8n.io](https://n8n.io)) atau self-hosted
- ✅ OpenAI API key ([platform.openai.com](https://platform.openai.com))
- ✅ Anthropic API key ([console.anthropic.com](https://console.anthropic.com))
- ✅ Node.js 20+ installed
- ✅ Git installed

---

## 🎯 Step 1: Clone & Setup (2 minutes)

```bash
# Clone repository
git clone <your-repo-url>
cd <your-repo>

# Navigate to app folder
cd apps/bolt-vercel

# Install dependencies
npm install
```

---

## 💾 Step 2: Setup Database (3 minutes)

### 2.1 Create Neon Database
1. Go to [console.neon.tech](https://console.neon.tech)
2. Click **New Project**
3. Name: `lbf-technoglow-simulator`
4. Region: Choose closest to your users
5. Click **Create Project**

### 2.2 Get Connection String
1. In project dashboard, click **Connection Details**
2. Copy **Connection string**
3. Should look like:
   ```
   postgresql://user:password@ep-xxx.region.aws.neon.tech/dbname?sslmode=require
   ```

### 2.3 Apply Database Schema
```bash
# Set DATABASE_URL
export DATABASE_URL="your-connection-string-here"

# Apply schema
psql $DATABASE_URL -f "../../automation/LBF Technoglow Simulator v1/02-Database/schema.sql"

# Verify
psql $DATABASE_URL -c "\dt"
```

Expected output: 5 tables created (submissions, submission_payloads, workflow_runs, report_sections, audit_logs)

---

## 🤖 Step 3: Setup n8n (5 minutes)

### 3.1 Create n8n Account
1. Go to [n8n.io](https://n8n.io)
2. Sign up for free account
3. Create new workspace
4. Note your instance URL: `https://your-instance.app.n8n.cloud`

### 3.2 Configure Credentials

**PostgreSQL**:
1. Go to **Credentials** → **New**
2. Select **Postgres**
3. Fill in from your Neon connection string:
   - Host: `ep-xxx.region.aws.neon.tech`
   - Database: `dbname`
   - User: `user`
   - Password: `password`
   - SSL: `require`
4. Test connection → Save as "Neon Postgres"

**OpenAI**:
1. **Credentials** → **New** → **OpenAI**
2. API Key: `sk-proj-...`
3. Save as "OpenAI GPT-4"

**Anthropic**:
1. **Credentials** → **New** → **Anthropic**
2. API Key: `sk-ant-...`
3. Save as "Anthropic Claude"

### 3.3 Import Main Workflow
1. Go to **Workflows** → **Import from File**
2. Select `automation/LBF Technoglow Simulator v1/01-Workflows/00-main-orchestrator.json`
3. Click **Import**
4. In workflow, click **Webhook Receiver** node
5. Copy **Production URL** (e.g., `https://your-n8n.app.n8n.cloud/webhook/lbf-simulator`)
6. Click **Activate** (top right)

---

## ⚙️ Step 4: Configure Next.js App (3 minutes)

### 4.1 Create Environment File
```bash
# In apps/bolt-vercel folder
cp .env.example .env.local
```

### 4.2 Edit .env.local
```env
# Database (from Step 2)
DATABASE_URL=postgresql://user:password@host.neon.tech/dbname?sslmode=require

# n8n Webhooks (from Step 3)
N8N_PRODUCTION_WEBHOOK=https://your-n8n.app.n8n.cloud/webhook/lbf-simulator
N8N_TEST_WEBHOOK=https://your-n8n.app.n8n.cloud/webhook-test/lbf-simulator

# Generate strong secret (run this command):
# openssl rand -base64 32
N8N_WEBHOOK_SECRET=your-generated-secret-here

# App Configuration
NEXT_PUBLIC_APP_VERSION=1.0.0
NEXT_PUBLIC_FORM_VERSION=1.0.0
NEXT_PUBLIC_DEFAULT_LANGUAGE=id
NEXT_PUBLIC_API_URL=http://localhost:3004
```

### 4.3 Add Secret to n8n
1. In n8n, go to **Settings** → **Environment Variables**
2. Add: `N8N_WEBHOOK_SECRET` = `your-generated-secret-here` (same as above)
3. Save

---

## 🧪 Step 5: Test Everything (2 minutes)

### 5.1 Start Next.js App
```bash
# In apps/bolt-vercel folder
npm run dev
```

Open browser: `http://localhost:3004`

### 5.2 Test Submission
1. Fill out the form
2. Click **Submit**
3. You should see: "✅ Submission queued successfully"
4. Note the `submissionId`

### 5.3 Check n8n Execution
1. Go to n8n dashboard
2. Click **Executions** tab
3. You should see new execution running
4. Click to see details

### 5.4 Check Database
```bash
# Check submission created
psql $DATABASE_URL -c "SELECT * FROM submissions ORDER BY created_at DESC LIMIT 1;"

# Check workflow run
psql $DATABASE_URL -c "SELECT * FROM workflow_runs ORDER BY created_at DESC LIMIT 1;"
```

### 5.5 View Result
Go to: `http://localhost:3004/result/[your-submission-id]`

You should see the report (may take 3-4 minutes to complete)

---

## ✅ Success Checklist

- [ ] Database created and schema applied
- [ ] n8n account created and credentials configured
- [ ] Main workflow imported and activated
- [ ] Next.js app running locally
- [ ] Test submission successful
- [ ] n8n workflow executed
- [ ] Report sections saved to database
- [ ] Result page displays correctly

---

## 🎉 You're Done!

Sistem Anda sudah berjalan! 

### Next Steps:

1. **Import Remaining Workflows** (Optional, untuk production):
   - `01-formulation-agent.json`
   - `02-market-research-agent.json`
   - `03-copywriting-agent.json`
   - `04-compliance-agent.json`
   - `05-pricing-agent.json`
   - `06-final-aggregator.json`
   - `07-error-handler.json`

2. **Deploy to Production**:
   - Follow `DEPLOYMENT-CHECKLIST.md`
   - Deploy Next.js to Vercel
   - Configure production environment variables

3. **Customize**:
   - Adjust AI prompts in workflows
   - Customize form fields
   - Add your branding

---

## 🆘 Troubleshooting

### Issue: "DATABASE_URL not found"
**Solution**: Make sure `.env.local` exists in `apps/bolt-vercel/` folder

### Issue: "Webhook not triggered"
**Solution**: 
1. Check `N8N_PRODUCTION_WEBHOOK` URL is correct
2. Verify `N8N_WEBHOOK_SECRET` matches in both Next.js and n8n
3. Check n8n workflow is activated

### Issue: "Connection refused" (Database)
**Solution**: 
1. Verify `?sslmode=require` in DATABASE_URL
2. Check Neon project is active
3. Test: `psql $DATABASE_URL -c "SELECT 1;"`

### Issue: "OpenAI API error"
**Solution**:
1. Verify API key is valid
2. Check account has credits
3. Check rate limits

---

## 📚 Full Documentation

Untuk panduan lengkap, lihat:
- **Integration Guide**: `INTEGRATION-GUIDE.md`
- **Deployment Checklist**: `DEPLOYMENT-CHECKLIST.md`
- **Environment Variables**: `03-Configuration/environment-variables.md`
- **Architecture**: `05-Documentation/architecture.md`

---

## 💬 Need Help?

- Check `05-Documentation/troubleshooting.md`
- Review workflow logs in n8n
- Check database with sample queries
- Review Next.js logs in terminal

---

**Version**: 1.0.0  
**Last Updated**: October 20, 2025  
**Maintained by**: LBF Technoglow Team

**Happy Building! 🚀✨**
