# 🔗 Integration Guide - LBF Technoglow Simulator v1

## 📋 Overview

Panduan lengkap untuk mengintegrasikan n8n workflow dengan Next.js application (apps/bolt-vercel).

**Tujuan**: Membuat sistem end-to-end yang seamless dari form submission hingga report generation.

---

## 🎯 Integration Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        USER INTERFACE                            │
│                    (Next.js App - Vercel)                        │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         │ 1. Form Submit
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                    API Route: /api/submit                        │
│  • Validate payload (Zod schema)                                │
│  • Save to database (submissions, submission_payloads)          │
│  • Dispatch to n8n webhook                                      │
│  • Return submissionId to user                                  │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         │ 2. Webhook POST
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                    n8n MAIN ORCHESTRATOR                         │
│  • Validate webhook signature                                   │
│  • Update submission status to "running"                        │
│  • Route to specialized agents                                  │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         │ 3. Parallel Execution
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                      AI AGENTS (Parallel)                        │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐         │
│  │ Formulation  │  │   Market     │  │ Copywriting  │         │
│  │    Agent     │  │   Research   │  │    Agent     │         │
│  │  (GPT-4)     │  │ (GPT-4+Web)  │  │  (Claude)    │         │
│  └──────────────┘  └──────────────┘  └──────────────┘         │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         │ 4. Sequential Execution
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                   AI AGENTS (Sequential)                         │
│  ┌──────────────┐  ┌──────────────┐                            │
│  │ Compliance   │  │   Pricing    │                            │
│  │    Agent     │  │    Agent     │                            │
│  │  (GPT-4)     │  │ (GPT-4+DB)   │                            │
│  └──────────────┘  └──────────────┘                            │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         │ 5. Aggregation
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                    FINAL AGGREGATOR                              │
│  • Merge all agent results                                      │
│  • Validate completeness                                        │
│  • Format report sections                                       │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         │ 6. Callback POST
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                   API Route: /api/sync                           │
│  • Receive report sections                                      │
│  • Save to database (report_sections)                           │
│  • Update submission status to "completed"                      │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         │ 7. User Polls Status
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                 API Route: /api/result/[id]                      │
│  • Fetch submission data                                        │
│  • Fetch report sections                                        │
│  • Return complete report                                       │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                    USER SEES REPORT                              │
│                  (Result Page - Next.js)                         │
└─────────────────────────────────────────────────────────────────┘
```

---

## 🔧 Step-by-Step Integration

### Phase 1: Database Setup

#### 1.1 Connect to Neon Database
```bash
# Set your DATABASE_URL
export DATABASE_URL="postgresql://user:password@host.neon.tech/dbname?sslmode=require"

# Test connection
psql $DATABASE_URL -c "SELECT version();"
```

#### 1.2 Run Schema Scripts
```bash
# Navigate to database folder
cd "automation/LBF Technoglow Simulator v1/02-Database"

# Run main schema
psql $DATABASE_URL -f schema.sql

# Verify tables created
psql $DATABASE_URL -c "\dt"
```

Expected output:
```
                List of relations
 Schema |         Name          | Type  |  Owner
--------+-----------------------+-------+---------
 public | audit_logs            | table | user
 public | report_sections       | table | user
 public | submission_payloads   | table | user
 public | submissions           | table | user
 public | workflow_runs         | table | user
```

---

### Phase 2: n8n Configuration

#### 2.1 Setup n8n Instance

**Option A: n8n Cloud** (Recommended)
1. Sign up at https://n8n.io
2. Create new workspace
3. Note your webhook base URL: `https://your-instance.app.n8n.cloud`

**Option B: Self-Hosted**
```bash
# Using Docker
docker run -it --rm \
  --name n8n \
  -p 5678:5678 \
  -v ~/.n8n:/home/node/.n8n \
  n8nio/n8n
```

#### 2.2 Configure Credentials

**PostgreSQL Credential**:
1. Go to **Credentials** → **New**
2. Select **Postgres**
3. Fill in:
   - Host: `your-host.neon.tech`
   - Database: `your-database`
   - User: `your-user`
   - Password: `your-password`
   - SSL: `require`
4. Test connection
5. Save as "Neon Postgres"

**OpenAI Credential**:
1. Go to **Credentials** → **New**
2. Select **OpenAI**
3. API Key: `sk-...`
4. Save as "OpenAI GPT-4"

**Anthropic Credential**:
1. Go to **Credentials** → **New**
2. Select **Anthropic**
3. API Key: `sk-ant-...`
4. Save as "Anthropic Claude"

#### 2.3 Import Workflows

**IMPORTANT**: Import dalam urutan ini!

```bash
cd "automation/LBF Technoglow Simulator v1/01-Workflows"
```

1. **Main Orchestrator** (PERTAMA)
   - File: `00-main-orchestrator.json`
   - Import via n8n UI: **Workflows** → **Import from File**
   - Configure webhook path: `/webhook/lbf-simulator`
   - Activate workflow

