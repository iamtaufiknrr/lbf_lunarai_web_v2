-- ============================================
-- SAMPLE QUERIES FOR LBF TECHNOGLOW SIMULATOR
-- ============================================

-- ============================================
-- 1. BASIC QUERIES
-- ============================================

-- Get submission with full payload
SELECT 
    s.id,
    s.brand_name,
    s.status,
    s.target_environment,
    s.submitted_at,
    sp.payload
FROM submissions s
LEFT JOIN submission_payloads sp ON s.id = sp.submission_id
WHERE s.id = 'your-submission-id';

-- Get submission with all report sections
SELECT 
    s.id,
    s.brand_name,
    s.status,
    rs.section_type,
    rs.section_data,
    rs."order"
FROM submissions s
LEFT JOIN report_sections rs ON s.id = rs.submission_id
WHERE s.id = 'your-submission-id'
ORDER BY rs."order";

-- Get workflow status
SELECT 
    wr.status,
    wr.retry_count,
    wr.last_error,
    wr.started_at,
    wr.completed_at,
    EXTRACT(EPOCH FROM (wr.completed_at - wr.started_at)) as duration_seconds
FROM workflow_runs wr
WHERE wr.submission_id = 'your-submission-id'
ORDER BY wr.created_at DESC
LIMIT 1;

-- ============================================
-- 2. MONITORING QUERIES
-- ============================================

-- Get recent submissions with stats
SELECT 
    s.id,
    s.brand_name,
    s.status,
    s.target_environment,
    s.submitted_at,
    COUNT(DISTINCT rs.id) as section_count,
    wr.status as workflow_status,
    wr.retry_count
FROM submissions s
LEFT JOIN report_sections rs ON s.id = rs.submission_id
LEFT JOIN workflow_runs wr ON s.id = wr.submission_id
GROUP BY s.id, s.brand_name, s.status, s.target_environment, s.submitted_at, wr.status, wr.retry_count
ORDER BY s.submitted_at DESC
LIMIT 20;

-- Monitor workflow performance (last 7 days)
SELECT 
    DATE(started_at) as date,
    status,
    COUNT(*) as count,
    AVG(EXTRACT(EPOCH FROM (completed_at - started_at))) as avg_duration_seconds,
    MIN(EXTRACT(EPOCH FROM (completed_at - started_at))) as min_duration_seconds,
    MAX(EXTRACT(EPOCH FROM (completed_at - started_at))) as max_duration_seconds
FROM workflow_runs
WHERE started_at > NOW() - INTERVAL '7 days'
GROUP BY DATE(started_at), status
ORDER BY date DESC, status;

-- Check failed workflows
SELECT 
    wr.id,
    wr.submission_id,
    s.brand_name,
    wr.status,
    wr.last_error,
    wr.retry_count,
    wr.started_at
FROM workflow_runs wr
JOIN submissions s ON wr.submission_id = s.id
WHERE wr.status = 'error'
ORDER BY wr.started_at DESC
LIMIT 20;

-- Report section completion rate
SELECT 
    s.id,
    s.brand_name,
    s.status,
    COUNT(rs.id) as sections_completed,
    s.submitted_at,
    EXTRACT(EPOCH FROM (NOW() - s.submitted_at)) / 60 as minutes_since_submission
FROM submissions s
LEFT JOIN report_sections rs ON s.id = rs.submission_id
WHERE s.submitted_at > NOW() - INTERVAL '24 hours'
GROUP BY s.id, s.brand_name, s.status, s.submitted_at
ORDER BY s.submitted_at DESC;

-- ============================================
-- 3. ANALYTICS QUERIES
-- ============================================

-- Submission statistics by environment
SELECT 
    target_environment,
    status,
    COUNT(*) as count,
    ROUND(COUNT(*)::numeric / SUM(COUNT(*)) OVER (PARTITION BY target_environment) * 100, 2) as percentage
FROM submissions
WHERE submitted_at > NOW() - INTERVAL '30 days'
GROUP BY target_environment, status
ORDER BY target_environment, count DESC;

-- Most common section types
SELECT 
    section_type,
    COUNT(*) as count,
    AVG(jsonb_array_length(section_data)) as avg_data_size
FROM report_sections
GROUP BY section_type
ORDER BY count DESC;

-- Audit log analysis
SELECT 
    action,
    actor_type,
    COUNT(*) as count,
    DATE(created_at) as date
FROM audit_logs
WHERE created_at > NOW() - INTERVAL '7 days'
GROUP BY action, actor_type, DATE(created_at)
ORDER BY date DESC, count DESC;

-- Average processing time by brand
SELECT 
    s.brand_name,
    COUNT(*) as total_submissions,
    AVG(EXTRACT(EPOCH FROM (s.updated_at - s.submitted_at))) / 60 as avg_processing_minutes,
    SUM(CASE WHEN s.status = 'completed' THEN 1 ELSE 0 END) as completed_count,
    ROUND(SUM(CASE WHEN s.status = 'completed' THEN 1 ELSE 0 END)::numeric / COUNT(*) * 100, 2) as success_rate
FROM submissions s
WHERE s.submitted_at > NOW() - INTERVAL '30 days'
GROUP BY s.brand_name
HAVING COUNT(*) > 1
ORDER BY total_submissions DESC;

-- ============================================
-- 4. MAINTENANCE QUERIES
-- ============================================

-- Find orphaned records (should not exist due to CASCADE)
SELECT 'submission_payloads' as table_name, COUNT(*) as orphaned_count
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

-- Database size information
SELECT 
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size,
    pg_total_relation_size(schemaname||'.'||tablename) AS size_bytes
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY size_bytes DESC;

-- Index usage statistics
SELECT 
    schemaname,
    tablename,
    indexname,
    idx_scan as index_scans,
    idx_tup_read as tuples_read,
    idx_tup_fetch as tuples_fetched
FROM pg_stat_user_indexes
WHERE schemaname = 'public'
ORDER BY idx_scan DESC;

-- ============================================
-- 5. CLEANUP QUERIES
-- ============================================

-- Delete old test submissions (older than 30 days)
-- WARNING: Use with caution!
-- DELETE FROM submissions 
-- WHERE target_environment = 'test' 
-- AND submitted_at < NOW() - INTERVAL '30 days';

-- Delete old audit logs (older than 90 days)
-- WARNING: Use with caution!
-- DELETE FROM audit_logs 
-- WHERE created_at < NOW() - INTERVAL '90 days';

-- Archive completed submissions older than 6 months
-- (First create an archive table, then move data)
-- CREATE TABLE submissions_archive (LIKE submissions INCLUDING ALL);
-- INSERT INTO submissions_archive 
-- SELECT * FROM submissions 
-- WHERE status = 'completed' 
-- AND submitted_at < NOW() - INTERVAL '6 months';
