# 🚀 n8n Workflow Structure Guide - LunarAI Beauty

## Complete Workflow Architecture

### Main Orchestrator Flow

```
1. Webhook Trigger (POST /lunarai-production)
   ↓
2. Authentication (X-Webhook-Secret validation)
   ↓
3. Extract & Validate Payload (JavaScript)
   ↓
4. Database - Create Submission
   ↓
5. Database - Store Payload
   ↓
6. Database - Create Workflow Run
   ↓
7. Split to Parallel Groups
   ├─ Group 1: Creative (Sections 1,2,3)
   ├─ Group 2: Data & Analysis (Sections 4,5,6)
   └─ Group 3: Pricing & Compliance (Sections 7,8)
   ↓
8. Merge Parallel Results
   ↓
9. Sequential Sections (9,10)
   ↓
10. Section 11 - Next Steps
   ↓
11. Aggregate All Results
   ↓
12. Database - Update Status
   ↓
13. Database - Store Report
   ↓
14. Callback to Next.js App
   ↓
15. Audit Log
   ↓
16. Webhook Response
```

---

## Individual Section Workflows

### SECTION 1: Product Header (AI Agent)
**Webhook**: `/webhook/section-1-product-header`

**Nodes**:
1. Webhook Trigger
2. Gemini AI Agent
   - Model: gemini-pro
   - Prompt: Generate product name and tagline
   - Memory: PostgreSQL context
3. Store Result
4. Return JSON

**Input**:
```json
{
  "submissionId": "uuid",
  "context": {
    "brand": {"name": "...", "voice": "...", "values": "..."},
    "product": {"type": "...", "functions": [...]}
  }
}
```

**Output**:
```json
{
  "sectionType": "productHeader",
  "content": {
    "name": "Product Name",
    "tagline": "Catchy Tagline",
    "shortDescription": "Brief description"
  }
}
```

---

### SECTION 2: Product Description (AI Agent)
**Webhook**: `/webhook/section-2-product-description`

**Nodes**:
1. Webhook Trigger
2. Gemini AI Agent
   - Model: gemini-pro
   - Prompt: Generate comprehensive product description
   - Memory: PostgreSQL context + Section 1 results
3. SEO Optimizer (Function node)
4. Store Result
5. Return JSON

---

### SECTION 3: Alternative Names (AI Agent)
**Webhook**: `/webhook/section-3-alternative-names`

**Nodes**:
1. Webhook Trigger
2. Gemini AI Agent
   - Model: gemini-pro
   - Prompt: Generate 10-15 alternative product names
   - Memory: PostgreSQL context
3. Trademark Check (HTTP Request - optional)
4. Store Result
5. Return JSON

---

### SECTION 4: Ingredient Breakdown (MCP Tools)
**Webhook**: `/webhook/section-4-ingredient-breakdown`

**Nodes**:
1. Webhook Trigger
2. MCP - Query Ingredient Database
   - Tool: query_ingredient_details
   - Get INCI names, properties, restrictions
3. MCP - Validate Percentages
   - Tool: validate_percentages
   - Ensure total = 100%
4. MCP - Check Compatibility
   - Tool: check_ingredient_compatibility
5. Format Results (Function node)
6. Store Result
7. Return JSON

**MCP Configuration**:
```json
{
  "server": "@modelcontextprotocol/server-postgres",
  "tools": ["query_ingredient_details", "validate_percentages"]
}
```

---

### SECTION 5: Market Analysis (Hybrid)
**Webhook**: `/webhook/section-5-market-analysis`

**Nodes**:
1. Webhook Trigger
2. MCP - Web Search (Tavily)
   - Query: Market trends, competitors
3. MCP - Database Query
   - Historical market data
4. Gemini AI Agent
   - Analyze search results
   - Generate insights and SWOT
5. Store Result
6. Return JSON

---

### SECTION 6: Marketing Copy (AI Agent)
**Webhook**: `/webhook/section-6-marketing-copy`

**Nodes**:
1. Webhook Trigger
2. Gemini AI Agent
   - Model: gemini-pro
   - Prompt: Generate marketing copy
   - Context: Product header + description