2. **Formulation Agent**
   - File: `01-formulation-agent.json`
   - Configure OpenAI credential
   - Activate workflow

3. **Market Research Agent**
   - File: `02-market-research-agent.json`
   - Configure OpenAI + Tavily credentials
   - Activate workflow

4. **Copywriting Agent**
   - File: `03-copywriting-agent.json`
   - Configure Anthropic credential
   - Activate workflow

5. **Compliance Agent**
   - File: `04-compliance-agent.json`
   - Configure OpenAI credential
   - Activate workflow

6. **Pricing Agent**
   - File: `05-pricing-agent.json`
   - Configure OpenAI + PostgreSQL credentials
   - Activate workflow

7. **Final Aggregator**
   - File: `06-final-aggregator.json`
   - Configure PostgreSQL credential
   - Set callback URL to your Next.js app
   - Activate workflow

8. **Error Handler**
   - File: `07-error-handler.json`
   - Configure notification settings
   - Activate workflow

#### 2.4 Get Webhook URLs

After importing Main Orchestrator:
1. Open workflow
2. Click on "Webhook Receiver" node
3. Copy **Production URL**: `https://your-n8n.com/webhook/lbf-simulator`
4. Copy **Test URL**: `https://your-n8n.com/webhook-test/lbf-simulator`

---

### Phase 3: Next.js App Configuration

#### 3.1 Update Environment Variables

Edit `apps/bolt-vercel/.env.local`:

```env
# Database
DATABASE_URL=postgresql://user:password@host.neon.tech/dbname?sslmode=require

# n8n Webhooks
N8N_PRODUCTION_WEBHOOK=https://your-n8n.com/webhook/lbf-simulator
N8N_TEST_WEBHOOK=https://your-n8n.com/webhook-test/lbf-simulator
N8N_WEBHOOK_SECRET=your-secret-key-here

# App Configuration
NEXT_PUBLIC_APP_VERSION=1.0.0
NEXT_PUBLIC_FORM_VERSION=1.0.0
NEXT_PUBLIC_DEFAULT_LANGUAGE=id

# API Base URL (for n8n callback)
NEXT_PUBLIC_API_URL=https://your-app.vercel.app
```

#### 3.2 Verify API Routes

Check these files exist and are configured:
- ✅ `apps/bolt-vercel/src/app/api/submit/route.ts`
- ✅ `apps/bolt-vercel/src/app/api/sync/route.ts`
- ✅ `apps/bolt-vercel/src/app/api/result/[id]/route.ts`

#### 3.3 Test Database Connection

```bash
cd apps/bolt-vercel

# Run migration (if using Drizzle)
npm run db:migrate

# Test connection
npm run db:studio
```

---

### Phase 4: Testing Integration

#### 4.1 Test Database Connectivity

```bash
# From n8n, test PostgreSQL node
# Query: SELECT 1 AS test;
# Expected: Returns 1
```

#### 4.2 Test Webhook Endpoint

```bash
# Test with curl
curl -X POST https://your-n8n.com/webhook-test/lbf-simulator \
  -H "Content-Type: application/json" \
  -H "X-Webhook-Secret: your-secret-key" \
  -d @"automation/LBF Technoglow Simulator v1/04-Testing/test-payload.json"
```

Expected response:
```json
{
  "success": true,
  "submissionId": "550e8400-e29b-41d4-a716-446655440000",
  "message": "Submission received and processing started",
  "status": "running",
  "timestamp": "2025-10-20T10:30:00.000Z",
  "estimatedCompletionTime": "3-4 minutes"
}
```

#### 4.3 Test End-to-End Flow

1. **Submit Form via Next.js App**:
   - Go to `http://localhost:3004` (or your deployed URL)
   - Fill out the form
   - Submit

2. **Monitor n8n Execution**:
   - Go to n8n dashboard
   - Check **Executions** tab
   - Verify all agents executed successfully

3. **Check Database**:
```sql
-- Check submission created
SELECT * FROM submissions ORDER BY created_at DESC LIMIT 1;

-- Check workflow run
SELECT * FROM workflow_runs ORDER BY created_at DESC LIMIT 1;

-- Check report sections
SELECT section_type, created_at 
FROM report_sections 
WHERE submission_id = 'your-submission-id'
ORDER BY "order";
```

4. **View Result**:
   - Go to `/result/[submissionId]` in your app
   - Verify all report sections displayed

---

## 🔐 Security Configuration

### Webhook Signature Verification

**In n8n (Main Orchestrator)**:
```javascript
const secret = $env.N8N_WEBHOOK_SECRET;
const receivedSecret = $input.item.json.headers['x-webhook-secret'];

if (receivedSecret !== secret) {
  throw new Error('Invalid webhook signature');
}
```

