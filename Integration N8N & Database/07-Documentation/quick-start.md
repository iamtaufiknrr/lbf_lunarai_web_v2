# Quick Start Guide - LBF Technoglow Simulator

## 🚀 Get Started in 15 Minutes

### Prerequisites
- Node.js 18+ installed
- PostgreSQL 15+ or Neon account
- n8n instance (cloud or self-hosted)
- API keys (OpenAI, Anthropic, Tavily)

---

## Step 1: Database Setup (5 minutes)

### Option A: Using Neon (Recommended)
```bash
# 1. Create account at neon.tech
# 2. Create new project "lbf-techno"
# 3. Copy connection string

# 4. Run schema
psql "postgresql://..." -f 01-Database/schema.sql

# 5. Verify
psql "postgresql://..." -c "\dt"
```

### Option B: Local PostgreSQL
```bash
# Create database
createdb lbf_techno

# Run schema
psql lbf_techno -f 01-Database/schema.sql

# Verify
psql lbf_techno -c "\dt"
```

---

## Step 2: Environment Configuration (3 minutes)

```bash
# Copy environment template
cp 04-Environment/.env.example .env

# Edit .env with your values
nano .env
```

**Minimum required**:
```env
DATABASE_URL="postgresql://..."
N8N_TEST_WEBHOOK="https://..."
N8N_WEBHOOK_SECRET="your-secret-32-chars"
OPENAI_API_KEY="sk-..."
ANTHROPIC_API_KEY="sk-ant-..."
TAVILY_API_KEY="tvly-..."
```

---

## Step 3: n8n Setup (5 minutes)

### Import Workflows
```bash
# Login to n8n dashboard
# Go to Workflows → Import from File

# Import these files in order:
1. 02-N8N-Workflows/main-processor.json
2. 02-N8N-Workflows/formulation-agent.json
3. 02-N8N-Workflows/market-research-agent.json
4. 02-N8N-Workflows/copywriting-agent.json
5. 02-N8N-Workflows/compliance-agent.json
6. 02-N8N-Workflows/final-aggregation.json
7. 02-N8N-Workflows/error-handler.json
```

### Configure Credentials
1. **PostgreSQL**:
   - Host: Your Neon host
   - Database: lbf_techno
   - User: Your username
   - Password: Your password
   - SSL: Enabled

2. **OpenAI**:
   - API Key: Your OpenAI key

3. **Anthropic**:
   - API Key: Your Anthropic key

### Activate Workflows
- Click on each workflow
- Click "Active" toggle
- Verify webhook URLs

---

## Step 4: Test (2 minutes)

### Test Webhook
```bash
curl -X POST https://your-n8n-instance.app/webhook-test/lbf-simulator \
  -H "Content-Type: application/json" \
  -H "X-Webhook-Secret: your-secret" \
  -d @05-Testing/test-payload.json
```

### Check Results
```sql
-- Check submission created
SELECT * FROM submissions ORDER BY created_at DESC LIMIT 1;

-- Check workflow status
SELECT * FROM workflow_runs ORDER BY created_at DESC LIMIT 1;

-- Check report sections
SELECT section_type, created_at 
FROM report_sections 
WHERE submission_id = 'your-submission-id'
ORDER BY "order";
```

---

## Step 5: Integration with Next.js App

### Update Application .env
```env
N8N_TEST_WEBHOOK="https://your-n8n-instance.app/webhook-test/lbf-simulator"
N8N_PRODUCTION_WEBHOOK="https://your-n8n-instance.app/webhook/lbf-simulator"
N8N_WEBHOOK_SECRET="your-secret"
```

### Test from Application
```bash
# Start Next.js app
npm run dev

# Open http://localhost:3000
# Fill form and submit
# Check workflow execution in n8n
```

---

## Common Issues & Solutions

### Issue: Database connection failed
```bash
# Test connection
psql "$DATABASE_URL" -c "SELECT 1;"

# Check SSL mode
# Neon requires: ?sslmode=require
```

### Issue: Webhook not receiving data
```bash
# Verify webhook URL
echo $N8N_TEST_WEBHOOK

# Test with curl
curl -v -X POST $N8N_TEST_WEBHOOK -d '{"test": true}'

# Check n8n logs
docker logs n8n-container
```

### Issue: AI API errors
```bash
# Test OpenAI key
curl https://api.openai.com/v1/models \
  -H "Authorization: Bearer $OPENAI_API_KEY"

# Test Anthropic key
curl https://api.anthropic.com/v1/messages \
  -H "x-api-key: $ANTHROPIC_API_KEY" \
  -H "anthropic-version: 2023-06-01" \
  -H "content-type: application/json" \
  -d '{"model":"claude-3-5-sonnet-20241022","max_tokens":1024,"messages":[{"role":"user","content":"Hello"}]}'
```

---

## Next Steps

### 1. Customize Workflows
- Adjust AI prompts
- Add more agents
- Customize report sections
- Implement caching

### 2. Optimize Performance
- Add database indexes
- Implement caching
- Configure rate limiting
- Setup monitoring

### 3. Production Deployment
- Follow deployment checklist
- Setup monitoring
- Configure backups
- Enable SSL

### 4. Monitor & Maintain
- Check error logs daily
- Review performance metrics
- Optimize slow queries
- Update documentation

---

## Useful Commands

### Database
```bash
# Connect to database
psql "$DATABASE_URL"

# Run migrations
npm run db:migrate

# Open database UI
npm run db:studio

# Backup database
./01-Database/backup-restore.sh backup

# Restore database
./01-Database/backup-restore.sh restore backup_file.sql.gz
```

### n8n
```bash
# Start n8n (Docker)
docker run -d --name n8n -p 5678:5678 n8nio/n8n

# View logs
docker logs n8n -f

# Import workflow
n8n import:workflow --input=workflow.json

# Export workflow
n8n export:workflow --id=1 --output=workflow.json
```

### Testing
```bash
# Run all tests
./05-Testing/run-tests.sh

# Test specific endpoint
curl -X POST $N8N_TEST_WEBHOOK \
  -H "Content-Type: application/json" \
  -d @test-payload.json

# Check database
psql "$DATABASE_URL" -f 01-Database/sample-queries.sql
```

---

## Resources

### Documentation
- [Full Documentation](./README.md)
- [Database Schema](../01-Database/schema.sql)
- [Testing Guide](../05-Testing/testing-guide.md)
- [Deployment Guide](../06-Deployment/deployment-checklist.md)

### External Links
- [n8n Documentation](https://docs.n8n.io)
- [Neon Documentation](https://neon.tech/docs)
- [OpenAI API](https://platform.openai.com/docs)
- [Anthropic API](https://docs.anthropic.com)

### Support
- GitHub Issues: [Your Repo]
- Email: support@your-domain.com
- Slack: your-workspace.slack.com

---

## Success Checklist

- [ ] Database created and schema applied
- [ ] Environment variables configured
- [ ] n8n workflows imported and active
- [ ] Credentials configured
- [ ] Test payload submitted successfully
- [ ] Workflow executed without errors
- [ ] Report sections generated
- [ ] Application integrated
- [ ] Monitoring setup
- [ ] Documentation reviewed

---

**Congratulations! 🎉**

Your LBF Technoglow Simulator is now ready to use!

For detailed information, refer to the complete documentation in each folder.
