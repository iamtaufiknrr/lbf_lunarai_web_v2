# Security Best Practices - LBF Technoglow Simulator

## Overview
Panduan keamanan lengkap untuk deployment dan maintenance sistem LBF Technoglow Simulator.

---

## 1. AUTHENTICATION & AUTHORIZATION

### Webhook Security

#### Signature Verification
```javascript
// Implement HMAC-SHA256 signature verification
const crypto = require('crypto');

function verifyWebhookSignature(payload, signature, secret) {
  const hmac = crypto.createHmac('sha256', secret);
  hmac.update(JSON.stringify(payload));
  const expectedSignature = hmac.digest('hex');
  
  return crypto.timingSafeEqual(
    Buffer.from(signature),
    Buffer.from(expectedSignature)
  );
}

// Usage in n8n
const isValid = verifyWebhookSignature(
  $json.body,
  $json.headers['x-webhook-secret'],
  $env.N8N_WEBHOOK_SECRET
);

if (!isValid) {
  throw new Error('Invalid webhook signature');
}
```

#### API Key Management
```env
# Use strong, unique secrets (minimum 32 characters)
N8N_WEBHOOK_SECRET="$(openssl rand -hex 32)"

# Rotate keys every 90 days
# Keep old key for 7 days during transition
N8N_WEBHOOK_SECRET_OLD="previous-key"
```

### Database Access Control

#### User Roles
```sql
-- Create read-only user for reporting
CREATE USER readonly_user WITH PASSWORD 'strong-password-here';
GRANT CONNECT ON DATABASE lbf_techno TO readonly_user;
GRANT USAGE ON SCHEMA public TO readonly_user;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO readonly_user;

-- Create application user with limited permissions
CREATE USER app_user WITH PASSWORD 'strong-password-here';
GRANT CONNECT ON DATABASE lbf_techno TO app_user;
GRANT USAGE ON SCHEMA public TO app_user;
GRANT SELECT, INSERT, UPDATE ON ALL TABLES IN SCHEMA public TO app_user;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO app_user;

-- Revoke DELETE permission
REVOKE DELETE ON ALL TABLES IN SCHEMA public FROM app_user;
```

#### Row-Level Security (RLS)
```sql
-- Enable RLS on sensitive tables
ALTER TABLE submissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE submission_payloads ENABLE ROW LEVEL SECURITY;

-- Create policy for environment isolation
CREATE POLICY environment_isolation ON submissions
FOR ALL
USING (
  target_environment = current_setting('app.environment', true)
  OR current_user = 'admin_user'
);

-- Set environment in connection
SET app.environment = 'production';
```

---

## 2. DATA PROTECTION

### Encryption at Rest

#### Database Encryption
```sql
-- Enable transparent data encryption (TDE)
-- Neon Postgres has this enabled by default

-- Encrypt sensitive JSONB fields
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Function to encrypt data
CREATE OR REPLACE FUNCTION encrypt_sensitive_data(data TEXT)
RETURNS TEXT AS $$
BEGIN
  RETURN encode(
    pgp_sym_encrypt(data, current_setting('app.encryption_key')),
    'base64'
  );
END;
$$ LANGUAGE plpgsql;

-- Function to decrypt data
CREATE OR REPLACE FUNCTION decrypt_sensitive_data(encrypted_data TEXT)
RETURNS TEXT AS $$
BEGIN
  RETURN pgp_sym_decrypt(
    decode(encrypted_data, 'base64'),
    current_setting('app.encryption_key')
  );
END;
$$ LANGUAGE plpgsql;
```

### Encryption in Transit

#### SSL/TLS Configuration
```javascript
// Enforce SSL for database connections
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: {
    rejectUnauthorized: true,
    ca: fs.readFileSync('/path/to/ca-certificate.crt').toString()
  }
});

// Enforce HTTPS for webhooks
if (!webhookUrl.startsWith('https://')) {
  throw new Error('Webhook URL must use HTTPS');
}
```

### Data Masking

#### PII Protection
```javascript
// Mask sensitive data in logs
function maskPII(data) {
  return {
    ...data,
    email: data.email?.replace(/(.{2})(.*)(@.*)/, '$1***$3'),
    phone: data.phone?.replace(/(\d{3})(\d{4})(\d{4})/, '$1****$3'),
    ipAddress: data.ipAddress?.replace(/(\d+\.\d+)\.\d+\.\d+/, '$1.xxx.xxx')
  };
}

// Use in logging
console.log('Submission received:', maskPII(submissionData));
```

---

## 3. INPUT VALIDATION

### Schema Validation

#### Zod Schema
```typescript
import { z } from 'zod';

// Strict validation schema
const SubmissionSchema = z.object({
  submissionId: z.string().uuid(),
  submittedAt: z.string().datetime(),
  targetEnvironment: z.enum(['test', 'production']),
  brand: z.object({
    name: z.string().min(1).max(255).regex(/^[a-zA-Z0-9\s-]+$/),
    voice: z.string().min(1).max(500),
    values: z.string().min(1).max(500)
  }),
  // ... more fields
}).strict(); // Reject unknown fields

// Validate input
try {
  const validated = SubmissionSchema.parse(input);
} catch (error) {
  // Handle validation error
  return { error: 'Invalid input', details: error.errors };
}
```

