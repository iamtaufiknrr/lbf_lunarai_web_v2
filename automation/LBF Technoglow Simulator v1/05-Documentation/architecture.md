# 🏗️ System Architecture - LBF Technoglow Simulator v1

## 📋 Overview

Dokumentasi lengkap arsitektur sistem LBF Technoglow Simulator - platform AI-powered untuk product development di industri kosmetik Indonesia.

---

## 🎯 High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                          CLIENT LAYER                                │
│                                                                       │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐              │
│  │   Browser    │  │    Mobile    │  │     API      │              │
│  │   (React)    │  │   (Future)   │  │   Clients    │              │
│  └──────────────┘  └──────────────┘  └──────────────┘              │
└────────────────────────────┬────────────────────────────────────────┘
                             │
                             │ HTTPS
                             ▼
┌─────────────────────────────────────────────────────────────────────┐
│                      APPLICATION LAYER                               │
│                     (Next.js 14 - Vercel)                           │
│                                                                       │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │                      API Routes                               │  │
│  │  • POST /api/submit      - Form submission                   │  │
│  │  • GET  /api/result/[id] - Get report                        │  │
│  │  • POST /api/sync        - n8n callback                      │  │
│  └──────────────────────────────────────────────────────────────┘  │
│                                                                       │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │                    Business Logic                             │  │
│  │  • Validation (Zod)                                          │  │
│  │  • Persistence (Drizzle ORM)                                 │  │
│  │  • Webhook Dispatch                                          │  │
│  └──────────────────────────────────────────────────────────────┘  │
└────────────────────────────┬────────────────────────────────────────┘
                             │
                ┌────────────┼────────────┐
                │            │            │
                ▼            ▼            ▼
┌──────────────────┐  ┌──────────────────┐  ┌──────────────────┐
│   DATA LAYER     │  │  WORKFLOW LAYER  │  │   AI LAYER       │
│  (Neon Postgres) │  │     (n8n)        │  │  (OpenAI/Claude) │
└──────────────────┘  └──────────────────┘  └──────────────────┘
```

---

## 🔄 Data Flow Architecture

### 1. Submission Flow

```
User fills form
      │
      ▼
Client-side validation (React Hook Form + Zod)
      │
      ▼
POST /api/submit
      │
      ├─→ Validate payload (Zod schema)
      │
      ├─→ Generate UUID (submissionId)
      │
      ├─→ Save to database
      │   ├─→ submissions table
      │   └─→ submission_payloads table
      │
      ├─→ Dispatch to n8n webhook
      │   ├─→ Add X-Webhook-Secret header
      │   └─→ POST to N8N_PRODUCTION_WEBHOOK
      │
      ├─→ Create workflow_run record
      │
      ├─→ Create audit_log
      │
      └─→ Return response to client
          {
            "submissionId": "uuid",
            "status": "queued",
            "message": "Success"
          }
```

### 2. Processing Flow (n8n)

```
n8n receives webhook
      │
      ▼
Main Orchestrator
      │
      ├─→ Validate webhook signature
      │
      ├─→ Update submission status to "running"
      │
      ├─→ Create workflow_run record
      │
      └─→ Route to agents
          │
          ├─→ PARALLEL EXECUTION (2 min)
          │   ├─→ Formulation Agent (GPT-4)
          │   │   └─→ Analyze ingredients, formulation
          │   │
          │   ├─→ Market Research Agent (GPT-4 + Tavily)
          │   │   └─→ Market analysis, competitors
          │   │
          │   └─→ Copywriting Agent (Claude 3.5)
          │       └─→ Product names, descriptions
          │
          └─→ SEQUENTIAL EXECUTION (1 min)
              ├─→ Compliance Agent (GPT-4)
              │   └─→ BPOM, Halal requirements
              │
              └─→ Pricing Agent (GPT-4 + DB)
                  └─→ Cost calculation, pricing
```

### 3. Aggregation & Callback Flow

```
All agents complete
      │
      ▼
Final Aggregator
      │
      ├─→ Merge all results
      │
      ├─→ Validate completeness
      │
      ├─→ Format report sections
      │
      └─→ POST /api/sync (callback to Next.js)
          {
            "submissionId": "uuid",
            "status": "completed",
            "reportSections": [...]
          }
          │
          ▼
