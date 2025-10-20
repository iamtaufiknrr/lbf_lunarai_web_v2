# 🔗 Webhook URLs - LunarAI Beauty

## 🌐 N8N Instance

**Base URL**: `https://n8n-gczfssttvtzs.nasgor.sumopod.my.id`

---

## 📍 Main Webhooks

### Test Environment
```
https://n8n-gczfssttvtzs.nasgor.sumopod.my.id/webhook-test/lbf_skincare
```

### Production Environment
```
https://n8n-gczfssttvtzs.nasgor.sumopod.my.id/webhook/lbf_skincare
```

---

## 📦 Section Webhooks

### Section 1 - Product Header
```
https://n8n-gczfssttvtzs.nasgor.sumopod.my.id/webhook/section-1-product-header
```

### Section 2 - Product Description
```
https://n8n-gczfssttvtzs.nasgor.sumopod.my.id/webhook/section-2-product-description
```

### Section 3 - Alternative Names
```
https://n8n-gczfssttvtzs.nasgor.sumopod.my.id/webhook/section-3-alternative-names
```

### Section 4 - Ingredient Breakdown
```
https://n8n-gczfssttvtzs.nasgor.sumopod.my.id/webhook/section-4-ingredient-breakdown
```

### Section 5 - Market Analysis
```
https://n8n-gczfssttvtzs.nasgor.sumopod.my.id/webhook/section-5-market-analysis
```

### Section 6 - Marketing Copy
```
https://n8n-gczfssttvtzs.nasgor.sumopod.my.id/webhook/section-6-marketing-copy
```

### Section 7 - Pricing Structure
```
https://n8n-gczfssttvtzs.nasgor.sumopod.my.id/webhook/section-7-pricing-structure
```

### Section 8 - Regulatory Compliance
```
https://n8n-gczfssttvtzs.nasgor.sumopod.my.id/webhook/section-8-regulatory-compliance
```

### Section 9 - Production Timeline
```
https://n8n-gczfssttvtzs.nasgor.sumopod.my.id/webhook/section-9-production-timeline
```

### Section 10 - Sustainability
```
https://n8n-gczfssttvtzs.nasgor.sumopod.my.id/webhook/section-10-sustainability
```

### Section 11 - Next Steps
```
https://n8n-gczfssttvtzs.nasgor.sumopod.my.id/webhook/section-11-next-steps
```

---

## 🔧 Configuration

### Environment Variables (.env.local)

```bash
# N8N Configuration
N8N_WEBHOOK_BASE="https://n8n-gczfssttvtzs.nasgor.sumopod.my.id"
N8N_TEST_WEBHOOK="https://n8n-gczfssttvtzs.nasgor.sumopod.my.id/webhook-test/lbf_skincare"
N8N_PRODUCTION_WEBHOOK="https://n8n-gczfssttvtzs.nasgor.sumopod.my.id/webhook/lbf_skincare"
N8N_WEBHOOK_SECRET="your-secret-key-here"

# Section Webhooks
SECTION_1_WEBHOOK="https://n8n-gczfssttvtzs.nasgor.sumopod.my.id/webhook/section-1-product-header"
SECTION_2_WEBHOOK="https://n8n-gczfssttvtzs.nasgor.sumopod.my.id/webhook/section-2-product-description"
SECTION_3_WEBHOOK="https://n8n-gczfssttvtzs.nasgor.sumopod.my.id/webhook/section-3-alternative-names"
SECTION_4_WEBHOOK="https://n8n-gczfssttvtzs.nasgor.sumopod.my.id/webhook/section-4-ingredient-breakdown"
SECTION_5_WEBHOOK="https://n8n-gczfssttvtzs.nasgor.sumopod.my.id/webhook/section-5-market-analysis"
SECTION_6_WEBHOOK="https://n8n-gczfssttvtzs.nasgor.sumopod.my.id/webhook/section-6-marketing-copy"
SECTION_7_WEBHOOK="https://n8n-gczfssttvtzs.nasgor.sumopod.my.id/webhook/section-7-pricing-structure"
SECTION_8_WEBHOOK="https://n8n-gczfssttvtzs.nasgor.sumopod.my.id/webhook/section-8-regulatory-compliance"
SECTION_9_WEBHOOK="https://n8n-gczfssttvtzs.nasgor.sumopod.my.id/webhook/section-9-production-timeline"
SECTION_10_WEBHOOK="https://n8n-gczfssttvtzs.nasgor.sumopod.my.id/webhook/section-10-sustainability"
SECTION_11_WEBHOOK="https://n8n-gczfssttvtzs.nasgor.sumopod.my.id/webhook/section-11-next-steps"
```

