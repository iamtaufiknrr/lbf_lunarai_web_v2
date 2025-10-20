# 🎯 Workflow Creation Plan - Complete n8n Implementation

## 📋 Overview

Berdasarkan analisis folder `automation/n8n/integration/02-N8N-Workflows`, saya akan membuat **11 workflow JSON lengkap** yang terintegrasi dengan main orchestrator menggunakan **AI Agent Tools** dan **MCP Tools**.

---

## 🏗️ Architecture Summary

```
Main Orchestrator (00-main-orchestrator.json)
        │
        ├─→ AI Agent Tools (Gemini Pro)
        │   ├─ Section 1: Product Header
        │   ├─ Section 2: Product Description
        │   ├─ Section 3: Alternative Names
        │   ├─ Section 6: Marketing Copy
        │   └─ Section 11: Next Steps
        │
        ├─→ MCP Tools (Database + Calculations)
        │   ├─ Section 4: Ingredient Breakdown
        │   └─ Section 7: Pricing Structure
        │
        └─→ Hybrid (Gemini + MCP)
            ├─ Section 5: Market Analysis
            ├─ Section 8: Regulatory Compliance
            ├─ Section 9: Production Timeline
            └─ Section 10: Sustainability
```

---

## 📊 Tool Selection Matrix (From Analysis)

| Section | Type | Primary Tool | Duration | Status |
|---------|------|--------------|----------|--------|
| 1. Product Header | 🤖 AI Agent | Gemini Pro | 20s | ✅ EXISTS |
| 2. Product Description | 🤖 AI Agent | Gemini Pro | 30s | ⏳ TO CREATE |
| 3. Alternative Names | 🤖 AI Agent | Gemini Pro | 25s | ⏳ TO CREATE |
| 4. Ingredient Breakdown | 🔧 MCP Tools | Database MCP | 30s | ⏳ TO CREATE |
| 5. Market Analysis | 🤖🔧 Hybrid | Gemini + Web MCP | 45s | ⏳ TO CREATE |
| 6. Marketing Copy | 🤖 AI Agent | Gemini Pro | 35s | ⏳ TO CREATE |
| 7. Pricing Structure | 🔧 MCP Tools | Database + Calc MCP | 25s | ✅ EXISTS |
| 8. Regulatory Compliance | 🤖🔧 Hybrid | Gemini + DB MCP | 35s | ⏳ TO CREATE |
| 9. Production Timeline | 🤖🔧 Hybrid | Gemini + DB MCP | 30s | ⏳ TO CREATE |
| 10. Sustainability | 🤖🔧 Hybrid | Gemini + DB MCP | 30s | ⏳ TO CREATE |
| 11. Next Steps | 🤖 AI Agent | Gemini Pro | 25s | ⏳ TO CREATE |

**Total**: 11 workflows  
**Completed**: 2 (Product Header, Pricing Structure)  
**To Create**: 9 workflows

---

## 🎯 Workflow Creation Strategy

### Phase 1: AI Agent Workflows (Pure Gemini)
**Sections**: 2, 3, 6, 11  
**Characteristics**:
- No external data needed
- Creative/generative tasks
- Context from memory only
- Fast execution (20-35s)

**Common Structure**:
```
Webhook Trigger
  ↓
Extract Context
  ↓
Retrieve Memory (PostgreSQL)
  ↓
Build Prompt
  ↓
AI Agent (Gemini Pro)
  ├─ Chat Model (Gemini)
  └─ Memory (PostgreSQL)
  ↓
Format Output (JSON)
  ↓
Store Result (PostgreSQL)
  ↓
Webhook Response
```

---

### Phase 2: MCP Tool Workflows (Database Queries)
**Sections**: 4  
**Characteristics**:
- Structured data retrieval
- Database queries
- Calculations
- Deterministic output

**Common Structure**:
```
Webhook Trigger
  ↓
Extract Ingredients
  ↓
Query Ingredient Database (MCP)
  ↓
Query INCI Names (MCP)
  ↓
Calculate Percentages (Function)
  ↓
Format Output (JSON)
  ↓
Store Result (PostgreSQL)
  ↓
Webhook Response
```

