# 🤖🔧 Hybrid Sections

## Overview

Folder ini berisi **workflow sections yang menggunakan kombinasi AI Agent (Gemini Pro) + MCP Tools**. Sections ini membutuhkan **analysis + real-time data** untuk hasil optimal.

## Sections dalam Folder Ini

### 1. Section 5 - Market Analysis
**File**: `section-05-market-analysis.json`
- **AI**: Gemini Pro (analytical, temp: 0.3)
- **MCP**: Web Search (Tavily)
- **Duration**: ~45 seconds
- **Purpose**: Analyze market trends + competitor intelligence

### 2. Section 8 - Regulatory Compliance
**File**: `section-08-regulatory-compliance.json`
- **AI**: Gemini Pro (analytical, temp: 0.3)
- **MCP**: Database (restricted ingredients) + Web Search (BPOM updates)
- **Duration**: ~35 seconds
- **Purpose**: Compliance checking + regulatory interpretation

### 3. Section 9 - Production Timeline
**File**: `section-09-production-timeline.json`
- **AI**: Gemini Pro (planning, temp: 0.3)
- **MCP**: Database (supplier lead times)
- **Duration**: ~30 seconds
- **Purpose**: Generate production schedule with real lead times

### 4. Section 10 - Sustainability Assessment
**File**: `section-10-sustainability.json`
- **AI**: Gemini Pro (analytical, temp: 0.3)
- **MCP**: Database (ingredient sustainability data)
- **Duration**: ~30 seconds
- **Purpose**: Calculate sustainability score + recommendations

## Hybrid Workflow Pattern

```
┌─────────────────────────────────────────┐
│     WEBHOOK TRIGGER                      │
└─────────────────────────────────────────┘
              ↓
┌─────────────────────────────────────────┐
│     EXTRACT CONTEXT                      │
└─────────────────────────────────────────┘
              ↓
┌─────────────────────────────────────────┐
│     MCP - GATHER DATA                    │
│  Query database / web search            │
└─────────────────────────────────────────┘
              ↓
┌─────────────────────────────────────────┐
│     PREPARE AI CONTEXT                   │
│  Combine MCP data with context          │
└─────────────────────────────────────────┘
              ↓
┌─────────────────────────────────────────┐
│     AI AGENT - ANALYZE                   │
│  ├─ Chat Model: Gemini Pro              │
│  ├─ Memory: PostgreSQL                  │
│  └─ Tools: MCP Tools                    │
└─────────────────────────────────────────┘
              ↓
┌─────────────────────────────────────────┐
│     FORMAT OUTPUT                        │
└─────────────────────────────────────────┘
              ↓
┌─────────────────────────────────────────┐
│     STORE RESULT                         │
└─────────────────────────────────────────┘
              ↓
┌─────────────────────────────────────────┐
│     RETURN RESPONSE                      │
└─────────────────────────────────────────┘
```

## Section 5: Market Analysis

### MCP Tools Used
- **Tavily Web Search**: Real-time market data
- **Database**: Historical market data

### AI Agent Role
- Analyze search results
- Generate insights and SWOT
- Identify opportunities

### Input
```json
{
  "submissionId": "uuid",
  "context": {
    "product": {
      "type": "Serum",
      "functions": ["Brightening"],
      "targetPrice": 450000
    },
    "target": {
      "location": {"country": "Indonesia"}
    }
  }
}
```

### Output
```json
{
  "sectionType": "marketAnalysis",
  "content": {
    "marketSize": {
      "current": "IDR 15 trillion",
      "growth": "12% CAGR"
    },
    "competitors": [...],
    "trends": [...],
    "swot": {...},
    "recommendations": {...}
  }
}
```

## Section 8: Regulatory Compliance

### MCP Tools Used
- **Database**: Query restricted ingredients
- **Web Search**: Latest BPOM regulations

### AI Agent Role
- Interpret complex regulations
- Generate compliance checklist
- Estimate timeline and costs

