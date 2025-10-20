# Testing Guide - LBF Technoglow Simulator

## Overview
Panduan lengkap untuk testing sistem n8n workflow dan database integration.

> **Catatan:** Seluruh perintah pada panduan ini diasumsikan dijalankan dari root repository. File payload contoh sekarang berada di `data/n8n/test-payload.json`.

---

## 1. PRE-TESTING CHECKLIST

### Database Setup
- [ ] Database schema telah dijalankan
- [ ] Semua tabel telah dibuat
- [ ] Indexes telah dibuat
- [ ] Triggers berfungsi dengan baik
- [ ] Connection string sudah benar

### n8n Setup
- [ ] Semua workflows telah diimport
- [ ] Credentials telah dikonfigurasi
- [ ] Webhook URLs sudah benar
- [ ] Environment variables sudah diset
- [ ] Workflows dalam status active

### API Keys
- [ ] OpenAI API key valid
- [ ] Anthropic API key valid
- [ ] Tavily API key valid
- [ ] Webhook secret sudah diset

---

## 2. UNIT TESTING

### Test Database Connection
```bash
# Test connection
psql "$DATABASE_URL" -c "SELECT 1;"

# Test tables exist
psql "$DATABASE_URL" -c "\dt"

# Test sample insert
psql "$DATABASE_URL" -c "
INSERT INTO submissions (brand_name, target_environment, status) 
VALUES ('Test Brand', 'test', 'queued') 
RETURNING id;
"
```

### Test Webhook Endpoint
```bash
# Test webhook is accessible
curl -X POST https://your-n8n-instance.app/webhook-test/lbf-simulator \
  -H "Content-Type: application/json" \
  -H "X-Webhook-Secret: your-secret" \
  -d '{"test": true}'

# Expected response
{
  "success": true,
  "message": "Webhook received"
}
```

### Test Individual Agents

#### Test Formulation Agent
```bash
curl -X POST http://localhost:5678/webhook-test/formulation-agent \
  -H "Content-Type: application/json" \
  -d '{
    "submissionId": "test-uuid-123",
    "inputData": {
      "functions": ["Moisturizing", "Anti-Aging"],
      "formType": "Serum",
      "gender": "All",
      "ageRanges": ["25-34"],
      "texturePreference": "Lightweight serum",
      "sustainabilityPriority": 80,
      "requiresClinicalStudy": true,
      "needsHalalCertification": true
    },
    "payload": {
      "ingredients": [
        {
          "name": "Niacinamide",
          "inciName": "Niacinamide",
          "percentage": 5,
          "purpose": "Brightening"
        }
      ]
    }
  }'
```

#### Test Market Research Agent
```bash
curl -X POST http://localhost:5678/webhook-test/market-research-agent \
  -H "Content-Type: application/json" \
  -d '{
    "submissionId": "test-uuid-123",
    "inputData": {
      "brand": {
        "name": "Glow Naturals",
        "voice": "Empowering, Natural",
        "values": "Sustainability"
      },
      "location": {
        "country": "Indonesia",
        "region": "DKI Jakarta",
        "city": "Jakarta Selatan"
      }
    }
  }'
```

#### Test Copywriting Agent
```bash
curl -X POST http://localhost:5678/webhook-test/copywriting-agent \
  -H "Content-Type: application/json" \
  -d '{
    "submissionId": "test-uuid-123",
    "inputData": {
      "brand": {
        "name": "Glow Naturals",
        "voice": "Empowering, Natural",
        "values": "Sustainability"
      },
      "concept": {
        "formulaNarrative": "Anti-aging serum with Indonesian botanicals",
        "benchmark": "The Ordinary Buffet"
      }
    }
  }'
```

---

## 3. INTEGRATION TESTING

### Test Complete Flow
```bash
# Send complete test payload
curl -X POST https://your-n8n-instance.app/webhook-test/lbf-simulator \
  -H "Content-Type: application/json" \
  -H "X-Webhook-Secret: your-secret" \
  -d @data/n8n/test-payload.json

# Expected response
{
  "success": true,
  "submissionId": "550e8400-e29b-41d4-a716-446655440000",
  "message": "Submission received and processing started",
  "workflowId": "workflow-run-id"
}
```