---

### Phase 3: Hybrid Workflows (Gemini + MCP)
**Sections**: 5, 8, 9, 10  
**Characteristics**:
- Combine AI analysis with real data
- Web search + database queries
- Complex reasoning
- Longer execution (30-45s)

**Common Structure**:
```
Webhook Trigger
  ↓
Extract Context
  ↓
Parallel Execution:
  ├─ Query Database (MCP)
  └─ Web Search (MCP - Tavily)
  ↓
Merge Data
  ↓
AI Agent Analysis (Gemini Pro)
  ├─ Chat Model (Gemini)
  └─ Memory (PostgreSQL)
  ↓
Format Output (JSON)
  ↓
Store Result (PostgreSQL)
  ↓
Webhook Response
```

---

## 📝 Detailed Workflow Specifications

### Section 2: Product Description (AI Agent)

**Purpose**: Generate long-form product description

**Input**:
```json
{
  "submissionId": "uuid",
  "context": {
    "brand": {...},
    "product": {...},
    "ingredients": [...],
    "benefits": [...]
  }
}
```

**Gemini Prompt**:
```
You are an expert beauty copywriter specializing in long-form product descriptions.

Create a comprehensive product description (200-300 words) that:
1. Opens with an emotional hook
2. Explains key benefits and ingredients
3. Describes texture and sensory experience
4. Includes usage instructions
5. Ends with a compelling call-to-action
6. Uses brand voice: {{brandVoice}}
7. Bilingual (Indonesian primary, English secondary)

Output as JSON with structure:
{
  "description": {
    "id": "Indonesian version",
    "en": "English version"
  },
  "keyPoints": ["point 1", "point 2", ...],
  "usageInstructions": "How to use",
  "callToAction": "CTA text"
}
```

**Output**:
```json
{
  "sectionType": "productDescription",
  "content": {
    "description": {...},
    "keyPoints": [...],
    "usageInstructions": "...",
    "callToAction": "..."
  }
}
```

---

### Section 3: Alternative Names (AI Agent)

**Purpose**: Generate 10 creative product name variations

**Gemini Prompt**:
```
You are a creative naming expert for beauty brands.

Generate 10 alternative product names that:
1. Align with brand: {{brandName}}
2. Reflect functions: {{functions}}
3. Are memorable and unique
4. Work in Indonesian market
5. Are SEO-friendly
6. Avoid trademark conflicts
7. Include rationale for each

Output as JSON:
{
  "alternativeNames": [
    {
      "name": "Name 1",
      "rationale": "Why this works",
      "seoScore": 8,
      "marketAppeal": 9
    },
    ...
  ],
  "recommended": "Top choice name"
}
```

---

### Section 4: Ingredient Breakdown (MCP Tools)

**Purpose**: Query ingredient database and generate structured breakdown

**MCP Queries**:
```sql
-- Query 1: Get ingredient details
SELECT 
  im.name,
  im.inci_name,
  im.category,
  im.function,
  im.restrictions,
  im.allergen_info,
  im.halal,
  im.vegan
FROM ingredients_master im
WHERE im.name = ANY($1::text[]);

-- Query 2: Get supplier pricing
SELECT 
  si.ingredient_id,
  si.price_per_kg,
  si.supplier_id,
  s.name as supplier_name,
  si.in_stock
FROM supplier_ingredients si
JOIN suppliers s ON si.supplier_id = s.id
WHERE si.ingredient_id = ANY($1::uuid[])
ORDER BY si.price_per_kg ASC;
```

**Calculation Logic**:
```javascript
// Calculate percentages and validate
const ingredients = $json.ingredients;
let totalPercentage = 0;

const breakdown = ingredients.map(ing => {
  totalPercentage += ing.percentage;
  return {
    name: ing.name,
    inciName: ing.inciName || dbData.inci_name,
    percentage: ing.percentage,
    purpose: ing.purpose,
    category: dbData.category,
    restrictions: dbData.restrictions,
    allergenInfo: dbData.allergen_info,
    halal: dbData.halal,
    vegan: dbData.vegan
  };
});

// Validate total = 100%
if (Math.abs(totalPercentage - 100) > 0.1) {
  throw new Error(`Total percentage is ${totalPercentage}%, must be 100%`);
}

return { json: { breakdown, totalPercentage } };
```

