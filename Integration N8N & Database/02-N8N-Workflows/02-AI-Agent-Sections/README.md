# 🤖 AI Agent Sections

## Overview

Folder ini berisi **workflow sections yang menggunakan pure AI Agent** (Gemini Pro) tanpa MCP tools. Sections ini fokus pada **kreativitas, copywriting, dan planning**.

## Sections dalam Folder Ini

### 1. Section 1 - Product Header
**File**: `section-01-product-header.json`
- **Purpose**: Generate product name dan tagline
- **AI Model**: Gemini Pro (temperature: 0.7)
- **Duration**: ~20 seconds
- **Input**: Brand context, product type, functions
- **Output**: Product name, tagline, short description

### 2. Section 2 - Product Description
**File**: `section-02-product-description.json`
- **Purpose**: Generate comprehensive product description
- **AI Model**: Gemini Pro (temperature: 0.7)
- **Duration**: ~30 seconds
- **Input**: Product header, ingredients, target audience
- **Output**: 250-300 words description, key highlights

### 3. Section 3 - Alternative Names
**File**: `section-03-alternative-names.json`
- **Purpose**: Generate 10-15 alternative product names
- **AI Model**: Gemini Pro (temperature: 0.7)
- **Duration**: ~25 seconds
- **Input**: Brand context, product type
- **Output**: List of alternative names with rationale

### 4. Section 6 - Marketing Copy
**File**: `section-06-marketing-copy.json`
- **Purpose**: Generate marketing copy (headlines, CTAs, social media)
- **AI Model**: Gemini Pro (temperature: 0.7)
- **Duration**: ~35 seconds
- **Input**: Product description, target audience
- **Output**: Headlines, body copy, CTAs, social captions

### 5. Section 11 - Next Steps
**File**: `section-11-next-steps.json`
- **Purpose**: Generate prioritized action plan
- **AI Model**: Gemini Pro (temperature: 0.3)
- **Duration**: ~25 seconds
- **Input**: All previous sections
- **Output**: Action items, timeline, resources

## Common Workflow Structure

Semua AI Agent sections mengikuti struktur yang sama:

```
┌─────────────────────────────────────────┐
│     WEBHOOK TRIGGER                      │
│  POST /webhook/section-X                │
└─────────────────────────────────────────┘
              ↓
┌─────────────────────────────────────────┐
│     EXTRACT CONTEXT                      │
│  Parse submissionId & context           │
└─────────────────────────────────────────┘
              ↓
┌─────────────────────────────────────────┐
│     RETRIEVE MEMORY (Optional)           │
│  Get previous section results           │
└─────────────────────────────────────────┘
              ↓
┌─────────────────────────────────────────┐
│     AI AGENT NODE                        │
│  ├─ Chat Model: Gemini Pro              │
│  ├─ Memory: PostgreSQL                  │
│  └─ Tools: None (pure AI)               │
└─────────────────────────────────────────┘
              ↓
┌─────────────────────────────────────────┐
│     FORMAT OUTPUT                        │
│  Structure as JSON                      │
└─────────────────────────────────────────┘
              ↓
┌─────────────────────────────────────────┐
│     STORE RESULT                         │
│  Save to agent_memory table             │
└─────────────────────────────────────────┘
              ↓
┌─────────────────────────────────────────┐
│     RETURN RESPONSE                      │
│  Return to main orchestrator            │
└─────────────────────────────────────────┘
```

## AI Agent Configuration

### Gemini Pro Settings

```json
{
  "model": "gemini-pro",
  "temperature": 0.7,
  "maxTokens": 2048,
  "topP": 0.9,
  "topK": 40
}
```

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
  "sessionIdExpression": "={{$json.submissionId}}"
}
```

## Input Format (Standard)

```json
{
  "submissionId": "uuid-v4",
  "context": {
    "brand": {
      "name": "Brand Name",
      "voice": "Modern, Professional",
      "values": "Sustainability"
    },
    "product": {
      "type": "Serum",
      "functions": ["Brightening"],
      "targetPrice": 450000
    },
    "target": {
      "gender": "All",
      "ageRanges": ["25-34"]
    }
  }
}
```

## Output Format (Standard)

```json
{
  "sectionType": "productHeader",
  "submissionId": "uuid-v4",
  "content": {
    "name": "Product Name",
    "tagline": "Catchy Tagline",
    "shortDescription": "Description here"
  },
  "metadata": {
    "model": "gemini-pro",
    "temperature": 0.7,
    "tokensUsed": 1500,
    "processingTime": 20000
  }
}
```

## Environment Variables

```bash
# AI API
GOOGLE_AI_API_KEY=your-gemini-api-key

# Database (for memory)
DATABASE_HOST=your-host.neon.tech
DATABASE_NAME=lunarai_db
DATABASE_USER=your_user
DATABASE_PASSWORD=your_password

# Section Webhooks
SECTION_1_WEBHOOK=https://n8n.../webhook/section-1
SECTION_2_WEBHOOK=https://n8n.../webhook/section-2
SECTION_3_WEBHOOK=https://n8n.../webhook/section-3
SECTION_6_WEBHOOK=https://n8n.../webhook/section-6
SECTION_11_WEBHOOK=https://n8n.../webhook/section-11
```

## Testing Individual Sections

```bash
# Test Section 1
curl -X POST https://your-n8n.../webhook/section-1 \
  -H "Content-Type: application/json" \
  -d '{
    "submissionId": "test-uuid-1",
    "context": {
      "brand": {"name": "TestBrand", "voice": "Modern"},
      "product": {"type": "Serum", "functions": ["Brightening"]}
    }
  }'
```

## Import Order

1. Import Section 1 first (simplest)
2. Test Section 1 thoroughly
3. Import remaining sections
4. Configure Gemini API credentials
5. Test each section individually
6. Test integration with main orchestrator

## Performance Monitoring

Monitor these metrics untuk setiap section:
- **Response Time**: Should be < 40s
- **Token Usage**: Track costs
- **Success Rate**: Should be > 98%
- **Output Quality**: Manual review samples

## Troubleshooting

### Issue: AI Agent timeout
**Solution**: Increase timeout in HTTP Request node

### Issue: Memory not persisting
**Solution**: Check PostgreSQL connection and agent_memory table

### Issue: Poor output quality
**Solution**: Adjust temperature or refine prompt

---

**Pure AI Agent sections untuk kreativitas maksimal! 🚀**