---

## 🧪 Testing

### Test Main Webhook
```bash
curl -X POST https://n8n-gczfssttvtzs.nasgor.sumopod.my.id/webhook-test/lbf_skincare \
  -H "Content-Type: application/json" \
  -H "X-Webhook-Secret: your-secret" \
  -d '{
    "submissionId": "test-123",
    "brand": {"name": "TestBrand"},
    "productBlueprint": {"formType": "Serum"}
  }'
```

### Test Section 1 Webhook
```bash
curl -X POST https://n8n-gczfssttvtzs.nasgor.sumopod.my.id/webhook/section-1-product-header \
  -H "Content-Type: application/json" \
  -d '{
    "submissionId": "test-123",
    "context": {
      "brand": {"name": "TestBrand", "voice": "Modern"},
      "product": {"type": "Serum", "functions": ["Brightening"]}
    }
  }'
```

---

## 📊 Webhook Paths

| Workflow | Path | Full URL |
|----------|------|----------|
| Main (Test) | `/webhook-test/lbf_skincare` | https://n8n-gczfssttvtzs.nasgor.sumopod.my.id/webhook-test/lbf_skincare |
| Main (Prod) | `/webhook/lbf_skincare` | https://n8n-gczfssttvtzs.nasgor.sumopod.my.id/webhook/lbf_skincare |
| Section 1 | `/webhook/section-1-product-header` | https://n8n-gczfssttvtzs.nasgor.sumopod.my.id/webhook/section-1-product-header |
| Section 2 | `/webhook/section-2-product-description` | https://n8n-gczfssttvtzs.nasgor.sumopod.my.id/webhook/section-2-product-description |
| Section 3 | `/webhook/section-3-alternative-names` | https://n8n-gczfssttvtzs.nasgor.sumopod.my.id/webhook/section-3-alternative-names |
| Section 4 | `/webhook/section-4-ingredient-breakdown` | https://n8n-gczfssttvtzs.nasgor.sumopod.my.id/webhook/section-4-ingredient-breakdown |
| Section 5 | `/webhook/section-5-market-analysis` | https://n8n-gczfssttvtzs.nasgor.sumopod.my.id/webhook/section-5-market-analysis |
| Section 6 | `/webhook/section-6-marketing-copy` | https://n8n-gczfssttvtzs.nasgor.sumopod.my.id/webhook/section-6-marketing-copy |
| Section 7 | `/webhook/section-7-pricing-structure` | https://n8n-gczfssttvtzs.nasgor.sumopod.my.id/webhook/section-7-pricing-structure |
| Section 8 | `/webhook/section-8-regulatory-compliance` | https://n8n-gczfssttvtzs.nasgor.sumopod.my.id/webhook/section-8-regulatory-compliance |
| Section 9 | `/webhook/section-9-production-timeline` | https://n8n-gczfssttvtzs.nasgor.sumopod.my.id/webhook/section-9-production-timeline |
| Section 10 | `/webhook/section-10-sustainability` | https://n8n-gczfssttvtzs.nasgor.sumopod.my.id/webhook/section-10-sustainability |
| Section 11 | `/webhook/section-11-next-steps` | https://n8n-gczfssttvtzs.nasgor.sumopod.my.id/webhook/section-11-next-steps |

---

## 🔐 Authentication

All webhooks require:
- **Header**: `X-Webhook-Secret`
- **Value**: Your secret key (set in environment variables)

Example:
```bash
-H "X-Webhook-Secret: your-secret-key-here"
```

---

## ✅ Setup Checklist

- [x] Webhook URLs updated in `.env.example`
- [x] Main orchestrator JSON updated
- [x] Section 1 JSON updated
- [x] Section 7 JSON updated
- [ ] Copy `.env.example` to `.env.local`
- [ ] Set `N8N_WEBHOOK_SECRET`
- [ ] Import workflows to n8n
- [ ] Test each webhook
- [ ] Verify production webhook

---

*Last Updated: October 18, 2025*  
*Instance: n8n-gczfssttvtzs.nasgor.sumopod.my.id*