### SQL Injection Prevention

#### Parameterized Queries
```javascript
// ❌ NEVER do this
const query = `SELECT * FROM submissions WHERE id = '${submissionId}'`;

// ✅ ALWAYS use parameterized queries
const query = 'SELECT * FROM submissions WHERE id = $1';
const result = await pool.query(query, [submissionId]);

// ✅ Using Drizzle ORM (automatically parameterized)
const result = await db
  .select()
  .from(submissions)
  .where(eq(submissions.id, submissionId));
```

### XSS Prevention

#### Output Escaping
```typescript
// React automatically escapes output
function BrandName({ name }: { name: string }) {
  // This is safe - React escapes HTML
  return <h1>{name}</h1>;
}

// For dangerouslySetInnerHTML, sanitize first
import DOMPurify from 'dompurify';

function RichContent({ html }: { html: string }) {
  const sanitized = DOMPurify.sanitize(html);
  return <div dangerouslySetInnerHTML={{ __html: sanitized }} />;
}
```

---

## 4. RATE LIMITING

### API Rate Limiting

#### Implementation
```javascript
import rateLimit from 'express-rate-limit';

// Rate limiter for submission endpoint
const submissionLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 10, // 10 requests per window
  message: 'Too many submissions, please try again later',
  standardHeaders: true,
  legacyHeaders: false,
  handler: (req, res) => {
    res.status(429).json({
      error: 'Rate limit exceeded',
      retryAfter: req.rateLimit.resetTime
    });
  }
});

// Apply to route
app.post('/api/submit', submissionLimiter, submitHandler);
```

### AI API Rate Limiting

#### Bottleneck Implementation
```javascript
const Bottleneck = require('bottleneck');

// OpenAI rate limiter
const openaiLimiter = new Bottleneck({
  maxConcurrent: 5,
  minTime: 200, // 200ms between requests
  reservoir: 60, // 60 requests
  reservoirRefreshAmount: 60,
  reservoirRefreshInterval: 60 * 1000 // per minute
});

// Wrap API calls
const rateLimitedOpenAI = openaiLimiter.wrap(async (prompt) => {
  return await openai.chat.completions.create({
    model: 'gpt-4-turbo-preview',
    messages: [{ role: 'user', content: prompt }]
  });
});
```

---

## 5. SECRETS MANAGEMENT

### Environment Variables

#### Best Practices
```bash
# ❌ NEVER commit secrets to git
# Add to .gitignore
echo ".env" >> .gitignore
echo ".env.local" >> .gitignore

# ✅ Use environment variables
export DATABASE_URL="postgresql://..."
export OPENAI_API_KEY="sk-..."

# ✅ Use secret management service
# AWS Secrets Manager
aws secretsmanager get-secret-value --secret-id lbf-techno/prod

# HashiCorp Vault
vault kv get secret/lbf-techno/prod
```

### Key Rotation

#### Rotation Schedule
```javascript
// Implement key rotation
const KEY_ROTATION_DAYS = 90;

async function checkKeyAge() {
  const keyCreatedAt = await getKeyCreationDate();
  const daysSinceCreation = (Date.now() - keyCreatedAt) / (1000 * 60 * 60 * 24);
  
  if (daysSinceCreation > KEY_ROTATION_DAYS) {
    await notifyKeyRotationNeeded();
  }
}

// Run daily
cron.schedule('0 0 * * *', checkKeyAge);
```

---

## 6. AUDIT LOGGING

### Comprehensive Logging

#### Implementation
```javascript
// Log all security-relevant events
async function auditLog(event) {
  await db.insert(auditLogs).values({
    submissionId: event.submissionId,
    action: event.action,
    actorType: event.actorType,
    metadata: event.metadata,
    ipAddress: event.ipAddress,
    userAgent: event.userAgent,
    createdAt: new Date()
  });
}

// Usage
await auditLog({
  submissionId: submission.id,
  action: 'submission_created',
  actorType: 'user',
  metadata: { environment: 'production' },
  ipAddress: req.ip,
  userAgent: req.headers['user-agent']
});
```

### Log Monitoring

#### Alert Rules
```sql
-- Detect suspicious activity
SELECT 
    ip_address,
    COUNT(*) as failed_attempts,
    MAX(created_at) as last_attempt
FROM audit_logs
WHERE action = 'authentication_failed'
AND created_at > NOW() - INTERVAL '1 hour'
GROUP BY ip_address
HAVING COUNT(*) > 5;

-- Detect unusual patterns
SELECT 
    actor_type,
    action,
    COUNT(*) as count,
    DATE_TRUNC('hour', created_at) as hour
FROM audit_logs
WHERE created_at > NOW() - INTERVAL '24 hours'
GROUP BY actor_type, action, DATE_TRUNC('hour', created_at)
HAVING COUNT(*) > 100;
```

---

## 7. NETWORK SECURITY

### Firewall Rules

