# System Architecture - LBF Technoglow Simulator

## Overview
LBF Technoglow Simulator adalah sistem AI Agentic yang menggunakan multiple specialized agents untuk menghasilkan comprehensive product development reports untuk industri kecantikan.

---

## High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         USER INTERFACE                           │
│                    (Next.js 14 Application)                      │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             │ HTTP POST
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                      API LAYER (/api/submit)                     │
│  - Validation (Zod)                                             │
│  - Database Insert                                              │
│  - Webhook Dispatch                                             │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             │ Webhook
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                    N8N WORKFLOW ORCHESTRATOR                     │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │              Main Processor Workflow                      │  │
│  │  1. Webhook Receiver                                     │  │
│  │  2. Signature Validation                                 │  │
│  │  3. Environment Check                                    │  │
│  │  4. Database Status Update                               │  │
│  │  5. Orchestrator Agent (Task Distribution)               │  │
│  └──────────────────────────────────────────────────────────┘  │
│                             │                                    │
│         ┌───────────────────┼───────────────────┐               │
│         │                   │                   │               │
│         ▼                   ▼                   ▼               │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐        │
│  │ Formulation │    │   Market    │    │ Copywriting │        │
│  │   Agent     │    │  Research   │    │    Agent    │        │
│  │  (GPT-4)    │    │   Agent     │    │  (Claude)   │        │
│  │             │    │  (GPT-4 +   │    │             │        │
│  │ - Formula   │    │   Tavily)   │    │ - Names     │        │
│  │ - INCI      │    │             │    │ - Copy      │        │
│  │ - Stability │    │ - Market    │    │ - Taglines  │        │
│  │ - Refs      │    │ - Competitors│   │ - SEO       │        │
│  └─────────────┘    └─────────────┘    └─────────────┘        │
│         │                   │                   │               │
│         └───────────────────┼───────────────────┘               │
│                             │                                    │
│                             ▼                                    │
│                    ┌─────────────────┐                          │
│                    │  Compliance     │                          │
│                    │    Agent        │                          │
│                    │  (GPT-4 +       │                          │
│                    │   Web Search)   │                          │
│                    │                 │                          │
│                    │ - BPOM          │                          │
│                    │ - Halal         │                          │
│                    │ - Regulations   │                          │
│                    └─────────────────┘                          │
│                             │                                    │
│                             ▼                                    │
│                    ┌─────────────────┐                          │
│                    │     Final       │                          │
│                    │  Aggregation    │                          │
│                    │                 │                          │
│                    │ - Collect All   │                          │
│                    │ - Build Report  │                          │
│                    │ - Callback      │                          │
│                    └─────────────────┘                          │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             │ HTTP PATCH /api/sync
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                    CALLBACK HANDLER (/api/sync)                  │
│  - Receive Report Sections                                      │
│  - Update Database                                              │
│  - Trigger UI Update                                            │
└─────────────────────────────────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                      DATABASE (Neon Postgres)                    │
│                                                                  │
│  ┌──────────────┐  ┌──────────────────┐  ┌─────────────────┐  │
│  │ submissions  │  │ submission_      │  │ workflow_runs   │  │
│  │              │  │ payloads         │  │                 │  │
│  │ - id         │  │                  │  │ - status        │  │
│  │ - status     │  │ - payload (JSONB)│  │ - retry_count   │  │
│  │ - brand_name │  │                  │  │ - errors        │  │
│  └──────────────┘  └──────────────────┘  └─────────────────┘  │
│                                                                  │
│  ┌──────────────────┐  ┌──────────────────────────────────┐   │
│  │ report_sections  │  │ audit_logs                       │   │
│  │                  │  │                                  │   │
│  │ - section_type   │  │ - action                         │   │
│  │ - section_data   │  │ - actor_type                     │   │
│  │ - order          │  │ - metadata                       │   │
│  └──────────────────┘  └──────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

---

## Component Details

### 1. Frontend Layer (Next.js 14)

**Technology Stack**:
- Next.js 14 (App Router)
- React 18
- TypeScript
- Tailwind CSS
- Shadcn UI
- Framer Motion

**Key Features**:
- Server-side rendering
- Form validation (React Hook Form + Zod)
- Real-time status updates
- Responsive design
- Accessibility compliant

**Pages**:
- `/` - Simulator form & landing
- `/result/[id]` - Report viewer
- `/api/submit` - Submission endpoint
- `/api/sync` - Callback endpoint
- `/api/result/[id]` - Report data endpoint

---

### 2. API Layer

#### POST /api/submit
**Purpose**: Receive form submission and initiate workflow