---

### Section 5: Market Analysis (Hybrid)

**Purpose**: Analyze market with real-time data + AI insights

**MCP Web Search** (Tavily):
```javascript
// Search 1: Market size
{
  "query": `${productType} skincare market size Indonesia 2024`,
  "search_depth": "advanced",
  "max_results": 5
}

// Search 2: Competitors
{
  "query": `${productType} ${functions} Indonesia brands competitors`,
  "search_depth": "advanced",
  "max_results": 10
}

// Search 3: Trends
{
  "query": `skincare trends Indonesia 2024 ${functions}`,
  "search_depth": "basic",
  "max_results": 5
}
```

**Gemini Analysis**:
```
Analyze the following market data and provide insights:

Web Search Results:
{{searchResults}}

Product Context:
- Type: {{productType}}
- Functions: {{functions}}
- Target Price: {{targetPrice}}
- Target Market: {{location}}

Provide:
1. Market size and growth rate
2. Key trends (3-5)
3. Opportunities and threats
4. Competitor analysis (top 5)
5. Positioning recommendations
6. SWOT analysis

Output as structured JSON.
```

---

### Section 6: Marketing Copy (AI Agent)

**Purpose**: Generate multiple marketing copy variations

**Gemini Prompt**:
```
You are an award-winning copywriter for beauty brands.

Generate comprehensive marketing copy:

1. Taglines (5 variations)
   - Short, punchy, emotional
   - Bilingual (ID/EN)

2. Social Media Captions (5 variations)
   - Instagram-ready
   - Include hashtags
   - Call-to-action

3. Email Subject Lines (5 variations)
   - Attention-grabbing
   - Urgency/curiosity

4. SEO Meta Description (160 chars)
   - Keyword-rich
   - Compelling

5. Product Highlights (5 bullet points)
   - Benefit-focused
   - Scannable

Output as JSON with all variations.
```

---

### Section 8: Regulatory Compliance (Hybrid)

**Purpose**: Check compliance requirements with database + AI analysis

**MCP Database Query**:
```sql
-- Check restricted ingredients
SELECT 
  im.name,
  im.restrictions,
  im.max_concentration,
  im.warning_labels
FROM ingredients_master im
WHERE im.id = ANY($1::uuid[])
  AND im.restrictions IS NOT NULL;

-- Get BPOM requirements
SELECT 
  requirement_type,
  description,
  timeline_days,
  estimated_cost
FROM regulatory_requirements
WHERE country = 'Indonesia'
  AND product_type = $1;
```

**Gemini Analysis**:
```
Analyze regulatory compliance for this product:

Ingredients: {{ingredients}}
Restricted Ingredients Found: {{restrictedIngredients}}
Claims: {{claims}}
Target Market: Indonesia

Database Requirements:
{{bpomRequirements}}

Provide:
1. BPOM registration process (step-by-step)
2. Halal certification requirements (if needed)
3. Labeling requirements
4. Claims substantiation needed
5. Estimated timeline (days)
6. Estimated costs (IDR)
7. Risk assessment (Low/Medium/High)
8. Recommendations

Output as structured JSON.
```

---

### Section 9: Production Timeline (Hybrid)

**Purpose**: Create realistic production timeline with lead times

**MCP Database Query**:
```sql
-- Get supplier lead times
SELECT 
  s.name as supplier_name,
  si.lead_time_days,
  si.moq
FROM supplier_ingredients si
JOIN suppliers s ON si.supplier_id = s.id
WHERE si.ingredient_id = ANY($1::uuid[]);

-- Get production milestones
SELECT 
  milestone_name,
  typical_duration_days,
  dependencies
FROM production_milestones
WHERE product_type = $1
ORDER BY sequence;
```