#### Database Access
```bash
# Allow only application servers
# Neon Postgres IP whitelist
neon ip-allow add 203.0.113.0/24 --project-id your-project

# Block all other IPs
neon ip-allow set-default deny --project-id your-project
```

### CORS Configuration

#### Next.js API Routes
```typescript
// pages/api/submit.ts
export default async function handler(req, res) {
  // Set CORS headers
  res.setHeader('Access-Control-Allow-Origin', process.env.ALLOWED_ORIGIN);
  res.setHeader('Access-Control-Allow-Methods', 'POST');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');
  
  if (req.method === 'OPTIONS') {
    res.status(200).end();
    return;
  }
  
  // Handle request
}
```

---

## 8. DEPENDENCY SECURITY

### Vulnerability Scanning

#### Regular Audits
```bash
# Check for vulnerabilities
npm audit

# Fix vulnerabilities
npm audit fix

# Check for outdated packages
npm outdated

# Update dependencies
npm update
```

### Automated Scanning

#### GitHub Dependabot
```yaml
# .github/dependabot.yml
version: 2
updates:
  - package-ecosystem: "npm"
    directory: "/"
    schedule:
      interval: "weekly"
    open-pull-requests-limit: 10
```

---

## 9. INCIDENT RESPONSE

### Security Incident Plan

#### Response Steps
1. **Detect**: Monitor alerts and logs
2. **Contain**: Isolate affected systems
3. **Investigate**: Analyze logs and traces
4. **Remediate**: Fix vulnerabilities
5. **Recover**: Restore normal operations
6. **Review**: Post-mortem analysis

#### Emergency Contacts
```markdown
## Security Team
- Security Lead: [Name] - [Phone] - [Email]
- DevOps Lead: [Name] - [Phone] - [Email]
- Legal: [Name] - [Phone] - [Email]

## Escalation Path
1. On-call engineer
2. Security lead
3. CTO
4. CEO
```

---

## 10. COMPLIANCE

### GDPR Compliance

#### Data Subject Rights
```javascript
// Right to access
async function exportUserData(userId) {
  const data = await db
    .select()
    .from(submissions)
    .where(eq(submissions.userId, userId));
  
  return JSON.stringify(data, null, 2);
}

// Right to erasure
async function deleteUserData(userId) {
  await db
    .delete(submissions)
    .where(eq(submissions.userId, userId));
  
  await auditLog({
    action: 'user_data_deleted',
    actorType: 'system',
    metadata: { userId }
  });
}
```

### Data Retention

#### Retention Policy
```sql
-- Archive old data
CREATE OR REPLACE FUNCTION archive_old_submissions()
RETURNS void AS $$
BEGIN
  -- Move to archive table
  INSERT INTO submissions_archive
  SELECT * FROM submissions
  WHERE created_at < NOW() - INTERVAL '2 years';
  
  -- Delete from main table
  DELETE FROM submissions
  WHERE created_at < NOW() - INTERVAL '2 years';
END;
$$ LANGUAGE plpgsql;

-- Schedule monthly
SELECT cron.schedule('archive-submissions', '0 0 1 * *', 'SELECT archive_old_submissions()');
```

---

## SECURITY CHECKLIST

### Pre-Deployment
- [ ] All secrets in environment variables
- [ ] SSL/TLS enabled for all connections
- [ ] Input validation implemented
- [ ] SQL injection prevention verified
- [ ] XSS protection enabled
- [ ] CSRF protection enabled
- [ ] Rate limiting configured
- [ ] Audit logging enabled
- [ ] Error messages don't leak sensitive info
- [ ] Security headers configured

### Post-Deployment
- [ ] Vulnerability scan completed
- [ ] Penetration testing done
- [ ] Security audit passed
- [ ] Incident response plan documented
- [ ] Team trained on security procedures
- [ ] Monitoring and alerting active
- [ ] Backup and recovery tested
- [ ] Compliance requirements met

---

## SECURITY MONITORING

### Key Metrics
- Failed authentication attempts
- Unusual API usage patterns
- Database query anomalies
- Error rate spikes
- Slow query alerts
- Unauthorized access attempts

### Alerting Rules
```javascript
// Alert on suspicious activity
if (failedAttempts > 5) {
  await sendAlert({
    severity: 'high',
    message: `Multiple failed auth attempts from ${ipAddress}`,
    action: 'Block IP and investigate'
  });
}

// Alert on data breach indicators
if (unusualDataAccess) {
  await sendAlert({
    severity: 'critical',
    message: 'Potential data breach detected',
    action: 'Immediate investigation required'
  });
}
```

---

## CONCLUSION

Keamanan adalah proses berkelanjutan, bukan tujuan akhir. Lakukan review security secara berkala, update dependencies, rotate keys, dan monitor logs untuk menjaga sistem tetap aman.

**Key Takeaways**:
- ✅ Always validate input
- ✅ Use parameterized queries
- ✅ Encrypt sensitive data
- ✅ Implement rate limiting
- ✅ Enable audit logging
- ✅ Regular security audits
- ✅ Incident response plan
- ✅ Compliance requirements