**Flow**:
1. Validate payload with Zod schema
2. Insert into `submissions` table
3. Insert payload into `submission_payloads` table
4. Dispatch webhook to n8n
5. Create `workflow_runs` entry
6. Return submission ID

**Error Handling**:
- Validation errors → 400
- Database errors → 500
- Webhook errors → Retry logic

#### PATCH /api/sync
**Purpose**: Receive completed report from n8n

**Flow**:
1. Verify webhook signature
2. Update `submissions` status
3. Insert/update `report_sections`
4. Update `workflow_runs`
5. Log to `audit_logs`
6. Return success

#### GET /api/result/[id]
**Purpose**: Fetch submission and report data

**Flow**:
1. Query `submissions` by ID
2. Join with `report_sections`
3. Join with `workflow_runs`
4. Format and return data

---

### 3. n8n Workflow Layer

#### Main Processor Workflow
**Trigger**: Webhook POST
**Purpose**: Orchestrate all agents

**Nodes**:
1. **Webhook Receiver**: Accept POST request
2. **Validate & Extract**: Verify signature, extract data
3. **Update Status**: Set submission status to 'running'
4. **Create Workflow Run**: Log workflow start
5. **Orchestrator Agent**: Distribute tasks to specialized agents

**Error Handling**:
- Invalid signature → 401
- Missing data → 400
- Database error → Retry
- Agent failure → Error handler workflow

#### Specialized Agent Workflows

**Formulation Agent**:
- **AI Model**: GPT-4 Turbo
- **Input**: Product blueprint, ingredients
- **Output**: Complete formulation, INCI names, stability analysis
- **MCP Tools**: Database (save), Web Search (scientific refs)
- **Processing Time**: ~30-60 seconds

**Market Research Agent**:
- **AI Model**: GPT-4 Turbo
- **Input**: Brand profile, location
- **Output**: Market analysis, competitor insights
- **MCP Tools**: Tavily Search (market data, competitors)
- **Processing Time**: ~45-90 seconds

**Copywriting Agent**:
- **AI Model**: Claude 3.5 Sonnet
- **Input**: Brand, concept, formula
- **Output**: Product names, taglines, marketing copy
- **MCP Tools**: Database (save)
- **Processing Time**: ~30-60 seconds

**Compliance Agent**:
- **AI Model**: GPT-4 Turbo
- **Input**: Regulatory priorities, location
- **Output**: Compliance requirements, certifications
- **MCP Tools**: Web Search (regulatory updates)
- **Processing Time**: ~30-45 seconds

**Final Aggregation**:
- **Purpose**: Collect all sections and callback
- **Input**: All agent outputs
- **Output**: Complete report
- **Actions**: Update database, callback to app
- **Processing Time**: ~10-15 seconds

---

### 4. Database Layer (Neon Postgres)

#### Schema Design

**submissions**:
- Primary table for submission metadata
- Indexed on: status, brand_name, created_at
- Triggers: auto-update updated_at

**submission_payloads**:
- Stores complete form data as JSONB
- GIN index on payload for fast queries
- Cascade delete with submissions

**workflow_runs**:
- Tracks n8n execution status
- Stores retry count and errors
- Indexed on: submission_id, status

**report_sections**:
- Stores individual report sections
- JSONB data for flexibility
- Ordered by "order" field
- Indexed on: submission_id, section_type

**audit_logs**:
- Complete audit trail
- Tracks all system actions
- Indexed on: submission_id, action, created_at

#### Performance Optimizations

**Indexes**:
- B-tree indexes on foreign keys
- GIN indexes on JSONB columns
- Composite indexes for common queries
- Partial indexes for active workflows

**Materialized Views**:
- `submission_stats`: Daily statistics
- `workflow_performance`: Performance metrics
- Refreshed periodically

**Connection Pooling**:
- Max connections: 100
- Idle timeout: 30s
- Connection timeout: 2s

---

### 5. MCP (Model Context Protocol) Layer

#### Database MCP
**Purpose**: Direct database access for AI agents

**Capabilities**:
- Execute SQL queries
- List tables and schemas
- Insert/update/delete operations
- Transaction support

**Security**:
- Read-only mode for queries
- Parameterized queries only
- Query timeout limits
- Audit logging

#### Web Search MCP (Tavily)
**Purpose**: Real-time web search for market research

**Capabilities**:
- Advanced search with filters
- Domain-specific search
- Relevance scoring
- Source credibility

**Configuration**:
- Max results: 5-10 per query
- Search depth: Advanced
- Domain whitelist: Industry sites
- Rate limit: 100 req/min

#### Filesystem MCP
**Purpose**: Read reference documents