**Gemini Planning**:
```
Create a detailed production timeline:

Product: {{productType}}
Batch Size: {{batchSize}}
Supplier Lead Times: {{leadTimes}}
Compliance Requirements: {{complianceTimeline}}

Generate timeline with:
1. Pre-production (formulation, testing)
2. Ingredient procurement
3. Manufacturing
4. Quality control
5. Packaging
6. Regulatory approval
7. Launch preparation

For each phase:
- Duration (days)
- Dependencies
- Key milestones
- Risk factors

Output as JSON with Gantt chart data.
```

---

### Section 10: Sustainability (Hybrid)

**Purpose**: Assess environmental impact with data + AI analysis

**MCP Database Query**:
```sql
-- Get ingredient sustainability scores
SELECT 
  im.name,
  im.sustainability_score,
  im.carbon_footprint_kg,
  im.water_usage_liters,
  im.biodegradable,
  im.renewable_source
FROM ingredients_master im
WHERE im.id = ANY($1::uuid[]);

-- Get packaging sustainability
SELECT 
  material_type,
  recyclable,
  biodegradable,
  carbon_footprint_kg
FROM packaging_materials
WHERE type = $1;
```

**Gemini Analysis**:
```
Assess sustainability for this product:

Ingredients Sustainability:
{{ingredientSustainability}}

Packaging:
{{packagingSustainability}}

Provide:
1. Overall sustainability score (0-100)
2. Carbon footprint calculation
3. Water usage assessment
4. Biodegradability analysis
5. Renewable vs non-renewable ratio
6. Improvement recommendations
7. Certifications to pursue (e.g., EcoCert)
8. Marketing claims (what can be claimed)

Output as structured JSON.
```

---

### Section 11: Next Steps (AI Agent)

**Purpose**: Generate actionable next steps based on all previous sections

**Gemini Prompt**:
```
You are a strategic project manager for beauty product launches.

Based on the complete product brief:

Product: {{productName}}
Formulation: {{formulation}}
Market Analysis: {{marketAnalysis}}
Pricing: {{pricing}}
Compliance: {{compliance}}
Timeline: {{timeline}}

Generate prioritized next steps:

1. Immediate Actions (Week 1-2)
   - Critical path items
   - Quick wins

2. Short-term (Month 1)
   - Key milestones
   - Resource allocation

3. Medium-term (Month 2-3)
   - Production ramp-up
   - Marketing preparation

4. Long-term (Month 4-6)
   - Launch activities
   - Post-launch monitoring

For each step:
- Action item
- Owner/responsible party
- Deadline
- Dependencies
- Success criteria

Output as JSON with actionable checklist.
```

---

## 🔗 Integration with Main Orchestrator

### Main Orchestrator Updates Needed

**Current**: `00-main-orchestrator.json` (basic routing)

**Enhanced Version** (to create):
```json
{
  "name": "Main Orchestrator - Enhanced",
  "nodes": [
    "Webhook Receiver",
    "Validate & Extract",
    "Update Status to Running",
    "Create Workflow Run",
    
    // PARALLEL GROUP 1 (AI Agents - Creative)
    "Route to Section 1 (Product Header)",
    "Route to Section 2 (Description)",
    "Route to Section 3 (Alt Names)",
    
    // PARALLEL GROUP 2 (Mixed)
    "Route to Section 4 (Ingredients - MCP)",
    "Route to Section 5 (Market - Hybrid)",
    "Route to Section 6 (Marketing Copy)",
    
    // PARALLEL GROUP 3 (MCP/Hybrid)
    "Route to Section 7 (Pricing - MCP)",
    "Route to Section 8 (Compliance - Hybrid)",
    
    // Wait for all parallel groups
    "Merge Parallel Results",
    
    // SEQUENTIAL
    "Route to Section 9 (Timeline - Hybrid)",
    "Route to Section 10 (Sustainability - Hybrid)",
    "Route to Section 11 (Next Steps)",
    
    // FINAL
    "Aggregate All Results",
    "QA Check",
    "Update Database",
    "Callback to Next.js",
    "Audit Log",
    "Webhook Response"
  ]
}
```