### Monitor Workflow Execution
```sql
-- Check submission status
SELECT id, brand_name, status, submitted_at, updated_at
FROM submissions
WHERE id = '550e8400-e29b-41d4-a716-446655440000';

-- Check workflow run
SELECT status, retry_count, started_at, completed_at, last_error
FROM workflow_runs
WHERE submission_id = '550e8400-e29b-41d4-a716-446655440000'
ORDER BY created_at DESC
LIMIT 1;

-- Check report sections
SELECT section_type, "order", created_at
FROM report_sections
WHERE submission_id = '550e8400-e29b-41d4-a716-446655440000'
ORDER BY "order";

-- Check audit logs
SELECT action, actor_type, created_at
FROM audit_logs
WHERE submission_id = '550e8400-e29b-41d4-a716-446655440000'
ORDER BY created_at DESC;
```

---

## 4. PERFORMANCE TESTING

### Load Testing with Apache Bench
```bash
# Test 100 requests with 10 concurrent
ab -n 100 -c 10 \
  -H "Content-Type: application/json" \
  -H "X-Webhook-Secret: your-secret" \
  -p data/n8n/test-payload.json \
  https://your-n8n-instance.app/webhook-test/lbf-simulator
```

### Stress Testing
```bash
# Test with increasing load
for i in {1..10}; do
  echo "Testing with $i concurrent requests..."
  ab -n 50 -c $i \
    -H "Content-Type: application/json" \
    -H "X-Webhook-Secret: your-secret" \
    -p data/n8n/test-payload.json \
    https://your-n8n-instance.app/webhook-test/lbf-simulator
  sleep 5
done
```

### Database Performance
```sql
-- Check query performance
EXPLAIN ANALYZE
SELECT s.*, sp.payload, COUNT(rs.id) as section_count
FROM submissions s
LEFT JOIN submission_payloads sp ON s.id = sp.submission_id
LEFT JOIN report_sections rs ON s.id = rs.submission_id
WHERE s.submitted_at > NOW() - INTERVAL '24 hours'
GROUP BY s.id, sp.id;

-- Check slow queries
SELECT 
    query,
    calls,
    total_exec_time,
    mean_exec_time,
    max_exec_time
FROM pg_stat_statements
ORDER BY mean_exec_time DESC
LIMIT 10;
```

---

## 5. ERROR TESTING

### Test Invalid Payload
```bash
# Missing required fields
curl -X POST https://your-n8n-instance.app/webhook-test/lbf-simulator \
  -H "Content-Type: application/json" \
  -H "X-Webhook-Secret: your-secret" \
  -d '{
    "submissionId": "test-uuid",
    "brand": {}
  }'

# Expected: Validation error
```

### Test Invalid Webhook Secret
```bash
curl -X POST https://your-n8n-instance.app/webhook-test/lbf-simulator \
  -H "Content-Type: application/json" \
  -H "X-Webhook-Secret: wrong-secret" \
  -d @data/n8n/test-payload.json

# Expected: 401 Unauthorized
```

### Test API Rate Limits
```bash
# Send rapid requests to trigger rate limit
for i in {1..100}; do
  curl -X POST https://your-n8n-instance.app/webhook-test/lbf-simulator \
    -H "Content-Type: application/json" \
    -H "X-Webhook-Secret: your-secret" \
    -d @data/n8n/test-payload.json &
done
wait
```

### Test Database Connection Failure
```sql
-- Simulate connection failure
-- Temporarily change DATABASE_URL to invalid value
-- Then test workflow execution
```

---

## 6. VALIDATION TESTING

### Test Data Integrity
```sql
-- Check for orphaned records
SELECT 'submission_payloads' as table_name, COUNT(*) as orphaned
FROM submission_payloads sp
WHERE NOT EXISTS (SELECT 1 FROM submissions s WHERE s.id = sp.submission_id)
UNION ALL
SELECT 'workflow_runs', COUNT(*)
FROM workflow_runs wr
WHERE NOT EXISTS (SELECT 1 FROM submissions s WHERE s.id = wr.submission_id)
UNION ALL
SELECT 'report_sections', COUNT(*)
FROM report_sections rs
WHERE NOT EXISTS (SELECT 1 FROM submissions s WHERE s.id = rs.submission_id);

-- Check data consistency
SELECT 
    s.id,
    s.status,
    wr.status as workflow_status,
    COUNT(rs.id) as section_count
FROM submissions s
LEFT JOIN workflow_runs wr ON s.id = wr.submission_id
LEFT JOIN report_sections rs ON s.id = rs.submission_id
WHERE s.status = 'completed'
GROUP BY s.id, s.status, wr.status
HAVING COUNT(rs.id) = 0;
```