3. A/B Testing Suggestions (Function)
4. Store Result
5. Return JSON

---

### SECTION 7: Pricing Structure (MCP Tools)
**Webhook**: `/webhook/section-7-pricing-structure`

**Nodes**:
1. Webhook Trigger
2. MCP - Query Ingredient Prices
   - Tool: query_ingredient_prices
   - Get current supplier pricing
3. MCP - Query Packaging Costs
   - Tool: query_packaging_costs
4. Function - Calculate Manufacturing Cost
   ```javascript
   // Base cost calculation
   const baseCost = ingredients.reduce((sum, ing) => {
     return sum + (ing.percentage/100 * ing.pricePerKg);
   }, 0) + packagingCost;
   
   // Apply waste factor (15%)
   const costWithWaste = baseCost * 1.15;
   
   // Calculate ranges
   const costMin = baseCost * 0.8;  // -20%
   const costMax = baseCost * 1.3;  // +30%
   
   // Retail price (40% margin)
   const retailPrice = costWithWaste / 0.6;
   
   return {
     manufacturingCost: {
       base: baseCost,
       withWaste: costWithWaste,
       range: {min: costMin, max: costMax}
     },
     retailPrice: {
       recommended: retailPrice,
       range: {
         min: retailPrice * 0.8,
         max: retailPrice * 1.3
       }
     },
     margin: 40,
     breakEven: calculateBreakEven(...)
   };
   ```
5. MCP - Store Formulation Cost
6. Store Result
7. Return JSON

---

### SECTION 8: Regulatory Compliance (Hybrid)
**Webhook**: `/webhook/section-8-regulatory-compliance`

**Nodes**:
1. Webhook Trigger
2. MCP - Query Restricted Ingredients
   - Check against regulatory database
3. MCP - Web Search
   - Latest BPOM regulations
4. Gemini AI Agent
   - Interpret regulations
   - Generate compliance checklist
5. Store Result
6. Return JSON

---

### SECTION 9: Production Timeline (Hybrid)
**Webhook**: `/webhook/section-9-production-timeline`

**Nodes**:
1. Webhook Trigger
2. MCP - Query Supplier Lead Times
3. Gemini AI Agent
   - Generate production schedule
   - Critical path analysis
4. Store Result
5. Return JSON

---

### SECTION 10: Sustainability Assessment (Hybrid)
**Webhook**: `/webhook/section-10-sustainability`

**Nodes**:
1. Webhook Trigger
2. MCP - Query Ingredient Sustainability Data
3. Gemini AI Agent
   - Calculate sustainability score
   - Environmental impact assessment
4. Store Result
5. Return JSON

---

### SECTION 11: Next Steps (AI Agent)
**Webhook**: `/webhook/section-11-next-steps`

**Nodes**:
1. Webhook Trigger
2. Gemini AI Agent
   - Input: All previous sections
   - Generate prioritized action items
   - Timeline and resource allocation
3. Store Result
4. Return JSON

---

## Gemini AI Agent Configuration

### Model Selection
- **gemini-pro**: Creative sections (1,2,3,6,11)
- **gemini-pro**: Analytical sections (5,8,9,10)

### Memory Configuration
```json
{
  "type": "postgres",
  "connection": {
    "host": "{{$env.DATABASE_HOST}}",
    "database": "{{$env.DATABASE_NAME}}",
    "user": "{{$env.DATABASE_USER}}",
    "password": "{{$env.DATABASE_PASSWORD}}"
  },
  "table": "agent_memory",
  "contextWindow": 32000
}
```

### Prompt Templates

#### Section 1 - Product Header
```
You are an expert product naming specialist for cosmetic brands.

Brand Context:
- Name: {{brand.name}}
- Voice: {{brand.voice}}
- Values: {{brand.values}}

Product Context:
- Type: {{product.type}}
- Functions: {{product.functions}}
- Target: {{target.gender}}, {{target.ageRanges}}

Task:
Generate a compelling product name and tagline that:
1. Aligns with brand voice and values
2. Highlights key benefits
3. Appeals to target audience
4. Is memorable and unique
5. Works in Indonesian and English

Output as JSON:
{
  "name": "Product Name",
  "tagline": "Catchy tagline",
  "shortDescription": "Brief description (50 words)",
  "rationale": "Why this name works"
}
```