---

## 📦 File Structure to Create

```
automation/LBF Technoglow Simulator v1/
├── 01-Workflows/
│   ├── 00-main-orchestrator.json ✅ EXISTS
│   ├── 00-main-orchestrator-enhanced.json ⏳ TO CREATE
│   │
│   ├── 01-AI-Agent-Sections/
│   │   ├── section-01-product-header.json ✅ EXISTS (copy from n8n folder)
│   │   ├── section-02-product-description.json ⏳ TO CREATE
│   │   ├── section-03-alternative-names.json ⏳ TO CREATE
│   │   ├── section-06-marketing-copy.json ⏳ TO CREATE
│   │   └── section-11-next-steps.json ⏳ TO CREATE
│   │
│   ├── 02-MCP-Sections/
│   │   ├── section-04-ingredient-breakdown.json ⏳ TO CREATE
│   │   └── section-07-pricing-structure.json ✅ EXISTS (copy from n8n folder)
│   │
│   └── 03-Hybrid-Sections/
│       ├── section-05-market-analysis.json ⏳ TO CREATE
│       ├── section-08-regulatory-compliance.json ⏳ TO CREATE
│       ├── section-09-production-timeline.json ⏳ TO CREATE
│       └── section-10-sustainability.json ⏳ TO CREATE
│
└── 06-Import-Order/
    └── import-sequence.md ⏳ TO CREATE
```

---

## ✅ Implementation Checklist

### Phase 1: Copy Existing Workflows
- [ ] Copy `section-01-product-header.json` from n8n folder
- [ ] Copy `section-07-pricing-structure.json` from n8n folder
- [ ] Verify both work with current structure

### Phase 2: Create AI Agent Workflows
- [ ] Section 2: Product Description
- [ ] Section 3: Alternative Names
- [ ] Section 6: Marketing Copy
- [ ] Section 11: Next Steps

### Phase 3: Create MCP Workflows
- [ ] Section 4: Ingredient Breakdown

### Phase 4: Create Hybrid Workflows
- [ ] Section 5: Market Analysis
- [ ] Section 8: Regulatory Compliance
- [ ] Section 9: Production Timeline
- [ ] Section 10: Sustainability

### Phase 5: Enhanced Main Orchestrator
- [ ] Create enhanced version with all routing
- [ ] Add parallel execution logic
- [ ] Add merge and aggregation
- [ ] Add QA checks

### Phase 6: Documentation
- [ ] Create import sequence guide
- [ ] Update README with new workflows
- [ ] Create testing guide for each workflow
- [ ] Document MCP configuration

### Phase 7: Testing
- [ ] Test each workflow individually
- [ ] Test parallel execution
- [ ] Test complete end-to-end flow
- [ ] Performance testing

---

## 🎯 Success Criteria

✅ All 11 section workflows created  
✅ Enhanced main orchestrator with routing  
✅ All workflows tested individually  
✅ End-to-end test successful  
✅ Processing time < 4 minutes  
✅ All sections generate valid JSON  
✅ Database updates successful  
✅ Callback to Next.js works  

---

## 📞 Next Actions

1. **Review this plan** - Confirm approach
2. **Start Phase 1** - Copy existing workflows
3. **Create Phase 2** - AI Agent workflows (easiest)
4. **Create Phase 3** - MCP workflows
5. **Create Phase 4** - Hybrid workflows (most complex)
6. **Create Phase 5** - Enhanced orchestrator
7. **Test everything** - Individual + E2E

---

**Estimated Time**:
- Phase 1: 30 minutes
- Phase 2: 2-3 hours (4 workflows)
- Phase 3: 1 hour (1 workflow)
- Phase 4: 3-4 hours (4 workflows)
- Phase 5: 2 hours (enhanced orchestrator)
- Phase 6: 1 hour (documentation)
- Phase 7: 2-3 hours (testing)

**Total**: 12-15 hours of work

---

**Ready to start implementation! 🚀✨**

**Version**: 1.0.0  
**Last Updated**: October 20, 2025  
**Maintained by**: LBF Technoglow Team
