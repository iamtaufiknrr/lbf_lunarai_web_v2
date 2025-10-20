# LBF Technoglow Simulator v1 - Complete n8n Workflow Package

## 📋 Overview

Package lengkap workflow n8n untuk **LBF Technoglow Simulator** - sistem AI-powered product development untuk industri kosmetik Indonesia.

**Version**: 1.0.0  
**Created**: October 20, 2025  
**Compatible with**: Next.js App (apps/bolt-vercel)

---

## 📁 Struktur Folder

```
LBF Technoglow Simulator v1/
│
├── README.md                           ← File ini
├── INTEGRATION-GUIDE.md                ← Panduan integrasi lengkap
├── DEPLOYMENT-CHECKLIST.md             ← Checklist deployment
│
├── 01-Workflows/                       ← n8n Workflow JSON files
│   ├── 00-main-orchestrator.json       ← Main workflow (import pertama)
│   ├── 01-formulation-agent.json       ← Formulation analysis agent
│   ├── 02-market-research-agent.json   ← Market research agent
│   ├── 03-copywriting-agent.json       ← Copywriting agent
│   ├── 04-compliance-agent.json        ← Regulatory compliance agent
│   ├── 05-pricing-agent.json           ← Pricing & costing agent
│   ├── 06-final-aggregator.json        ← Final aggregation & callback
│   └── 07-error-handler.json           ← Error handling workflow
│
├── 02-Database/                        ← Database scripts
│   ├── schema.sql                      ← Main database schema
│   ├── supplier-pricing-schema.sql     ← Supplier & pricing tables
│   ├── sample-data.sql                 ← Sample data untuk testing
│   ├── indexes.sql                     ← Performance indexes
│   └── views.sql                       ← Database views
│
├── 03-Configuration/                   ← Configuration files
│   ├── environment-variables.md        ← Environment setup guide
│   ├── api-credentials.md              ← API keys & credentials
│   ├── webhook-setup.md                ← Webhook configuration
│   └── mcp-config.json                 ← MCP servers configuration
│
├── 04-Testing/                         ← Testing resources
│   ├── test-payload.json               ← Complete test payload
│   ├── test-scenarios.md               ← Test scenarios
│   └── validation-checklist.md         ← Validation checklist
│
└── 05-Documentation/                   ← Additional documentation
    ├── architecture.md                 ← System architecture
    ├── workflow-logic.md               ← Workflow logic explanation
    ├── ai-prompts.md                   ← AI agent prompts
    └── troubleshooting.md              ← Common issues & solutions
```

---

## 🚀 Quick Start

### Prerequisites
- ✅ n8n instance (cloud atau self-hosted)
- ✅ Neon Postgres database
- ✅ OpenAI API key (GPT-4)
- ✅ Anthropic API key (Claude 3.5)
- ✅ Tavily API key (optional, untuk market research)
- ✅ Next.js app deployed (apps/bolt-vercel)

### Installation Steps

#### 1. Setup Database
```bash
# Connect to your Neon database
psql $DATABASE_URL

# Run schema
\i 02-Database/schema.sql
\i 02-Database/supplier-pricing-schema.sql
\i 02-Database/sample-data.sql
\i 02-Database/indexes.sql
\i 02-Database/views.sql
```

#### 2. Configure Environment
Lihat file `03-Configuration/environment-variables.md` untuk detail lengkap.

Required variables:
```env
DATABASE_URL=postgresql://user:pass@host/db?sslmode=require
N8N_PRODUCTION_WEBHOOK=https://your-n8n.com/webhook/lbf-simulator
N8N_TEST_WEBHOOK=https://your-n8n.com/webhook-test/lbf-simulator
N8N_WEBHOOK_SECRET=your-secret-key
OPENAI_API_KEY=sk-...
ANTHROPIC_API_KEY=sk-ant-...
TAVILY_API_KEY=tvly-...
NEXT_PUBLIC_API_URL=https://your-app.vercel.app
```

#### 3. Import Workflows ke n8n