Next.js receives callback
      │
      ├─→ Validate submissionId
      │
      ├─→ Save report sections to database
      │   └─→ report_sections table
      │
      ├─→ Update submission status to "completed"
      │
      └─→ Create audit_log
```

### 4. Result Retrieval Flow

```
User visits /result/[id]
      │
      ▼
GET /api/result/[id]
      │
      ├─→ Fetch submission data
      │   └─→ SELECT FROM submissions WHERE id = ?
      │
      ├─→ Fetch submission payload
      │   └─→ SELECT FROM submission_payloads WHERE submission_id = ?
      │
      ├─→ Fetch workflow run
      │   └─→ SELECT FROM workflow_runs WHERE submission_id = ?
      │
      ├─→ Fetch report sections
      │   └─→ SELECT FROM report_sections WHERE submission_id = ? ORDER BY order
      │
      └─→ Return complete report
          {
            "submissionId": "uuid",
            "status": "completed",
            "submittedAt": "timestamp",
            "payload": {...},
            "sections": {...}
          }
```

---

## 💾 Database Architecture

### Entity Relationship Diagram

```
┌─────────────────────┐
│    submissions      │
│─────────────────────│
│ id (PK)             │
│ submitted_at        │
│ target_environment  │
│ brand_name          │
│ status              │
│ created_at          │
│ updated_at          │
└──────────┬──────────┘
           │
           │ 1:1
           ▼
┌─────────────────────┐
│ submission_payloads │
│─────────────────────│
│ id (PK)             │
│ submission_id (FK)  │
│ payload (JSONB)     │
│ created_at          │
└─────────────────────┘

┌─────────────────────┐
│    submissions      │
└──────────┬──────────┘
           │
           │ 1:N
           ▼
┌─────────────────────┐
│   workflow_runs     │
│─────────────────────│
│ id (PK)             │
│ submission_id (FK)  │
│ webhook_url         │
│ webhook_response    │
│ status              │
│ retry_count         │
│ last_error          │
│ started_at          │
│ completed_at        │
│ created_at          │
│ updated_at          │
└─────────────────────┘

┌─────────────────────┐
│    submissions      │
└──────────┬──────────┘
           │
           │ 1:N
           ▼
┌─────────────────────┐
│  report_sections    │
│─────────────────────│
│ id (PK)             │
│ submission_id (FK)  │
│ section_type        │
│ section_data (JSONB)│
│ order               │
│ created_at          │
│ updated_at          │
└─────────────────────┘

┌─────────────────────┐
│    submissions      │
└──────────┬──────────┘
           │
           │ 1:N
           ▼
┌─────────────────────┐
│    audit_logs       │
│─────────────────────│
│ id (PK)             │
│ submission_id (FK)  │
│ action              │
│ actor_type          │
│ metadata (JSONB)    │
│ ip_address          │
│ user_agent          │
│ created_at          │
└─────────────────────┘
```

### Table Purposes

| Table | Purpose | Key Features |
|-------|---------|--------------|
| `submissions` | Track all form submissions | Status tracking, environment flag |
| `submission_payloads` | Store complete form data | JSONB for flexibility |
| `workflow_runs` | Track n8n executions | Retry logic, error tracking |
| `report_sections` | Store AI-generated content | Ordered sections, JSONB data |
| `audit_logs` | Complete audit trail | All actions logged |

---

## 🤖 AI Agent Architecture

### Agent Specifications

#### 1. Formulation Agent
```
Input:
  - Product blueprint (functions, form type, etc.)
  - Ingredients list
  - Concept narrative

Processing:
  - Analyze ingredient compatibility
  - Calculate percentages
  - Determine pH range
  - Assess stability
  - Generate INCI names

Output:
  - Complete formulation specification
  - Ingredient breakdown
  - pH recommendations
  - Stability notes
  - Manufacturing instructions

Model: GPT-4 Turbo
Tokens: ~2000 input, ~1500 output
Cost: ~$0.04 per execution
Time: ~60 seconds
```

#### 2. Market Research Agent
```
Input:
  - Brand information
  - Target location
  - Target demographics

