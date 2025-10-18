# N8N Workflows - LBF Technoglow Simulator

## Overview
Kumpulan workflow n8n untuk sistem AI Agentic multi-agent yang memproses submission produk kecantikan.

## Workflow Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Main Processor                            │
│  (Webhook Receiver → Orchestrator → Agent Router)           │
└─────────────────────────────────────────────────────────────┘
                            │
        ┌───────────────────┼───────────────────┐
        │                   │                   │
        ▼                   ▼                   ▼
┌──────────────┐    ┌──────────────┐    ┌──────────────┐
│ Formulation  │    │   Market     │    │ Copywriting  │
│    Agent     │    │   Research   │    │    Agent     │
│              │    │    Agent     │    │              │
└──────────────┘    └──────────────┘    └──────────────┘
        │                   │                   │
        └───────────────────┼───────────────────┘
                            │
                            ▼
                ┌──────────────────────┐
                │  Compliance Agent    │
                └──────────────────────┘
                            │
                            ▼
                ┌──────────────────────┐
                │ Final Aggregation    │
                │   & Callback         │
                └──────────────────────┘
```

## Workflow Files

### 1. main-processor.json
**Purpose**: Workflow utama yang menerima webhook dan mengorkestrasikan semua agent

**Key Features**:
- Webhook receiver dengan signature validation
- Environment checker (test/production)
- Database status update
- Agent task distribution

**Trigger**: HTTP POST webhook dari aplikasi Next.js

---

### 2. formulation-agent.json
**Purpose**: Analisis formula dan ingredient menggunakan GPT-4

**Key Features**:
- AI-powered formulation analysis
- INCI name generation
- Stability assessment
- Scientific reference search via MCP

**Output**: Section `ingredients` dan `scientificReferences`

---

### 3. market-research-agent.json
**Purpose**: Riset pasar dan analisis kompetitor

**Key Features**:
- Market size analysis
- Consumer insights
- Competitor research via web search
- Pricing landscape analysis

**Output**: Section `marketAnalysis` dan `competitors`

---

### 4. copywriting-agent.json
**Purpose**: Generate konten marketing menggunakan Claude AI

**Key Features**:
- Product naming (multiple options)
- Tagline generation
- Marketing copy (short & long)
- Social media captions
- SEO content

**Output**: Section `copywriting` dan `alternativeNames`

---

### 5. compliance-agent.json
**Purpose**: Analisis regulasi dan compliance

**Key Features**:
- BPOM requirements
- Halal certification process
- Ingredient restrictions
- Labeling requirements
- Latest regulatory updates via web search

**Output**: Section `regulatory` dan `regulatoryUpdates`

---

### 6. final-aggregation.json
**Purpose**: Mengumpulkan semua hasil dan callback ke aplikasi

**Key Features**:
- Aggregate all report sections
- Update submission status
- Callback to Next.js API
- Audit logging

**Output**: Complete report sent to `/api/sync`

---

### 7. error-handler.json
**Purpose**: Global error handling dan retry logic

**Key Features**:
- Error logging to database
- Retry logic dengan exponential backoff
- Error notification to application
- Audit trail

---

## Import Instructions

### Method 1: Via n8n UI
1. Login ke n8n dashboard
2. Click **Workflows** → **Import from File**
3. Select workflow JSON file
4. Click **Import**
5. Configure credentials (PostgreSQL, OpenAI, etc.)
6. Activate workflow

### Method 2: Via n8n CLI
```bash
# Import all workflows
for file in *.json; do
  n8n import:workflow --input="$file"
done
```

### Method 3: Via API
```bash
# Import workflow via API
curl -X POST http://localhost:5678/rest/workflows \
  -H "Content-Type: application/json" \
  -H "X-N8N-API-KEY: your-api-key" \
  -d @main-processor.json
```

## Configuration Required

### 1. PostgreSQL Credentials
- Host: Your Neon Postgres host
- Database: lbf_techno
- User: Your database user
- Password: Your database password
- SSL: Enabled

### 2. OpenAI Credentials
- API Key: Your OpenAI API key
- Organization: (optional)

### 3. Anthropic Credentials
- API Key: Your Anthropic API key

### 4. Tavily Credentials (Web Search)
- API Key: Your Tavily API key

### 5. Environment Variables
Set these in n8n settings:
```
N8N_WEBHOOK_SECRET=your-secret-key
NEXT_PUBLIC_APP_URL=https://your-app.com
OPENAI_API_KEY=sk-...
ANTHROPIC_API_KEY=sk-ant-...
TAVILY_API_KEY=tvly-...
```

## Testing Workflows

### Test Individual Workflow
```bash
# Test formulation agent
curl -X POST http://localhost:5678/webhook-test/formulation-agent \
  -H "Content-Type: application/json" \
  -d '{
    "submissionId": "test-uuid",
    "inputData": {...}
  }'
```

### Test Complete Flow
```bash
# Send test submission
curl -X POST http://localhost:5678/webhook-test/lbf-simulator \
  -H "Content-Type: application/json" \
  -H "X-Webhook-Secret: your-secret" \
  -d @../05-Testing/test-payload.json
```

## Monitoring

### Check Workflow Execution
1. Go to **Executions** in n8n dashboard
2. Filter by workflow name
3. View execution details and logs

### Check Database
```sql
-- Check workflow status
SELECT * FROM workflow_runs 
WHERE submission_id = 'your-uuid' 
ORDER BY created_at DESC;

-- Check report sections
SELECT section_type, created_at 
FROM report_sections 
WHERE submission_id = 'your-uuid' 
ORDER BY "order";
```

## Troubleshooting

### Workflow Not Triggering
- Check webhook URL is correct
- Verify webhook secret matches
- Check n8n logs: `docker logs n8n`

### Agent Failing
- Check API credentials
- Verify API rate limits
- Check error logs in database

### Database Connection Issues
- Verify DATABASE_URL is correct
- Check SSL mode is enabled
- Test connection: `psql $DATABASE_URL`

## Performance Tips

1. **Parallel Execution**: Agents run in parallel for faster processing
2. **Caching**: Implement caching for repeated market research
3. **Rate Limiting**: Use Bottleneck for API rate limiting
4. **Batch Processing**: Process multiple submissions in batches

## Next Steps

1. Import all workflows
2. Configure credentials
3. Test each workflow individually
4. Test complete flow end-to-end
5. Monitor execution logs
6. Optimize based on performance metrics
