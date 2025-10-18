# Environment Setup Guide

Complete guide for configuring LBF Technoglow Simulator in local and production environments.

## Required Environment Variables

### Database Configuration

#### `DATABASE_URL`
**Required**: Yes  
**Format**: PostgreSQL connection string  
**Example**: `postgresql://user:password@host.neon.tech/dbname?sslmode=require`

**Setup Steps:**
1. Create a Neon Postgres database at [neon.tech](https://neon.tech)
2. Navigate to your project dashboard
3. Copy the connection string from "Connection Details"
4. Ensure `?sslmode=require` is appended
5. Add to `.env` file

### n8n Webhook Configuration

#### `N8N_TEST_WEBHOOK`
**Required**: Yes  
**Format**: HTTPS URL  
**Example**: `https://n8n-gczfssttvtzs.nasgor.sumopod.my.id/webhook-test/lbf_skincare`

**Setup Steps:**
1. Create a webhook node in your n8n test workflow
2. Set path to `/webhook-test/lbf_skincare`
3. Configure to accept POST requests
4. Copy the full webhook URL
5. Add to `.env` file

#### `N8N_PRODUCTION_WEBHOOK`
**Required**: Yes  
**Format**: HTTPS URL  
**Example**: `https://n8n-gczfssttvtzs.nasgor.sumopod.my.id/webhook/lbf_skincare`

**Setup Steps:**
1. Create a webhook node in your n8n production workflow
2. Set path to `/webhook/lbf_skincare`
3. Configure to accept POST requests
4. Enable authentication if needed
5. Copy the full webhook URL
6. Add to `.env` file

#### `N8N_WEBHOOK_SECRET` (Optional)
**Required**: No  
**Format**: String  
**Purpose**: HMAC signature verification for webhook security

### Application Configuration

#### `NEXT_PUBLIC_APP_VERSION`
**Required**: No  
**Default**: `1.0.0`  
**Purpose**: Tracks application version in submissions

#### `NEXT_PUBLIC_FORM_VERSION`
**Required**: No  
**Default**: `1.0.0`  
**Purpose**: Tracks form schema version for compatibility

#### `NEXT_PUBLIC_DEFAULT_LANGUAGE`
**Required**: No  
**Default**: `id`  
**Options**: `id` (Indonesian), `en` (English)

### Google Sheets Integration (Managed via n8n)

These credentials are configured in n8n, not in the Next.js app:

- `GOOGLE_SERVICE_ACCOUNT_EMAIL`
- `GOOGLE_PRIVATE_KEY`

**Setup in n8n:**
1. Create Google Cloud project
2. Enable Google Sheets API
3. Create service account
4. Download JSON credentials
5. Configure in n8n Google Sheets node
6. Share target spreadsheet with service account email

### Analytics (Optional)

#### `ANALYTICS_ENDPOINT`
**Required**: No  
**Format**: HTTPS URL  
**Purpose**: External analytics service endpoint

## Local Development Setup

### Step 1: Install Dependencies

```bash
pnpm install
```

### Step 2: Configure Environment

```bash
cp .env.example .env
```

Edit `.env` with your credentials.

### Step 3: Database Setup

```bash
# Generate migration files
pnpm db:generate

# Apply migrations to Neon
pnpm db:migrate

# (Optional) Open Drizzle Studio
pnpm db:studio
```

### Step 4: Verify Configuration

```bash
# Type check
pnpm type-check

# Lint
pnpm lint

# Run tests
pnpm test
```

### Step 5: Start Development Server

```bash
pnpm dev
```

Access at `http://localhost:3000`

## Production Deployment

### Vercel (Recommended)

1. **Connect Repository**
   - Import project in Vercel dashboard
   - Select Next.js framework preset

2. **Configure Environment Variables**
   - Add all required variables in Vercel project settings
   - Use production values for webhooks and database

3. **Deploy**
   ```bash
   vercel --prod
   ```

4. **Post-Deployment**
   - Verify database connectivity
   - Test webhook endpoints
   - Monitor logs for errors

### Manual Deployment

1. **Build Application**
   ```bash
   pnpm build
   ```

2. **Set Environment Variables**
   ```bash
   export DATABASE_URL="..."
   export N8N_PRODUCTION_WEBHOOK="..."
   # ... other variables
   ```

3. **Run Migrations**
   ```bash
   pnpm db:migrate
   ```

4. **Start Server**
   ```bash
   pnpm start
   ```

## Neon Database Configuration

### Connection Pooling

For production, enable connection pooling:

```
DATABASE_URL=postgresql://user:password@host.neon.tech/dbname?sslmode=require&pgbouncer=true
```

### Compute Settings

Recommended Neon compute tier:
- **Development**: Shared compute (free tier)
- **Production**: Dedicated compute with autoscaling

### Backup Strategy

Neon provides automatic backups. Configure retention:
1. Navigate to project settings
2. Set backup retention period (7-30 days)
3. Enable point-in-time recovery

## n8n Workflow Configuration

### Required Nodes

1. **Webhook Trigger**
   - Path: `/webhook/lbf_skincare` or `/webhook-test/lbf_skincare`
   - Method: POST
   - Authentication: Optional (use `N8N_WEBHOOK_SECRET`)

2. **Data Processing**
   - Parse JSON payload
   - Validate schema
   - Extract key fields

3. **AI Agent Calls**
   - OpenAI/Anthropic nodes for content generation
   - Custom function nodes for business logic

4. **Database Write**
   - HTTP Request node to `/api/sync`
   - Include `submissionId` and `reportSections`

5. **Google Sheets Sync**
   - Google Sheets node
   - Append row with submission data
   - Update status column

### Webhook Payload Example

```json
{
  "submissionId": "uuid-v4",
  "submittedAt": "2024-01-01T00:00:00Z",
  "targetEnvironment": "production",
  "brand": { "name": "...", "voice": "...", "values": "..." },
  "productBlueprint": { ... },
  "concept": { ... },
  "ingredients": [ ... ],
  "systemMetadata": { ... }
}
```

### Callback to Next.js

After processing, n8n should POST to `/api/sync`:

```json
{
  "submissionId": "uuid-v4",
  "status": "completed",
  "reportSections": [
    {
      "type": "productDescription",
      "data": { "description": "..." },
      "order": 1
    }
  ]
}
```

## Troubleshooting

### Database Connection Issues

**Error**: `Connection refused`  
**Solution**: Verify `DATABASE_URL` format and Neon project status

**Error**: `SSL required`  
**Solution**: Ensure `?sslmode=require` is in connection string

### Webhook Failures

**Error**: `Webhook timeout`  
**Solution**: Increase timeout in n8n workflow settings (default 30s to 120s)

**Error**: `Invalid payload`  
**Solution**: Check Zod schema validation in `/api/submit`

### Migration Errors

**Error**: `Migration already applied`  
**Solution**: Check `drizzle` table in database for applied migrations

**Error**: `Permission denied`  
**Solution**: Verify database user has CREATE/ALTER permissions

## Security Checklist

- [ ] All environment variables stored securely (not in git)
- [ ] Production database uses strong password
- [ ] n8n webhooks use HTTPS
- [ ] Webhook secret configured for signature verification
- [ ] Google service account has minimal permissions
- [ ] CORS configured for API routes
- [ ] Rate limiting enabled (if using Vercel)

## Monitoring

### Recommended Tools

- **Application**: Vercel Analytics
- **Database**: Neon metrics dashboard
- **Workflows**: n8n execution logs
- **Errors**: Sentry (optional)

### Key Metrics

- Submission success rate
- Average processing time
- Database query performance
- Webhook response times
- Error rates by endpoint

## Support

For setup assistance:
- Email: devops@lbftechnoglow.com
- Documentation: [System Architecture](./system_architecture.md)