---

## 7. SECURITY TESTING

### Test SQL Injection
```bash
# Try SQL injection in payload
curl -X POST https://your-n8n-instance.app/webhook-test/lbf-simulator \
  -H "Content-Type: application/json" \
  -H "X-Webhook-Secret: your-secret" \
  -d '{
    "submissionId": "test'; DROP TABLE submissions; --",
    "brand": {"name": "Test"}
  }'

# Should be safely handled by parameterized queries
```

### Test XSS
```bash
# Try XSS in brand name
curl -X POST https://your-n8n-instance.app/webhook-test/lbf-simulator \
  -H "Content-Type: application/json" \
  -H "X-Webhook-Secret: your-secret" \
  -d '{
    "submissionId": "test-uuid",
    "brand": {"name": "<script>alert(\"XSS\")</script>"}
  }'

# Should be escaped properly
```

---

## 8. REGRESSION TESTING

### Test After Updates
```bash
# Run complete test suite after any changes
./run-tests.sh

# Check for breaking changes
npm run test
npm run type-check
npm run lint
```

---

## 9. MONITORING & LOGGING

### Check n8n Logs
```bash
# Docker logs
docker logs n8n-container -f

# File logs
tail -f /var/log/n8n/workflow.log
```

### Check Application Logs
```bash
# Next.js logs
npm run dev

# Check API logs
tail -f logs/api.log
```

### Database Logs
```sql
-- Enable logging
ALTER DATABASE lbf_techno SET log_statement = 'all';

-- View logs
SELECT * FROM pg_stat_activity WHERE datname = 'lbf_techno';
```

---

## 10. ACCEPTANCE TESTING

### User Acceptance Test Scenarios

#### Scenario 1: Complete Submission Flow
1. Submit form via UI
2. Verify webhook received
3. Check database entry created
4. Monitor workflow execution
5. Verify all report sections generated
6. Check callback received
7. Verify report displayed correctly

#### Scenario 2: Error Recovery
1. Submit with invalid data
2. Verify error handling
3. Check retry logic
4. Verify error logged
5. Check user notification

#### Scenario 3: Performance
1. Submit multiple forms simultaneously
2. Verify all processed correctly
3. Check processing time
4. Verify no data loss

---

## TEST RESULTS TEMPLATE

```markdown
## Test Results - [Date]

### Environment
- n8n Version: 
- Database: 
- Node Version: 

### Test Summary
- Total Tests: 
- Passed: 
- Failed: 
- Skipped: 

### Failed Tests
1. Test Name: 
   - Error: 
   - Expected: 
   - Actual: 

### Performance Metrics
- Average Response Time: 
- 95th Percentile: 
- Max Response Time: 
- Throughput: 

### Notes
- 
```

---

## AUTOMATED TESTING SCRIPT

```bash
#!/bin/bash
# run-tests.sh

echo "Starting LBF Technoglow Simulator Tests..."

# 1. Test database connection
echo "Testing database connection..."
psql "$DATABASE_URL" -c "SELECT 1;" || exit 1

# 2. Test webhook endpoint
echo "Testing webhook endpoint..."
curl -f -X POST "$N8N_TEST_WEBHOOK" \
  -H "Content-Type: application/json" \
  -H "X-Webhook-Secret: $N8N_WEBHOOK_SECRET" \
  -d '{"test": true}' || exit 1

# 3. Test complete flow
echo "Testing complete flow..."
RESPONSE=$(curl -s -X POST "$N8N_TEST_WEBHOOK" \
  -H "Content-Type: application/json" \
  -H "X-Webhook-Secret: $N8N_WEBHOOK_SECRET" \
  -d @data/n8n/test-payload.json)

SUBMISSION_ID=$(echo $RESPONSE | jq -r '.submissionId')

# 4. Wait for processing
echo "Waiting for processing..."
sleep 30

# 5. Check results
echo "Checking results..."
psql "$DATABASE_URL" -c "
SELECT status FROM submissions WHERE id = '$SUBMISSION_ID';
" || exit 1

echo "All tests passed!"
```

---

## NEXT STEPS

1. Run unit tests for each component
2. Run integration tests for complete flow
3. Perform load testing
4. Document any issues found
5. Fix issues and retest
6. Get approval for production deployment