**PENTING**: Import dalam urutan ini!

1. Login ke n8n dashboard
2. Go to **Workflows** → **Import from File**
3. Import workflows dalam urutan:
   - `00-main-orchestrator.json` (PERTAMA)
   - `01-formulation-agent.json`
   - `02-market-research-agent.json`
   - `03-copywriting-agent.json`
   - `04-compliance-agent.json`
   - `05-pricing-agent.json`
   - `06-final-aggregator.json`
   - `07-error-handler.json`

4. Untuk setiap workflow:
   - Configure credentials (PostgreSQL, OpenAI, Anthropic)
   - Update webhook URLs
   - Activate workflow

#### 4. Test Integration
```bash
# Test dengan payload contoh
curl -X POST $N8N_TEST_WEBHOOK \
  -H "Content-Type: application/json" \
  -H "X-Webhook-Secret: $N8N_WEBHOOK_SECRET" \
  -d @04-Testing/test-payload.json
```

---

## 🔄 Workflow Architecture

### Main Flow
```
User Submit Form (Next.js)
        ↓
POST /api/submit
        ↓
Save to Database
        ↓
Trigger n8n Webhook
        ↓
┌─────────────────────────────────────┐
│   Main Orchestrator                 │
│   - Validate payload                │
│   - Update status to "running"      │
│   - Route to agents                 │
└─────────────────────────────────────┘
        ↓
┌─────────────────────────────────────┐
│   PARALLEL EXECUTION (2 min)        │
├─────────────────────────────────────┤
│  • Formulation Agent (GPT-4)        │
│  • Market Research (GPT-4 + Tavily) │
│  • Copywriting (Claude 3.5)         │
└─────────────────────────────────────┘
        ↓
┌─────────────────────────────────────┐
│   SEQUENTIAL EXECUTION (1 min)      │
├─────────────────────────────────────┤
│  • Compliance Agent (GPT-4)         │
│  • Pricing Agent (GPT-4 + DB)       │
└─────────────────────────────────────┘
        ↓
Final Aggregator
        ↓
POST /api/sync (Callback to Next.js)
        ↓
Update Database
        ↓
User Sees Complete Report
```

**Total Processing Time**: ~3-4 minutes

---

## 🤖 AI Agents Overview

### 1. Formulation Agent
- **Model**: GPT-4 Turbo
- **Purpose**: Ingredient analysis & formulation optimization
- **Input**: Product blueprint, ingredients list
- **Output**: Complete formulation with INCI names, percentages, pH, stability notes
- **Processing Time**: ~60 seconds

### 2. Market Research Agent
- **Model**: GPT-4 + Tavily Search
- **Purpose**: Market analysis & competitor intelligence
- **Input**: Brand info, location, target market
- **Output**: Market size, trends, competitor analysis, SWOT
- **Processing Time**: ~45 seconds

### 3. Copywriting Agent
- **Model**: Claude 3.5 Sonnet
- **Purpose**: Creative content generation
- **Input**: Brand voice, concept, product details
- **Output**: Product names, taglines, descriptions (bilingual ID/EN)
- **Processing Time**: ~30 seconds

### 4. Compliance Agent
- **Model**: GPT-4
- **Purpose**: Regulatory compliance checking
- **Input**: Ingredients, claims, target market
- **Output**: BPOM requirements, Halal certification process, restrictions
- **Processing Time**: ~30 seconds

### 5. Pricing Agent
- **Model**: GPT-4 + Database Queries
- **Purpose**: Cost calculation & pricing strategy
- **Input**: Ingredients, packaging, batch size
- **Output**: Manufacturing cost, retail price recommendations, margins
- **Processing Time**: ~20 seconds

### 6. Final Aggregator
- **Purpose**: Merge all results & callback to app
- **Functions**: QA check, format validation, database update, API callback
- **Processing Time**: ~30 seconds

---

## 💾 Database Integration

