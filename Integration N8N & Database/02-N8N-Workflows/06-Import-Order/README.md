# 📋 Import Order & Setup Guide

## Import Sequence

Ikuti urutan ini untuk import workflows ke n8n:

### Step 1: Prepare Environment
```bash
# 1. Set up environment variables
cp .env.example .env
# Edit .env with your credentials

# 2. Verify database connection
psql $DATABASE_URL -c "SELECT 1;"

# 3. Apply database schemas
psql $DATABASE_URL < 01-Database/schema.sql
psql $DATABASE_URL < 01-Database/supplier-pricing-schema.sql

# 4. Create agent_memory table
psql $DATABASE_URL -c "
CREATE TABLE IF NOT EXISTS agent_memory (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    submission_id UUID NOT NULL,
    section_type VARCHAR(50),
    context_data JSONB,
    created_at TIMESTAMP DEFAULT NOW()
);"
```

### Step 2: Configure n8n Credentials

1. **PostgreSQL Database**
   - Name: `LunarAI Database`
   - Host: From `DATABASE_HOST`
   - Database: From `DATABASE_NAME`
   - User: From `DATABASE_USER`
   - Password: From `DATABASE_PASSWORD`
   - SSL: Require

2. **Google AI (Gemini)**
   - Name: `Google AI (Gemini)`
   - API Key: From `GOOGLE_AI_API_KEY`

3. **Tavily Search**
   - Name: `Tavily Search`
   - API Key: From `TAVILY_API_KEY`

### Step 3: Import Workflows (In Order)

#### 3.1 Main Orchestrator (FIRST)
```
Import: 01-Main-Orchestrator/main-orchestrator.json
```
- This is the INDUK workflow
- Must be imported first
- Configure webhook URL
- Note the webhook URL for later

#### 3.2 AI Agent Sections
```
Import in any order:
- 02-AI-Agent-Sections/section-01-product-header.json
- 02-AI-Agent-Sections/section-02-product-description.json
- 02-AI-Agent-Sections/section-03-alternative-names.json
- 02-AI-Agent-Sections/section-06-marketing-copy.json
- 02-AI-Agent-Sections/section-11-next-steps.json
```

For each workflow:
1. Import JSON file
2. Configure credentials (Gemini AI, PostgreSQL)
3. Activate workflow
4. Note webhook URL
5. Test with sample payload

#### 3.3 MCP Sections
```
Import in any order:
- 03-MCP-Sections/section-04-ingredient-breakdown.json
- 03-MCP-Sections/section-07-pricing-structure.json
```

For each workflow:
1. Import JSON file
2. Configure PostgreSQL credentials
3. Activate workflow
4. Note webhook URL
5. Test with sample payload

#### 3.4 Hybrid Sections
```
Import in any order:
- 04-Hybrid-Sections/section-05-market-analysis.json
- 04-Hybrid-Sections/section-08-regulatory-compliance.json
- 04-Hybrid-Sections/section-09-production-timeline.json
- 04-Hybrid-Sections/section-10-sustainability.json
```

For each workflow:
1. Import JSON file
2. Configure all credentials (Gemini, PostgreSQL, Tavily)
3. Activate workflow
4. Note webhook URL
5. Test with sample payload

### Step 4: Update Environment Variables

After all workflows are imported, update `.env` with webhook URLs:

```bash
# Main Orchestrator
N8N_PRODUCTION_WEBHOOK=https://your-n8n.../webhook/lunarai-production

# Section Webhooks
SECTION_1_WEBHOOK=https://your-n8n.../webhook/section-1-product-header
SECTION_2_WEBHOOK=https://your-n8n.../webhook/section-2-product-description
SECTION_3_WEBHOOK=https://your-n8n.../webhook/section-3-alternative-names
SECTION_4_WEBHOOK=https://your-n8n.../webhook/section-4-ingredient-breakdown
SECTION_5_WEBHOOK=https://your-n8n.../webhook/section-5-market-analysis
SECTION_6_WEBHOOK=https://your-n8n.../webhook/section-6-marketing-copy
SECTION_7_WEBHOOK=https://your-n8n.../webhook/section-7-pricing-structure
SECTION_8_WEBHOOK=https://your-n8n.../webhook/section-8-regulatory-compliance
SECTION_9_WEBHOOK=https://your-n8n.../webhook/section-9-production-timeline
SECTION_10_WEBHOOK=https://your-n8n.../webhook/section-10-sustainability
SECTION_11_WEBHOOK=https://your-n8n.../webhook/section-11-next-steps
```

### Step 5: Update Main Orchestrator

1. Open Main Orchestrator workflow
2. Update each HTTP Request node with correct webhook URLs
3. Save workflow

### Step 6: Testing

#### 6.1 Test Individual Sections
```bash
# Test Section 1
curl -X POST $SECTION_1_WEBHOOK \
  -H "Content-Type: application/json" \
  -d @05-Testing/test-section-1.json

# Verify response
# Expected: JSON with sectionType: "productHeader"
```

Repeat for all 11 sections.

#### 6.2 Test Main Orchestrator
```bash
curl -X POST $N8N_PRODUCTION_WEBHOOK \
  -H "Content-Type: application/json" \
  -H "X-Webhook-Secret: $N8N_WEBHOOK_SECRET" \
  -d @05-Testing/test-complete-submission.json
```

Expected:
- Status: 200 OK
- Response: `{"success": true, "submissionId": "..."}`
- Database: Check `submissions` table for new record
- Processing time: ~3.5 minutes

### Step 7: Monitor Execution

1. Open n8n Executions panel
2. Watch Main Orchestrator execution
3. Verify all section workflows triggered
4. Check for errors
5. Review execution time

---

## Troubleshooting

### Issue: Workflow import fails
**Solution**: 
- Check JSON syntax
- Verify n8n version compatibility
- Try importing manually via UI

### Issue: Credentials not found
**Solution**:
- Create credentials first
- Use exact credential names
- Re-link credentials in workflow

### Issue: Webhook not triggering
**Solution**:
- Verify workflow is activated
- Check webhook path is correct
- Test with curl first

### Issue: Database connection fails
**Solution**:
- Verify DATABASE_URL format
- Check SSL mode (require)
- Test connection with psql

### Issue: AI Agent timeout
**Solution**:
- Increase timeout in HTTP Request nodes
- Check Gemini API key
- Verify API quota

---

## Checklist

### Pre-Import
- [ ] Environment variables configured
- [ ] Database schemas applied
- [ ] agent_memory table created
- [ ] n8n credentials configured

### Import
- [ ] Main Orchestrator imported
- [ ] All 5 AI Agent sections imported
- [ ] All 2 MCP sections imported
- [ ] All 4 Hybrid sections imported
- [ ] All workflows activated

### Configuration
- [ ] Webhook URLs noted
- [ ] Environment variables updated
- [ ] Main Orchestrator updated with URLs
- [ ] Credentials linked to all workflows

### Testing
- [ ] Individual section tests passed
- [ ] Main orchestrator test passed
- [ ] Database records created
- [ ] Processing time acceptable
- [ ] No errors in execution logs

### Production
- [ ] Monitoring set up
- [ ] Alerts configured
- [ ] Backup strategy in place
- [ ] Documentation reviewed

---

**Follow this sequence for smooth deployment! 🚀**