#### Section 4 - Ingredient Breakdown (MCP)
```sql
-- Query ingredient details
SELECT 
  im.name,
  im.inci_name,
  im.category,
  im.function,
  im.typical_usage_min,
  im.typical_usage_max,
  im.ph_range,
  im.restrictions,
  im.allergen_info
FROM ingredients_master im
WHERE im.name = ANY($1::text[]);
```

#### Section 7 - Pricing (MCP)
```sql
-- Query current ingredient prices
SELECT 
  im.name,
  im.inci_name,
  si.price_per_kg,
  si.supplier_id,
  s.name as supplier_name,
  si.moq_kg,
  si.in_stock
FROM ingredients_master im
JOIN supplier_ingredients si ON im.id = si.ingredient_id
JOIN suppliers s ON si.supplier_id = s.id
WHERE im.name = ANY($1::text[])
  AND si.in_stock = true
  AND (si.price_valid_until IS NULL OR si.price_valid_until >= CURRENT_DATE)
ORDER BY si.price_per_kg ASC;
```

---

## Environment Variables Required

```bash
# n8n Configuration
N8N_WEBHOOK_BASE=https://your-n8n.app.n8n.cloud
N8N_WEBHOOK_SECRET=your-secret-key

# Database
DATABASE_URL=postgresql://user:pass@host/db?sslmode=require
DATABASE_HOST=your-host.neon.tech
DATABASE_NAME=lunarai_db
DATABASE_USER=your_user
DATABASE_PASSWORD=your_password

# AI APIs
GOOGLE_AI_API_KEY=your-gemini-api-key
TAVILY_API_KEY=your-tavily-key

# Application
NEXT_PUBLIC_APP_URL=https://your-app.vercel.app
```

---

## Performance Optimization

### Parallel Execution
- **Group 1** (Creative): 60s max
- **Group 2** (Data): 60s max
- **Group 3** (Pricing): 45s max
- **Sequential**: 80s max
- **Total**: ~3 minutes

### Caching Strategy
```javascript
// Cache ingredient data for 1 hour
const cacheKey = `ingredients_${ingredientNames.join('_')}`;
const cached = await redis.get(cacheKey);
if (cached) return JSON.parse(cached);

// Query and cache
const data = await queryIngredients(ingredientNames);
await redis.setex(cacheKey, 3600, JSON.stringify(data));
return data;
```

### Error Handling
```javascript
// Retry logic with exponential backoff
async function retryWithBackoff(fn, maxRetries = 3) {
  for (let i = 0; i < maxRetries; i++) {
    try {
      return await fn();
    } catch (error) {
      if (i === maxRetries - 1) throw error;
      await sleep(Math.pow(2, i) * 1000);
    }
  }
}
```

---

## Testing Strategy

### Unit Tests (Per Section)
```bash
# Test Section 1
curl -X POST http://localhost:5678/webhook-test/section-1-product-header \
  -H "Content-Type: application/json" \
  -d @test-payloads/section-1-input.json
```

### Integration Test (Complete Flow)
```bash
# Test complete workflow
curl -X POST http://localhost:5678/webhook-test/lunarai-production \
  -H "Content-Type: application/json" \
  -H "X-Webhook-Secret: $N8N_WEBHOOK_SECRET" \
  -d @test-payloads/complete-submission.json
```

---

## Next Steps

1. ✅ Tool selection analysis complete
2. ✅ Workflow structure documented
3. ⏳ Create individual workflow JSON files
4. ⏳ Configure Gemini AI credentials
5. ⏳ Set up MCP servers
6. ⏳ Test each section
7. ⏳ Deploy to production

---

**This structure provides the foundation for building powerful, scalable n8n workflows! 🚀**