Processing:
  - Web search for market data (Tavily)
  - Analyze competitors
  - Identify trends
  - Calculate market size
  - SWOT analysis

Output:
  - Market size & growth
  - Competitor analysis
  - Trend insights
  - SWOT matrix
  - Positioning recommendations

Model: GPT-4 + Tavily Search
Tokens: ~1500 input, ~2000 output
Cost: ~$0.05 per execution
Time: ~45 seconds
```

#### 3. Copywriting Agent
```
Input:
  - Brand voice & values
  - Product concept
  - Target audience

Processing:
  - Generate product names (5 options)
  - Create taglines (bilingual)
  - Write product descriptions
  - Craft marketing copy
  - Develop brand story

Output:
  - Product name options
  - Taglines (ID & EN)
  - Product descriptions
  - Marketing copy
  - Social media captions

Model: Claude 3.5 Sonnet
Tokens: ~1000 input, ~2000 output
Cost: ~$0.05 per execution
Time: ~30 seconds
```

#### 4. Compliance Agent
```
Input:
  - Ingredients list
  - Product claims
  - Target market

Processing:
  - Check BPOM requirements
  - Verify Halal compliance
  - Identify restricted ingredients
  - Calculate registration timeline
  - Generate checklist

Output:
  - BPOM registration guide
  - Halal certification process
  - Restricted ingredients list
  - Timeline estimate
  - Compliance checklist

Model: GPT-4
Tokens: ~1500 input, ~1500 output
Cost: ~$0.04 per execution
Time: ~30 seconds
```

#### 5. Pricing Agent
```
Input:
  - Ingredients list
  - Packaging specifications
  - Batch size
  - Target retail price

Processing:
  - Query ingredient prices from DB
  - Calculate manufacturing cost
  - Apply waste factor (15%)
  - Generate price ranges
  - Calculate margins
  - Break-even analysis

Output:
  - Manufacturing cost
  - Cost range (-20% to +30%)
  - Retail price recommendations
  - Margin analysis
  - Break-even units