**Capabilities**:
- Read files (PDF, DOCX, TXT)
- List directories
- File metadata
- Content extraction

**Security**:
- Restricted to specific directories
- Read-only access
- File type validation
- Size limits

---

## Data Flow

### Submission Flow
```
User Form → Validation → Database Insert → Webhook Dispatch → n8n
```

### Processing Flow
```
n8n Orchestrator → Parallel Agent Execution → Database Updates → Aggregation
```

### Callback Flow
```
n8n Final Aggregation → HTTP PATCH /api/sync → Database Update → UI Refresh
```

### Report Retrieval Flow
```
User Request → API Query → Database Join → Format Response → Display
```

---

## Security Architecture

### Authentication & Authorization
- Webhook signature verification (HMAC-SHA256)
- API key authentication for external services
- Environment-based access control
- Row-level security (RLS) on database

### Data Protection
- SSL/TLS for all connections
- Encrypted secrets in environment variables
- JSONB for sensitive data
- Audit logging for all operations

### Input Validation
- Zod schema validation
- SQL injection prevention (parameterized queries)
- XSS protection (React escaping)
- CSRF protection

### Rate Limiting
- API rate limits per endpoint
- AI API rate limits per provider
- Database connection limits
- Webhook rate limits

---

## Scalability Considerations

### Horizontal Scaling
- **n8n**: Queue mode with multiple workers
- **Application**: Multiple Next.js instances
- **Database**: Read replicas for queries

### Vertical Scaling
- **Database**: Increase connection pool
- **n8n**: Increase worker memory
- **Application**: Increase server resources

### Caching Strategy
- **Redis**: Cache frequent queries
- **CDN**: Static assets
- **Application**: React Query for client-side
- **Database**: Materialized views

### Load Balancing
- **Application**: Nginx/Vercel
- **n8n**: Redis queue distribution
- **Database**: PgBouncer connection pooling

---

## Monitoring & Observability

### Application Monitoring
- Error tracking (Sentry)
- Performance monitoring (Vercel Analytics)
- User analytics
- API response times

### Database Monitoring
- Query performance (pg_stat_statements)
- Connection pool usage
- Table sizes and bloat
- Index usage statistics

### n8n Monitoring
- Workflow execution times
- Error rates
- Retry counts
- Queue depth

### Alerting
- Error rate threshold
- Response time threshold
- Database connection issues
- Workflow failures

---

## Disaster Recovery

### Backup Strategy
- **Database**: Daily automated backups
- **n8n Workflows**: Version controlled in git
- **Application**: Deployed via git
- **Retention**: 30 days

### Recovery Procedures
- **Database**: Point-in-time recovery
- **Application**: Rollback deployment
- **n8n**: Re-import workflows
- **RTO**: < 1 hour
- **RPO**: < 24 hours

---

## Technology Stack Summary

| Layer | Technology | Purpose |
|-------|-----------|---------|
| Frontend | Next.js 14, React 18, TypeScript | User interface |
| Styling | Tailwind CSS, Shadcn UI | Design system |
| Validation | Zod, React Hook Form | Form validation |
| Database | Neon Postgres 15 | Data persistence |
| ORM | Drizzle ORM | Database queries |
| Workflow | n8n | Orchestration |
| AI | GPT-4, Claude 3.5 | Content generation |
| Search | Tavily API | Web search |
| MCP | Model Context Protocol | Tool integration |
| Monitoring | Sentry, Vercel Analytics | Observability |
| Deployment | Vercel, Docker | Hosting |

---

## Performance Benchmarks

### Target Metrics
- **API Response Time**: < 200ms (p95)
- **Workflow Processing**: < 5 minutes (complete)
- **Database Queries**: < 50ms (p95)
- **Uptime**: 99.9%
- **Error Rate**: < 1%

### Current Performance
- **Form Submission**: ~150ms
- **Formulation Agent**: ~45s
- **Market Research**: ~60s
- **Copywriting**: ~40s
- **Compliance**: ~35s
- **Total Processing**: ~3-4 minutes

---

## Future Enhancements

### Short Term
- Implement caching layer (Redis)
- Add more specialized agents
- Optimize AI prompts
- Improve error recovery

### Medium Term
- Real-time progress updates (WebSockets)
- Batch processing support
- Advanced analytics dashboard
- Multi-language support

### Long Term
- Custom AI model fine-tuning
- Predictive analytics
- Integration with ERP systems
- Mobile application

---

## Conclusion

LBF Technoglow Simulator menggunakan arsitektur modern yang scalable, secure, dan maintainable. Dengan kombinasi Next.js, n8n, dan AI agents, sistem ini mampu menghasilkan comprehensive product development reports secara otomatis dan efisien.
