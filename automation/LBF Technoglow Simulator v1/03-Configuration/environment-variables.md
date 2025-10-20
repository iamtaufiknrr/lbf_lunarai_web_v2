# 🔐 Environment Variables Configuration

## 📋 Overview

Panduan lengkap untuk konfigurasi environment variables di semua komponen sistem.

---

## 🎯 Required Variables

### Next.js Application (Vercel / Bolt.new)

#### Database Configuration
```env
# Neon Postgres Connection
DATABASE_URL=postgresql://user:password@host.neon.tech/dbname?sslmode=require
```

**Format Explanation**:
- `user`: Your Neon database username
- `password`: Your Neon database password
- `host`: Your Neon host (e.g., `ep-cool-darkness-123456.us-east-2.aws.neon.tech`)
- `dbname`: Your database name
- `?sslmode=require`: **REQUIRED** for Neon connections

**How to Get**:
1. Go to [Neon Console](https://console.neon.tech)
2. Select your project
3. Go to **Connection Details**
4. Copy **Connection string**
5. Ensure `?sslmode=require` is appended

---

#### n8n Webhook Configuration
```env
# Production Webhook (for real submissions)
N8N_PRODUCTION_WEBHOOK=https://your-n8n-instance.app.n8n.cloud/webhook/lbf-simulator

# Test Webhook (for testing)
N8N_TEST_WEBHOOK=https://your-n8n-instance.app.n8n.cloud/webhook-test/lbf-simulator

# Webhook Secret (for signature verification)
N8N_WEBHOOK_SECRET=your-strong-secret-key-min-32-characters
```

**How to Get Webhook URLs**:
1. Login to n8n dashboard
2. Open **Main Orchestrator** workflow
3. Click on **Webhook Receiver** node
4. Copy **Production URL** and **Test URL**

**Generate Strong Secret**:
```bash
# Using OpenSSL
openssl rand -base64 32

# Using Node.js
node -e "console.log(require('crypto').randomBytes(32).toString('base64'))"

# Using Python
python -c "import secrets; print(secrets.token_urlsafe(32))"
```

---

#### Application Configuration
```env
# App Version (for tracking)
NEXT_PUBLIC_APP_VERSION=1.0.0

# Form Schema Version (for compatibility)
NEXT_PUBLIC_FORM_VERSION=1.0.0

# Default Language (id or en)
NEXT_PUBLIC_DEFAULT_LANGUAGE=id

# API Base URL (for n8n callback)
NEXT_PUBLIC_API_URL=https://your-app.vercel.app
```

**Notes**:
- `NEXT_PUBLIC_*` variables are exposed to browser
- `NEXT_PUBLIC_API_URL` should be your production domain
- For local development, use `http://localhost:3004`

---

### n8n Configuration

#### Environment Variables in n8n
```env
# Webhook Secret (must match Next.js)
N8N_WEBHOOK_SECRET=your-strong-secret-key-min-32-characters

# Database Connection (same as Next.js)
DATABASE_URL=postgresql://user:password@host.neon.tech/dbname?sslmode=require

# OpenAI API Key
OPENAI_API_KEY=sk-proj-...

# Anthropic API Key
ANTHROPIC_API_KEY=sk-ant-api03-...

# Tavily API Key (for web search)
TAVILY_API_KEY=tvly-...

# Next.js Callback URL
NEXT_PUBLIC_API_URL=https://your-app.vercel.app
```

**How to Set in n8n Cloud**:
1. Go to **Settings** → **Environment Variables**
2. Add each variable
3. Save and restart workflows

**How to Set in Self-Hosted n8n**:
```bash
# In docker-compose.yml
environment:
  - N8N_WEBHOOK_SECRET=your-secret
  - DATABASE_URL=postgresql://...
  - OPENAI_API_KEY=sk-...
  - ANTHROPIC_API_KEY=sk-ant-...
  - TAVILY_API_KEY=tvly-...
  - NEXT_PUBLIC_API_URL=https://...
```

---

## 🔑 API Keys Setup

### OpenAI API Key

**Purpose**: Used by Formulation, Market Research, Compliance, and Pricing agents

**How to Get**:
1. Go to [OpenAI Platform](https://platform.openai.com)
2. Sign up / Login
3. Go to **API Keys**
4. Click **Create new secret key**
5. Copy key (starts with `sk-proj-...`)
6. **IMPORTANT**: Save immediately (can't view again)

**Recommended Settings**:
- Model: `gpt-4-turbo-preview` or `gpt-4-1106-preview`
- Usage limits: Set monthly budget
- Rate limits: Default is fine for most use cases

**Cost Estimation**:
- ~$0.12 per submission
- 100 submissions = ~$12

---

### Anthropic API Key

**Purpose**: Used by Copywriting agent (Claude 3.5 Sonnet)

**How to Get**:
1. Go to [Anthropic Console](https://console.anthropic.com)
2. Sign up / Login
3. Go to **API Keys**
4. Click **Create Key**
5. Copy key (starts with `sk-ant-api03-...`)

**Recommended Settings**:
- Model: `claude-3-5-sonnet-20241022`
- Usage limits: Set monthly budget

**Cost Estimation**:
- ~$0.05 per submission
- 100 submissions = ~$5

---

### Tavily API Key (Optional)

**Purpose**: Used by Market Research agent for web search

**How to Get**:
1. Go to [Tavily](https://tavily.com)
2. Sign up / Login
3. Go to **API Keys**
4. Copy key (starts with `tvly-...`)

**Recommended Settings**:
- Plan: Free tier (1000 searches/month) or Pro
- Search depth: Basic (faster) or Advanced (more comprehensive)

**Cost Estimation**:
- Free tier: $0
- Pro: ~$0.03 per submission
- 100 submissions = ~$3

**Alternative**: If not using Tavily, Market Research agent will use GPT-4 only (less comprehensive but still functional)

---

## 📝 Configuration Files

### .env.local (Next.js Development)

Create `apps/bolt-vercel/.env.local`:

```env
# ============================================================================
# LBF Technoglow Simulator - Environment Variables
# ============================================================================

# ----------------------------------------------------------------------------
# Database Configuration
# ----------------------------------------------------------------------------
DATABASE_URL=postgresql://user:password@host.neon.tech/dbname?sslmode=require

# ----------------------------------------------------------------------------
# n8n Webhook Configuration
# ----------------------------------------------------------------------------
N8N_PRODUCTION_WEBHOOK=https://your-n8n.app.n8n.cloud/webhook/lbf-simulator
N8N_TEST_WEBHOOK=https://your-n8n.app.n8n.cloud/webhook-test/lbf-simulator
N8N_WEBHOOK_SECRET=your-strong-secret-key-min-32-characters

# ----------------------------------------------------------------------------
# Application Configuration
# ----------------------------------------------------------------------------
NEXT_PUBLIC_APP_VERSION=1.0.0
NEXT_PUBLIC_FORM_VERSION=1.0.0
NEXT_PUBLIC_DEFAULT_LANGUAGE=id
NEXT_PUBLIC_API_URL=http://localhost:3004

# ----------------------------------------------------------------------------
# Optional: Analytics
# ----------------------------------------------------------------------------
# ANALYTICS_ENDPOINT=https://your-analytics-service.com/api/events
```

---

### .env.production (Vercel Production)

**Set in Vercel Dashboard**:
1. Go to your project in Vercel
2. Go to **Settings** → **Environment Variables**
3. Add each variable:

| Variable | Value | Environment |
|----------|-------|-------------|
| `DATABASE_URL` | `postgresql://...` | Production |
| `N8N_PRODUCTION_WEBHOOK` | `https://...` | Production |
| `N8N_TEST_WEBHOOK` | `https://...` | Production |
| `N8N_WEBHOOK_SECRET` | `your-secret` | Production |
| `NEXT_PUBLIC_APP_VERSION` | `1.0.0` | Production |
| `NEXT_PUBLIC_FORM_VERSION` | `1.0.0` | Production |
| `NEXT_PUBLIC_DEFAULT_LANGUAGE` | `id` | Production |
| `NEXT_PUBLIC_API_URL` | `https://your-app.vercel.app` | Production |

---

### n8n Environment Variables

**n8n Cloud**:
1. Go to **Settings** → **Environment Variables**
2. Add:

```
N8N_WEBHOOK_SECRET=your-secret
DATABASE_URL=postgresql://...
OPENAI_API_KEY=sk-proj-...
ANTHROPIC_API_KEY=sk-ant-...
TAVILY_API_KEY=tvly-...
NEXT_PUBLIC_API_URL=https://your-app.vercel.app
```

**Self-Hosted n8n** (`docker-compose.yml`):
```yaml
version: '3.8'

services:
  n8n:
    image: n8nio/n8n:latest
    restart: always
    ports:
      - "5678:5678"
    environment:
      - N8N_WEBHOOK_SECRET=your-secret
      - DATABASE_URL=postgresql://...
      - OPENAI_API_KEY=sk-proj-...
      - ANTHROPIC_API_KEY=sk-ant-...
      - TAVILY_API_KEY=tvly-...
      - NEXT_PUBLIC_API_URL=https://your-app.vercel.app
      - N8N_BASIC_AUTH_ACTIVE=true
      - N8N_BASIC_AUTH_USER=admin
      - N8N_BASIC_AUTH_PASSWORD=your-password
    volumes:
      - ~/.n8n:/home/node/.n8n
```

---

## 🔒 Security Best Practices

### 1. Never Commit Secrets to Git

**Add to `.gitignore`**:
```gitignore
# Environment variables
.env
.env.local
.env.production
.env.*.local

# Sensitive files
*.pem
*.key
secrets/
```

### 2. Use Strong Secrets

**Minimum Requirements**:
- Length: 32+ characters
- Include: uppercase, lowercase, numbers, special characters
- Avoid: dictionary words, personal info, sequential patterns

**Generate Strong Secrets**:
```bash
# 32-character random string
openssl rand -base64 32

# 64-character random string
openssl rand -base64 64
```

### 3. Rotate Secrets Regularly

**Recommended Schedule**:
- Webhook secrets: Every 90 days
- API keys: Every 180 days
- Database passwords: Every 180 days

**Rotation Procedure**:
1. Generate new secret
2. Update in all environments
3. Test thoroughly
4. Revoke old secret
5. Document change

### 4. Limit API Key Permissions

**OpenAI**:
- Set usage limits
- Enable rate limiting
- Monitor usage regularly

**Anthropic**:
- Set monthly budget
- Enable alerts
- Review usage logs

**Database**:
- Use separate users for different environments
- Grant minimal required permissions
- Enable audit logging

---

## 🧪 Testing Configuration

### Verify Environment Variables

**Next.js**:
```bash
# Check if variables are loaded
cd apps/bolt-vercel
npm run dev

# In browser console:
console.log(process.env.NEXT_PUBLIC_API_URL)
```

**n8n**:
1. Create test workflow
2. Add **Code** node
3. Test:
```javascript
return {
  webhookSecret: $env.N8N_WEBHOOK_SECRET ? 'Set' : 'Not set',
  databaseUrl: $env.DATABASE_URL ? 'Set' : 'Not set',
  openaiKey: $env.OPENAI_API_KEY ? 'Set' : 'Not set',
};
```

### Test Database Connection

```bash
# Test from command line
psql $DATABASE_URL -c "SELECT version();"

# Expected output: PostgreSQL version info
```

### Test Webhook

```bash
# Test webhook endpoint
curl -X POST $N8N_TEST_WEBHOOK \
  -H "Content-Type: application/json" \
  -H "X-Webhook-Secret: $N8N_WEBHOOK_SECRET" \
  -d '{"test": true}'

# Expected: 200 OK response
```

---

## 🆘 Troubleshooting

### Issue: "DATABASE_URL not found"

**Solution**:
1. Check `.env.local` exists in `apps/bolt-vercel/`
2. Verify variable name is exactly `DATABASE_URL`
3. Restart dev server: `npm run dev`

### Issue: "Invalid webhook signature"

**Solution**:
1. Verify `N8N_WEBHOOK_SECRET` matches in both Next.js and n8n
2. Check for extra spaces or newlines
3. Regenerate secret if needed

### Issue: "OpenAI API key invalid"

**Solution**:
1. Verify key starts with `sk-proj-` or `sk-`
2. Check key hasn't been revoked
3. Verify account has credits
4. Regenerate key if needed

### Issue: "Connection refused" (Database)

**Solution**:
1. Verify `?sslmode=require` in connection string
2. Check Neon project is active
3. Verify IP whitelist (if configured)
4. Test connection: `psql $DATABASE_URL -c "SELECT 1;"`

---

## 📚 Additional Resources

- [Vercel Environment Variables](https://vercel.com/docs/concepts/projects/environment-variables)
- [n8n Environment Variables](https://docs.n8n.io/hosting/environment-variables/)
- [Neon Connection Strings](https://neon.tech/docs/connect/connect-from-any-app)
- [OpenAI API Keys](https://platform.openai.com/api-keys)
- [Anthropic API Keys](https://console.anthropic.com/settings/keys)

---

**Version**: 1.0.0  
**Last Updated**: October 20, 2025  
**Maintained by**: LBF Technoglow Team