Model: GPT-4 + Database Queries
Tokens: ~1000 input, ~1000 output
Cost: ~$0.03 per execution
Time: ~20 seconds
```

---

## 🔐 Security Architecture

### Authentication & Authorization

```
┌─────────────────────────────────────────────────────────────┐
│                    Security Layers                           │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  1. Transport Layer Security (TLS)                          │
│     • HTTPS enforced                                         │
│     • SSL certificates (Vercel/Let's Encrypt)               │
│                                                               │
│  2. Webhook Signature Verification                          │
│     • X-Webhook-Secret header                               │
│     • HMAC validation (optional)                            │
│                                                               │
│  3. Database Security                                        │
│     • SSL/TLS required                                       │
│     • Connection pooling                                     │
│     • Prepared statements (SQL injection prevention)        │
│                                                               │
│  4. API Key Management                                       │
│     • Environment variables                                  │
│     • Never committed to git                                 │
│     • Rotated regularly                                      │
│                                                               │
│  5. Input Validation                                         │
│     • Zod schema validation                                  │
│     • Type checking (TypeScript)                            │
│     • Sanitization                                           │
│                                                               │
│  6. Rate Limiting                                            │
│     • Vercel automatic DDoS protection                      │
│     • n8n execution limits                                   │
│     • Database connection limits                             │
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

### Data Protection

```
┌─────────────────────────────────────────────────────────────┐
│                    Data Protection                           │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  At Rest:                                                    │
│  • Database encryption (Neon)                               │
│  • Encrypted backups                                         │
│  • Secure credential storage                                 │
│                                                               │
│  In Transit:                                                 │
│  • TLS 1.3                                                   │
│  • HTTPS only                                                │
│  • Secure WebSocket (WSS)                                    │
│                                                               │
│  In Use:                                                     │
│  • Memory encryption                                         │
│  • Secure variable handling                                  │
│  • No logging of sensitive data                              │
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

---

## 📊 Performance Architecture

### Optimization Strategies

#### 1. Database Optimization
```sql
-- Indexes for fast queries
CREATE INDEX idx_submissions_status ON submissions(status);
CREATE INDEX idx_submissions_created_at ON submissions(created_at DESC);
CREATE INDEX idx_report_sections_submission_id ON report_sections(submission_id);

-- JSONB indexes for flexible queries
CREATE INDEX idx_submission_payloads_payload_gin 
  ON submission_payloads USING GIN (payload);

-- Views for common queries
CREATE VIEW v_submission_details AS
  SELECT s.*, sp.payload, wr.status AS workflow_status
  FROM submissions s
  LEFT JOIN submission_payloads sp ON s.id = sp.submission_id
  LEFT JOIN workflow_runs wr ON s.id = wr.submission_id;
```

#### 2. API Optimization
- Response caching (Vercel Edge)
- Minimal payload sizes
- Streaming responses (future)
- Connection pooling

#### 3. Workflow Optimization
- Parallel agent execution
- Timeout management
- Retry with exponential backoff
- Error handling

---

## 🔄 Scalability Architecture

### Current Capacity

| Component | Limit | Notes |
|-----------|-------|-------|
| Neon Database | 0.5 GB (free) | Upgrade to Scale/Pro for more |
| Vercel | 100 GB bandwidth/month | Hobby tier |
| n8n | 5-10 concurrent workflows | Cloud tier |
| OpenAI | Rate limits apply | Tier-based |
| Anthropic | Rate limits apply | Tier-based |

### Scaling Strategy

```
Phase 1: Current (0-100 submissions/month)
  • Free/Hobby tiers
  • Single region
  • Manual monitoring

Phase 2: Growth (100-1000 submissions/month)
  • Upgrade to paid tiers
  • Add monitoring tools
  • Implement caching
  • Optimize database queries

Phase 3: Scale (1000+ submissions/month)
  • Multi-region deployment
  • Load balancing
  • Redis caching
  • CDN for static assets
  • Dedicated n8n workers
  • Database read replicas
```

---

## 📈 Monitoring Architecture

### Metrics to Track

```
Application Metrics:
  • Request rate (req/min)
  • Response time (ms)
  • Error rate (%)
  • Success rate (%)

Workflow Metrics:
  • Execution time (seconds)
  • Success rate (%)
  • Retry count
  • Agent performance

Database Metrics:
  • Query time (ms)
  • Connection count
  • Storage usage (GB)
  • Cache hit rate (%)

AI API Metrics:
  • Token usage
  • Cost per submission
  • Rate limit status
  • Error rate
```

### Monitoring Tools

- **Vercel Analytics**: Application performance
- **n8n Execution Logs**: Workflow monitoring
- **Neon Metrics**: Database performance
- **Custom Queries**: Business metrics

---

## 🎯 Future Architecture Enhancements

### Planned Improvements

1. **Authentication & Authorization**
   - User accounts
   - Role-based access control
   - API key management

2. **Real-time Updates**
   - WebSocket connections
   - Live progress tracking
   - Push notifications

3. **Advanced Analytics**
   - Usage dashboards
   - Cost tracking
   - Performance insights

4. **Multi-tenancy**
   - Organization support
   - Team collaboration
   - Shared workspaces

5. **API Layer**
   - RESTful API
   - GraphQL (optional)
   - Webhook subscriptions

---

## 📚 Technology Stack Summary

| Layer | Technology | Purpose |
|-------|-----------|---------|
| **Frontend** | Next.js 14, React 18, TypeScript | UI & Client Logic |
| **Styling** | Tailwind CSS, Shadcn UI | Design System |
| **Backend** | Next.js API Routes, Node.js 20 | Server Logic |
| **Database** | Neon Postgres 15 | Data Persistence |
| **ORM** | Drizzle ORM | Database Access |
| **Validation** | Zod | Schema Validation |
| **Workflow** | n8n | Orchestration |
| **AI** | OpenAI GPT-4, Claude 3.5 | Content Generation |
| **Search** | Tavily API | Web Search |
| **Hosting** | Vercel | Application Hosting |
| **Monitoring** | Vercel Analytics, n8n Logs | Performance Tracking |

---

**Version**: 1.0.0  
**Last Updated**: October 20, 2025  
**Maintained by**: LBF Technoglow Team
