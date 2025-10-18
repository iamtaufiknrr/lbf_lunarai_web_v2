# 🚀 n8n Workflow Implementation Guide - LunarAI Beauty

## 📋 Table of Contents
1. [Prerequisites](#prerequisites)
2. [Setup Steps](#setup-steps)
3. [Workflow Configuration](#workflow-configuration)
4. [Agent Implementation](#agent-implementation)
5. [Testing & Validation](#testing--validation)
6. [Monitoring & Optimization](#monitoring--optimization)
7. [Troubleshooting](#troubleshooting)

---

## 🎯 Prerequisites

### Required Services
- ✅ **n8n Instance** (Cloud or Self-hosted)
- ✅ **Neon Postgres Database** (with schemas applied)
- ✅ **OpenAI API Key** (GPT-4 Turbo access)
- ✅ **Anthropic API Key** (Claude 3.5 Sonnet)
- ✅ **Tavily API Key** (Web search)
- ✅ **Next.js Application** (deployed and running)

### Database Setup
```bash
# 1. Apply main schema
psql "$DATABASE_URL" -f 01-Database/schema.sql

# 2. Apply supplier & pricing schema
psql "$DATABASE_URL" -f 01-Database/supplier-pricing-schema.sql

# 3. Verify tables
psql "$DATABASE_URL" -c "\dt"
```

### Environment Variables
Create `.env` file:
```bash
# Database
DATABASE_URL=postgresql://user:pass@host/db?sslmode=require

# n8n
N8N_WEBHOOK_SECRET=your-secret-key-here
N8N_PRODUCTION_WEBHOOK=https://your-n8n.app.n8n.cloud/webhook/lunarai-production
N8N_TEST_WEBHOOK=https://your-n8n.app.n8n.cloud/webhook-test/lunarai-test

# AI APIs
OPENAI_API_KEY=sk-...
ANTHROPIC_API_KEY=sk-ant-...
TAVILY_API_KEY=tvly-...

# Application
NEXT_PUBLIC_APP_URL=https://your-app.vercel.app
```

---

## 🔧 Setup Steps

### Step 1: Import Workflows to n8n

#### Option A: Via n8n UI
1. Login to n8n dashboard
2. Click **Workflows** → **Import from File**
3. Import in this order:
   - `main-processor.json`
   - `formulation-agent.json`
   - `market-research-agent.json`
   - `copywriting-agent.json`
   - `compliance-agent.json`
   - `pricing-agent.json` ⭐ NEW
   - `final-aggregation.json`
   - `error-handler.json`

#### Option B: Via n8n CLI
```bash
cd "02-N8N-Workflows"
for file in *.json; do
  n8n import:workflow --input="$file"
done
```

### Step 2: Configure Credentials

#### PostgreSQL Credential
```
Name: LunarAI-Database
Type: Postgres
Host: [from DATABASE_URL]
Database: [from DATABASE_URL]
User: [from DATABASE_URL]
Password: [from DATABASE_URL]
SSL: Enabled
```

#### OpenAI Credential
```
Name: OpenAI-GPT4
Type: OpenAI
API Key: [your OpenAI key]
Organization: [optional]
```

#### Anthropic Credential
```
Name: Anthropic-Claude
Type: Anthropic
API Key: [your Anthropic key]
```

#### Tavily Credential
```
Name: Tavily-Search
Type: HTTP Request (Custom)
Base URL: https://api.tavily.com
Headers:
  - Authorization: Bearer [your Tavily key]
```

### Step 3: Configure Webhooks

#### Main Processor Webhook
1. Open `main-processor` workflow
2. Click on **Webhook** node
3. Set path: `/webhook/lunarai-production`
4. Method: `POST`
5. Authentication: `Header Auth`
6. Header Name: `X-Webhook-Secret`
7. Header Value: `{{$env.N8N_WEBHOOK_SECRET}}`
8. Copy webhook URL

#### Test Webhook
1. Create test version with path: `/webhook-test/lunarai-test`
2. Same configuration as production
3. Copy test webhook URL

### Step 4: Update Application URLs

Update `.env.local` in Next.js app:
```bash
N8N_PRODUCTION_WEBHOOK=[production webhook URL]
N8N_TEST_WEBHOOK=[test webhook URL]
N8N_WEBHOOK_SECRET=[your secret]
```

---

## 🤖 Agent Implementation

### 1. Formulation Agent

**Purpose**: Analyze ingredients and generate formulation recommendations

**n8n Nodes**:
```
Webhook Trigger
  ↓
Extract Payload
  ↓
Query Ingredient Database (PostgreSQL)
  ↓
GPT-4 Analysis
  ↓
Generate INCI Names
  ↓
Calculate pH & Stability
  ↓
Store Results (PostgreSQL)
  ↓
Return JSON
```

**GPT-4 Prompt Template**:
```
You are an expert cosmetic formulation scientist. Analyze the following product brief and provide detailed formulation recommendations.

Product Type: {{$json.formType}}
Functions: {{$json.functions}}
Target Price: {{$json.targetRetailPrice}}
Ingredients Provided: {{$json.ingredients}}

Tasks:
1. Validate ingredient compatibility
2. Generate complete INCI names
3. Optimize percentages for efficacy
4. Calculate pH range
5. Assess stability (Excellent/Good/Fair/Poor)
6. Suggest additional ingredients if needed
7. Provide scientific references

Output as JSON with this structure:
{
  "ingredients": {
    "list": [
      {
        "name": "...",
        "inciName": "...",
        "percentage": 5.0,
        "purpose": "...",
        "notes": "..."
      }
    ],
    "totalPercentage": 100,
    "phRange": "5.5-6.5",
    "stability": "Excellent",
    "shelfLife": "24 months"
  },
  "scientificReferences": [...]
}
```

**Database Query** (Get ingredient prices):
```sql
SELECT 
  im.name,
  im.inci_name,
  im.category,
  si.price_per_kg,
  si.supplier_id,
  s.name as supplier_name
FROM ingredients_master im
JOIN supplier_ingredients si ON im.id = si.ingredient_id
JOIN suppliers s ON si.supplier_id = s.id
WHERE im.name = ANY($1::text[])
  AND si.in_stock = true
ORDER BY si.price_per_kg ASC;
```

---

### 2. Market Research Agent

**Purpose**: Analyze market trends and competitors

**n8n Nodes**:
```
Webhook Trigger
  ↓
Extract Market Data
  ↓
Tavily Web Search (Competitors)
  ↓
Tavily Web Search (Market Trends)
  ↓
GPT-4 Analysis
  ↓
Store Results (PostgreSQL)
  ↓
Return JSON
```

**Tavily Search Queries**:
```javascript
// Query 1: Competitors
{
  "query": `${productType} ${functions.join(' ')} Indonesia market competitors`,
  "search_depth": "advanced",
  "max_results": 10
}

// Query 2: Market Trends
{
  "query": `${productType} skincare market trends Indonesia 2024`,
  "search_depth": "advanced",
  "max_results": 5
}

// Query 3: Pricing
{
  "query": `${productType} ${priceRange} Indonesia retail price`,
  "search_depth": "basic",
  "max_results": 5
}
```

**GPT-4 Analysis Prompt**:
```
Analyze the following market data and provide comprehensive insights.

Product: {{$json.formType}}
Target Market: {{$json.location.country}}
Price Range: {{$json.targetRetailPrice}}

Web Search Results:
{{$json.searchResults}}

Provide:
1. Market size and growth rate
2. Key trends and opportunities
3. Top 5-10 competitor products with analysis
4. Pricing landscape
5. Distribution channels
6. Consumer insights
7. SWOT analysis

Output as structured JSON.
```

---

### 3. Copywriting Agent

**Purpose**: Generate creative marketing content

**n8n Nodes**:
```
Webhook Trigger
  ↓
Extract Brand Data
  ↓
Claude 3.5 Sonnet
  ↓
Generate Multiple Variations
  ↓
Store Results (PostgreSQL)
  ↓
Return JSON
```

**Claude Prompt**:
```
You are a creative copywriter specializing in beauty and skincare products.

Brand: {{$json.brandName}}
Brand Voice: {{$json.brandVoice}}
Brand Values: {{$json.brandValues}}
Product Type: {{$json.formType}}
Key Benefits: {{$json.functions}}

Generate:
1. 10 alternative product names (creative, memorable, SEO-friendly)
2. 5 taglines (short, punchy, emotional)
3. Short copy (50 words) - for packaging
4. Long copy (200 words) - for website
5. 5 social media captions (Instagram-ready)
6. SEO meta description (160 chars)
7. Email subject lines (5 variations)

Requirements:
- Bilingual (Bahasa Indonesia & English)
- Align with brand voice
- Emphasize key benefits
- Include emotional triggers
- SEO-optimized

Output as JSON.
```

---

### 4. Compliance Agent

**Purpose**: Ensure regulatory compliance

**n8n Nodes**:
```
Webhook Trigger
  ↓
Extract Ingredients & Claims
  ↓
Query Restricted Ingredients DB
  ↓
Tavily Search (Latest Regulations)
  ↓
GPT-4 Compliance Analysis
  ↓
Store Results (PostgreSQL)
  ↓
Return JSON
```

**Database Query** (Check restrictions):
```sql
SELECT 
  im.name,
  im.inci_name,
  im.restrictions,
  im.allergen_info,
  im.halal,
  im.vegan
FROM ingredients_master im
WHERE im.id = ANY($1::uuid[])
  AND (
    im.restrictions IS NOT NULL 
    OR im.allergen_info IS NOT NULL
  );
```

**GPT-4 Compliance Prompt**:
```
Analyze regulatory compliance for this cosmetic product.

Product: {{$json.formType}}
Ingredients: {{$json.ingredients}}
Claims: {{$json.claimEmphasis}}
Target Markets: Indonesia, ASEAN
Certifications Needed: {{$json.regulatoryPriority}}

Provide:
1. BPOM registration requirements
2. Halal certification process (if needed)
3. Ingredient restrictions or warnings
4. Labeling requirements
5. Claims substantiation needed
6. Estimated timeline
7. Estimated costs
8. Risk assessment

Output as structured JSON.
```

---

### 5. Pricing & Costing Agent ⭐ NEW

**Purpose**: Calculate manufacturing costs and pricing strategy

**n8n Nodes**:
```
Webhook Trigger
  ↓
Extract Formulation Data
  ↓
Query Ingredient Prices (PostgreSQL)
  ↓
Query Packaging Costs (PostgreSQL)
  ↓
Calculate Base Cost (Function Node)
  ↓
Apply Waste Factor (15%)
  ↓
Calculate Price Ranges
  ↓
GPT-4 Pricing Strategy
  ↓
Store Results (PostgreSQL)
  ↓
Return JSON
```

**Cost Calculation Logic** (Function Node):
```javascript
// Get ingredient costs
const ingredients = $input.all()[0].json.ingredients;
const ingredientPrices = $input.all()[1].json; // from DB query

let totalIngredientCost = 0;
const breakdown = [];

for (const ing of ingredients) {
  const priceData = ingredientPrices.find(p => p.name === ing.name);
  if (!priceData) continue;
  
  // Convert percentage to kg (assuming 1kg batch)
  const quantityKg = (ing.percentage / 100);
  const cost = quantityKg * priceData.price_per_kg;
  
  totalIngredientCost += cost;
  breakdown.push({
    name: ing.name,
    percentage: ing.percentage,
    quantityKg: quantityKg,
    pricePerKg: priceData.price_per_kg,
    totalCost: cost,
    supplier: priceData.supplier_name
  });
}

// Get packaging cost
const packagingType = $json.packagingType;
const packagingCost = $input.all()[2].json.price_per_unit || 15000;

// Calculate manufacturing cost
const wasteFactor = 0.15; // 15%
const baseCost = totalIngredientCost + packagingCost;
const costWithWaste = baseCost * (1 + wasteFactor);

// Calculate price ranges
const costRangeMin = baseCost * 0.8; // -20%
const costRangeMax = baseCost * 1.3; // +30%

// Calculate retail price (40% margin)
const targetMargin = 0.40;
const recommendedRetailPrice = costWithWaste / (1 - targetMargin);
const retailPriceMin = recommendedRetailPrice * 0.8;
const retailPriceMax = recommendedRetailPrice * 1.3;

// Break-even calculation
const batchSize = $json.pilotBatchSize || 1000;
const fixedCosts = 5000000; // Rp 5 juta (setup, labor, overhead)
const variableCostPerUnit = costWithWaste / batchSize;
const pricePerUnit = recommendedRetailPrice;
const breakEvenUnits = Math.ceil(fixedCosts / (pricePerUnit - variableCostPerUnit));

return {
  json: {
    totalIngredientCost,
    ingredientCostBreakdown: breakdown,
    packagingCost,
    wasteFactor: wasteFactor * 100,
    wasteCost: baseCost * wasteFactor,
    manufacturingCostBase: baseCost,
    manufacturingCostWithWaste: costWithWaste,
    costRangeMin,
    costRangeMax,
    targetMarginPercentage: targetMargin * 100,
    recommendedRetailPrice,
    retailPriceRangeMin: retailPriceMin,
    retailPriceRangeMax: retailPriceMax,
    batchSize,
    costPerUnit: costWithWaste / batchSize,
    breakEvenUnits,
    calculationDate: new Date().toISOString()
  }
};
```

**Database Insert** (Store costs):
```sql
INSERT INTO formulation_costs (
  submission_id,
  total_ingredient_cost,
  ingredient_cost_breakdown,
  waste_percentage,
  waste_cost,
  manufacturing_cost_base,
  manufacturing_cost_with_waste,
  cost_range_min,
  cost_range_max,
  packaging_cost,
  recommended_retail_price,
  retail_price_range_min,
  retail_price_range_max,
  target_margin_percentage,
  break_even_units,
  batch_size,
  cost_per_unit,
  calculated_by
) VALUES (
  $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, 'AI Agent'
);
```

---

### 6. Final Aggregation

**Purpose**: Merge all agent results and send to application

**n8n Nodes**:
```
Wait for All Agents
  ↓
Merge Results (Function Node)
  ↓
QA Check (Validate completeness)
  ↓
Update Submission Status (PostgreSQL)
  ↓
Store Complete Report (PostgreSQL)
  ↓
Callback to Next.js API
  ↓
Audit Log
```

**Merge Function**:
```javascript
const formulation = $input.all()[0].json;
const market = $input.all()[1].json;
const copywriting = $input.all()[2].json;
const compliance = $input.all()[3].json;
const pricing = $input.all()[4].json;

const completeReport = {
  submissionId: $json.submissionId,
  status: 'completed',
  generatedAt: new Date().toISOString(),
  sections: {
    productHeader: {
      name: copywriting.alternativeNames[0],
      tagline: copywriting.copywriting.tagline,
      description: copywriting.copywriting.shortCopy
    },
    productDescription: {
      description: copywriting.copywriting.longCopy
    },
    alternativeNames: {
      names: copywriting.alternativeNames
    },
    ingredients: formulation.ingredients,
    scientificReferences: formulation.scientificReferences,
    marketAnalysis: market.marketAnalysis,
    competitors: market.competitors,
    copywriting: copywriting.copywriting,
    pricing: {
      manufacturingCost: {
        base: pricing.manufacturingCostBase,
        withWaste: pricing.manufacturingCostWithWaste,
        range: {
          min: pricing.costRangeMin,
          max: pricing.costRangeMax
        }
      },
      retailPrice: {
        recommended: pricing.recommendedRetailPrice,
        range: {
          min: pricing.retailPriceRangeMin,
          max: pricing.retailPriceRangeMax
        }
      },
      margin: pricing.targetMarginPercentage,
      breakEven: pricing.breakEvenUnits
    },
    regulatory: compliance.regulatory,
    nextSteps: {
      steps: [
        'Review and approve formulation',
        'Submit BPOM registration',
        'Order pilot batch materials',
        'Conduct stability testing',
        'Finalize packaging design',
        'Launch marketing campaign'
      ]
    }
  }
};

return { json: completeReport };
```

**Callback to Next.js**:
```javascript
// POST to /api/sync
{
  method: 'POST',
  url: `${process.env.NEXT_PUBLIC_APP_URL}/api/sync`,
  headers: {
    'Content-Type': 'application/json',
    'X-API-Key': process.env.API_SECRET
  },
  body: completeReport
}
```

---

## ✅ Testing & Validation

### Test Individual Agents

```bash
# Test Formulation Agent
curl -X POST http://localhost:5678/webhook-test/formulation \
  -H "Content-Type: application/json" \
  -d '{
    "submissionId": "test-123",
    "formType": "Serum",
    "functions": ["Brightening", "Anti-Aging"],
    "ingredients": [...]
  }'

# Test Pricing Agent
curl -X POST http://localhost:5678/webhook-test/pricing \
  -H "Content-Type: application/json" \
  -d '{
    "submissionId": "test-123",
    "ingredients": [...],
    "packagingType": "dropper",
    "batchSize": 1000
  }'
```

### Test Complete Flow

```bash
# Use test payload
curl -X POST $N8N_TEST_WEBHOOK \
  -H "Content-Type: application/json" \
  -H "X-Webhook-Secret: $N8N_WEBHOOK_SECRET" \
  -d @../05-Testing/test-payload.json
```

### Validation Checklist

- [ ] All agents execute successfully
- [ ] Database records created
- [ ] Pricing calculations accurate
- [ ] Cost ranges within expected bounds
- [ ] Report sections complete
- [ ] Callback received by Next.js
- [ ] No errors in logs

---

## 📊 Monitoring & Optimization

### Key Metrics to Track

1. **Execution Time**
   - Target: < 4 minutes total
   - Per agent: < 60 seconds

2. **Success Rate**
   - Target: > 95%
   - Track failures by agent

3. **Cost per Submission**
   - Target: < $0.30
   - Track API usage

4. **Database Performance**
   - Query time: < 100ms
   - Connection pool usage

### Monitoring Queries

```sql
-- Check workflow performance
SELECT 
  DATE_TRUNC('hour', created_at) as hour,
  COUNT(*) as submissions,
  AVG(EXTRACT(EPOCH FROM (updated_at - created_at))) as avg_duration_seconds,
  COUNT(CASE WHEN status = 'completed' THEN 1 END) as successful,
  COUNT(CASE WHEN status = 'error' THEN 1 END) as failed
FROM submissions
WHERE created_at > NOW() - INTERVAL '24 hours'
GROUP BY hour
ORDER BY hour DESC;

-- Check pricing accuracy
SELECT 
  AVG(manufacturing_cost_with_waste) as avg_mfg_cost,
  AVG(recommended_retail_price) as avg_retail_price,
  AVG(target_margin_percentage) as avg_margin,
  COUNT(*) as total_calculations
FROM formulation_costs
WHERE calculation_date > NOW() - INTERVAL '7 days';
```

---

## 🔧 Troubleshooting

### Common Issues

#### 1. Webhook Not Triggering
**Symptoms**: No workflow execution after form submission

**Solutions**:
- Verify webhook URL is correct
- Check webhook secret matches
- Test with curl command
- Check n8n logs: `docker logs n8n`

#### 2. Database Connection Failed
**Symptoms**: PostgreSQL errors in logs

**Solutions**:
- Verify DATABASE_URL format
- Check SSL mode is enabled
- Test connection: `psql $DATABASE_URL -c "SELECT 1;"`
- Check connection pool limits

#### 3. Pricing Calculation Errors
**Symptoms**: NaN or incorrect costs

**Solutions**:
- Verify ingredient prices exist in DB
- Check packaging costs table
- Validate input percentages sum to 100
- Review waste factor calculation

#### 4. AI API Rate Limits
**Symptoms**: 429 errors from OpenAI/Anthropic

**Solutions**:
- Implement exponential backoff
- Add rate limiting in n8n
- Use different API keys for test/prod
- Monitor API usage dashboard

#### 5. Missing Report Sections
**Symptoms**: Incomplete report data

**Solutions**:
- Check all agents completed successfully
- Verify merge logic in aggregation
- Check database foreign key constraints
- Review agent output schemas

---

## 🎉 Next Steps

1. ✅ Complete database setup
2. ✅ Import all workflows
3. ✅ Configure credentials
4. ✅ Test each agent individually
5. ✅ Test complete flow end-to-end
6. ✅ Monitor execution logs
7. ✅ Optimize based on metrics
8. ✅ Deploy to production

---

**Need Help?**
- Check logs in n8n dashboard
- Review database audit logs
- Test with sample payload
- Contact support team

**Happy Building! 🚀✨**