### Tables Used
- `submissions` - Track form submissions
- `submission_payloads` - Store complete form data
- `workflow_runs` - Track n8n execution
- `report_sections` - Store generated report sections
- `audit_logs` - Complete audit trail
- `suppliers` - Supplier master data
- `ingredients_master` - Ingredient database
- `supplier_ingredients` - Pricing data
- `formulation_costs` - Cost calculations

### Key Queries
```sql
-- Get submission status
SELECT status FROM submissions WHERE id = $1;

-- Get ingredient pricing
SELECT * FROM v_current_ingredient_prices 
WHERE ingredient_name = ANY($1::text[]);

-- Save report section
INSERT INTO report_sections (submission_id, section_type, section_data, order)
VALUES ($1, $2, $3, $4);
```

---

## 🔐 Security Features

- ✅ Webhook signature verification
- ✅ Environment-based routing (test/production)
- ✅ API key encryption
- ✅ Database connection pooling
- ✅ Rate limiting
- ✅ Error handling & retry logic
- ✅ Audit logging

---

## 📊 Performance Metrics

| Metric | Target | Expected |
|--------|--------|----------|
| Total Processing Time | < 4 min | 3.5 min |
| Success Rate | > 95% | 97% |
| Cost per Submission | < $0.30 | $0.22 |
| Database Query Time | < 100ms | 50ms |
| Concurrent Submissions | 10+ | 15 |

---

## 💰 Cost Estimation

### Per Submission
- GPT-4 Turbo: ~$0.12
- Claude 3.5 Sonnet: ~$0.05
- Tavily Search: ~$0.03
- Database queries: ~$0.02
- **Total**: ~$0.22

### Monthly Infrastructure
- Neon Postgres: $19
- n8n Cloud: $20
- Vercel: $20
- **Total**: $59/month

### Total Monthly Cost Examples
- 50 submissions: $70/month
- 200 submissions: $110/month
- 500 submissions: $190/month

---

## 🆘 Troubleshooting

### Common Issues

#### 1. Webhook tidak menerima data
**Solution**:
- Verify webhook URL di Next.js `.env`
- Check webhook secret match
- Test dengan curl

#### 2. Database connection error
**Solution**:
- Verify `DATABASE_URL` format
- Ensure `?sslmode=require` appended
- Test connection: `psql $DATABASE_URL -c "SELECT 1;"`

#### 3. AI API errors
**Solution**:
- Check API keys valid
- Verify rate limits
- Check account balance

#### 4. Workflow timeout
**Solution**:
- Increase timeout di n8n settings (default 30s → 120s)
- Check AI API response time
- Verify database query performance

Lihat `05-Documentation/troubleshooting.md` untuk detail lengkap.

---

## 📚 Additional Resources

- **Integration Guide**: `INTEGRATION-GUIDE.md`
- **Deployment Checklist**: `DEPLOYMENT-CHECKLIST.md`
- **Architecture**: `05-Documentation/architecture.md`
- **Workflow Logic**: `05-Documentation/workflow-logic.md`
- **AI Prompts**: `05-Documentation/ai-prompts.md`

---

## ✅ Pre-Deployment Checklist

- [ ] Database schema applied
- [ ] Sample data inserted
- [ ] Environment variables configured
- [ ] All workflows imported to n8n
- [ ] Credentials configured (PostgreSQL, OpenAI, Anthropic)
- [ ] Webhook URLs updated
- [ ] Test payload submitted successfully
- [ ] All agents executed without errors
- [ ] Report sections generated correctly
- [ ] Callback to Next.js successful
- [ ] Monitoring setup
- [ ] Backup configured

---

## 🎉 Ready to Deploy!

Ikuti langkah-langkah di `DEPLOYMENT-CHECKLIST.md` untuk deployment ke production.

---

## 📞 Support

Untuk pertanyaan atau bantuan:
- Review dokumentasi di folder `05-Documentation/`
- Check troubleshooting guide
- Test dengan sample payload

---

**Version**: 1.0.0  
**Last Updated**: October 20, 2025  
**Maintained by**: LBF Technoglow Team

**Happy Building! 🚀✨**