**In Next.js (api/submit)**:
```typescript
const webhookSecret = process.env.N8N_WEBHOOK_SECRET;

const response = await fetch(webhookUrl, {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'X-Webhook-Secret': webhookSecret,
  },
  body: JSON.stringify(payload),
});
```

### Environment-Based Routing

```typescript
// In Next.js
const webhookUrl = payload.targetEnvironment === 'test'
  ? process.env.N8N_TEST_WEBHOOK
  : process.env.N8N_PRODUCTION_WEBHOOK;
```

---

## 📊 Monitoring & Debugging

### Check Submission Status

```sql
-- Get submission with all details
SELECT * FROM v_submission_details 
WHERE id = 'your-submission-id';

-- Get recent submissions
SELECT * FROM v_recent_submissions;

-- Check workflow execution
SELECT 
  s.id,
  s.brand_name,
  s.status,
  wr.status AS workflow_status,
  wr.retry_count,
  wr.last_error,
  COUNT(rs.id) AS sections_count
FROM submissions s
LEFT JOIN workflow_runs wr ON s.id = wr.submission_id
LEFT JOIN report_sections rs ON s.id = rs.submission_id
WHERE s.id = 'your-submission-id'
GROUP BY s.id, wr.status, wr.retry_count, wr.last_error;
```

### n8n Execution Logs

1. Go to n8n dashboard
2. Click **Executions**
3. Filter by workflow name
4. Click on execution to see detailed logs
5. Check each node's input/output

### Next.js Logs

```bash
# Development
npm run dev

# Production (Vercel)
# Check Vercel dashboard → Logs
```

---

## 🆘 Troubleshooting

### Issue 1: Webhook Not Receiving Data

**Symptoms**: n8n workflow not triggered

**Solutions**:
1. Verify webhook URL correct in `.env.local`
2. Check webhook secret matches
3. Test with curl:
```bash
curl -X POST $N8N_TEST_WEBHOOK \
  -H "Content-Type: application/json" \
  -H "X-Webhook-Secret: $N8N_WEBHOOK_SECRET" \
  -d '{"test": true}'
```

### Issue 2: Database Connection Error

**Symptoms**: "Connection refused" or "SSL required"

**Solutions**:
1. Verify `DATABASE_URL` format:
```
postgresql://user:password@host.neon.tech/dbname?sslmode=require
```
2. Test connection:
```bash
psql $DATABASE_URL -c "SELECT 1;"
```
3. Check Neon project status

### Issue 3: AI API Errors

**Symptoms**: "Rate limit exceeded" or "Invalid API key"

**Solutions**:
1. Verify API keys in n8n credentials
2. Check account balance
3. Check rate limits
4. Add retry logic in workflows

### Issue 4: Report Sections Not Saving

**Symptoms**: Workflow completes but no sections in database

**Solutions**:
1. Check Final Aggregator workflow logs
2. Verify callback URL correct
3. Check `/api/sync` endpoint logs
4. Verify report_sections table exists:
```sql
SELECT * FROM report_sections LIMIT 1;
```

---

## ✅ Integration Checklist

### Database
- [ ] Neon Postgres database created
- [ ] `schema.sql` executed successfully
- [ ] All tables created (5 tables)
- [ ] All indexes created
- [ ] All views created (2 views)
- [ ] Connection tested from n8n

### n8n
- [ ] n8n instance running (cloud or self-hosted)
- [ ] PostgreSQL credential configured
- [ ] OpenAI credential configured
- [ ] Anthropic credential configured
- [ ] All 8 workflows imported
- [ ] All workflows activated
- [ ] Webhook URLs copied
- [ ] Test webhook successful

### Next.js App
- [ ] `.env.local` configured with all variables
- [ ] Database connection tested
- [ ] Migrations run (if applicable)
- [ ] API routes verified
- [ ] Test submission successful
- [ ] Result page displays correctly

### End-to-End
- [ ] Form submission triggers n8n workflow
- [ ] All agents execute successfully
- [ ] Report sections saved to database
- [ ] Callback to `/api/sync` successful
- [ ] User can view complete report
- [ ] Audit logs created

---

## 📚 Additional Resources

- **Workflow Logic**: `05-Documentation/workflow-logic.md`
- **AI Prompts**: `05-Documentation/ai-prompts.md`
- **Troubleshooting**: `05-Documentation/troubleshooting.md`
- **Architecture**: `05-Documentation/architecture.md`

---

## 🎉 Success!

Jika semua checklist di atas sudah ✅, maka integrasi Anda sudah berhasil!

**Next Steps**:
1. Test dengan berbagai skenario
2. Monitor performance metrics
3. Optimize AI prompts jika diperlukan
4. Setup monitoring & alerts
5. Deploy to production

---

**Version**: 1.0.0  
**Last Updated**: October 20, 2025  
**Maintained by**: LBF Technoglow Team