### Input
```json
{
  "submissionId": "uuid",
  "context": {
    "ingredients": [...],
    "claims": ["Brightening", "Anti-aging"],
    "certifications": ["Halal", "BPOM"]
  }
}
```

### Output
```json
{
  "sectionType": "regulatory",
  "content": {
    "bpom": {
      "classification": "Kosmetik",
      "timeline": "3 months",
      "cost": "IDR 5,000,000"
    },
    "halal": {...},
    "restrictions": [],
    "timeline": {...}
  }
}
```

## Section 9: Production Timeline

### MCP Tools Used
- **Database**: Query supplier lead times
- **Database**: Query production capacity

### AI Agent Role
- Generate intelligent schedule
- Critical path analysis
- Resource optimization

### Input
```json
{
  "submissionId": "uuid",
  "context": {
    "product": {...},
    "complexity": "Medium",
    "batchSize": 1000,
    "certifications": ["BPOM", "Halal"]
  }
}
```

### Output
```json
{
  "sectionType": "productionTimeline",
  "content": {
    "phases": [...],
    "criticalPath": [...],
    "milestones": [...],
    "totalDuration": "12 weeks"
  }
}
```

## Section 10: Sustainability Assessment

### MCP Tools Used
- **Database**: Ingredient sustainability scores
- **Database**: Packaging environmental data

### AI Agent Role
- Calculate overall score
- Environmental impact analysis
- Generate recommendations

### Input
```json
{
  "submissionId": "uuid",
  "context": {
    "ingredients": [...],
    "packaging": {
      "type": "Glass Bottle",
      "material": "Recycled Glass"
    }
  }
}
```

### Output
```json
{
  "sectionType": "sustainability",
  "content": {
    "overallScore": 85,
    "categoryScores": {...},
    "environmentalImpact": {...},
    "recommendations": [...]
  }
}
```

## MCP Configuration for Hybrid

```json
{
  "mcpServers": {
    "database": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-postgres"],
      "env": {"DATABASE_URL": "{{$env.DATABASE_URL}}"}
    },
    "web-search": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-tavily"],
      "env": {"TAVILY_API_KEY": "{{$env.TAVILY_API_KEY}}"}
    }
  }
}
```

## Gemini AI Configuration

```json
{
  "model": "gemini-pro",
  "temperature": 0.3,
  "maxTokens": 2048,
  "topP": 0.9
}
```

## Environment Variables

```bash
# AI API
GOOGLE_AI_API_KEY=your-gemini-key

# Database
DATABASE_URL=postgresql://...

# Web Search
TAVILY_API_KEY=your-tavily-key

# Webhooks
SECTION_5_WEBHOOK=https://n8n.../webhook/section-5
SECTION_8_WEBHOOK=https://n8n.../webhook/section-8
SECTION_9_WEBHOOK=https://n8n.../webhook/section-9
SECTION_10_WEBHOOK=https://n8n.../webhook/section-10
```

## Testing

```bash
# Test Section 5
curl -X POST https://n8n.../webhook/section-5 \
  -H "Content-Type: application/json" \
  -d @test-section-5.json

# Test Section 8
curl -X POST https://n8n.../webhook/section-8 \
  -H "Content-Type: application/json" \
  -d @test-section-8.json
```

## Best Practices

### 1. Data First, AI Second
```javascript
// ✅ Good: Get data first
const mcpData = await queryDatabase();
const aiAnalysis = await analyzeWithAI(mcpData);

// ❌ Bad: AI without data
const aiGuess = await analyzeWithAI();
```

### 2. Error Handling
```javascript
try {
  const mcpData = await queryMCP();
} catch (error) {
  // Fallback to cached data
  const mcpData = await getCachedData();
}
```

### 3. Context Management
```javascript
// Combine MCP data with context
const fullContext = {
  ...userContext,
  mcpData: mcpResults,
  timestamp: Date.now()
};
```

---

**Hybrid sections untuk best of both worlds! 🤖🔧**
