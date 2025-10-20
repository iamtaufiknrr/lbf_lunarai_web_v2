-- ============================================
-- DATABASE OPTIMIZATION FOR LBF TECHNOGLOW SIMULATOR
-- ============================================

-- ============================================
-- 1. ADDITIONAL INDEXES FOR PERFORMANCE
-- ============================================

-- Composite index for common query patterns
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_submissions_status_created 
ON submissions(status, created_at DESC);

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_report_sections_submission_order 
ON report_sections(submission_id, "order");

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_workflow_runs_status_started 
ON workflow_runs(status, started_at DESC);

-- Partial indexes for active workflows
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_workflow_runs_active 
ON workflow_runs(submission_id, status) 
WHERE status IN ('pending', 'running', 'retrying');

-- Partial index for recent submissions
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_submissions_recent 
ON submissions(submitted_at DESC) 
WHERE submitted_at > NOW() - INTERVAL '30 days';

-- ============================================
-- 2. MATERIALIZED VIEWS FOR DASHBOARD
-- ============================================

-- Materialized view for submission statistics
CREATE MATERIALIZED VIEW IF NOT EXISTS submission_stats AS
SELECT 
    DATE(submitted_at) as date,
    target_environment,
    status,
    COUNT(*) as count,
    AVG(EXTRACT(EPOCH FROM (updated_at - submitted_at))) as avg_processing_time_seconds
FROM submissions
GROUP BY DATE(submitted_at), target_environment, status;

CREATE INDEX idx_submission_stats_date ON submission_stats(date DESC);

-- Materialized view for workflow performance
CREATE MATERIALIZED VIEW IF NOT EXISTS workflow_performance AS
SELECT 
    DATE(started_at) as date,
    status,
    COUNT(*) as total_runs,
    AVG(EXTRACT(EPOCH FROM (completed_at - started_at))) as avg_duration_seconds,
    AVG(retry_count) as avg_retries,
    SUM(CASE WHEN status = 'completed' THEN 1 ELSE 0 END) as successful_runs,
    SUM(CASE WHEN status = 'error' THEN 1 ELSE 0 END) as failed_runs
FROM workflow_runs
WHERE started_at > NOW() - INTERVAL '90 days'
GROUP BY DATE(started_at), status;

CREATE INDEX idx_workflow_performance_date ON workflow_performance(date DESC);

-- Refresh materialized views (run periodically via cron or n8n)
-- REFRESH MATERIALIZED VIEW CONCURRENTLY submission_stats;
-- REFRESH MATERIALIZED VIEW CONCURRENTLY workflow_performance;

-- ============================================
-- 3. QUERY OPTIMIZATION FUNCTIONS
-- ============================================

-- Function to get submission with all related data
CREATE OR REPLACE FUNCTION get_submission_complete(submission_uuid UUID)
RETURNS TABLE (
    submission_id UUID,
    brand_name VARCHAR,
    status VARCHAR,
    submitted_at TIMESTAMP,
    payload JSONB,
    sections JSONB,
    workflow_status VARCHAR,
    workflow_duration NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        s.id,
        s.brand_name,
        s.status,
        s.submitted_at,
        sp.payload,
        jsonb_agg(
            jsonb_build_object(
                'type', rs.section_type,
                'data', rs.section_data,
                'order', rs."order"
            ) ORDER BY rs."order"
        ) as sections,
        wr.status as workflow_status,
        EXTRACT(EPOCH FROM (wr.completed_at - wr.started_at)) as workflow_duration
    FROM submissions s
    LEFT JOIN submission_payloads sp ON s.id = sp.submission_id
    LEFT JOIN report_sections rs ON s.id = rs.submission_id
    LEFT JOIN LATERAL (
        SELECT status, started_at, completed_at
        FROM workflow_runs
        WHERE submission_id = s.id
        ORDER BY created_at DESC
        LIMIT 1
    ) wr ON true
    WHERE s.id = submission_uuid
    GROUP BY s.id, s.brand_name, s.status, s.submitted_at, sp.payload, wr.status, wr.started_at, wr.completed_at;
END;
$$ LANGUAGE plpgsql;

-- Usage: SELECT * FROM get_submission_complete('your-uuid-here');

-- ============================================
-- 4. PARTITIONING (For High Volume)
-- ============================================

-- If you have high volume, consider partitioning audit_logs by date
-- This is an example - implement only if needed

-- CREATE TABLE audit_logs_partitioned (
--     id UUID DEFAULT gen_random_uuid(),
--     submission_id UUID,
--     action VARCHAR(100) NOT NULL,
--     actor_type VARCHAR(50) NOT NULL,
--     metadata JSONB,
--     ip_address VARCHAR(45),
--     user_agent TEXT,
--     created_at TIMESTAMP NOT NULL DEFAULT NOW()
-- ) PARTITION BY RANGE (created_at);

-- CREATE TABLE audit_logs_2025_10 PARTITION OF audit_logs_partitioned
--     FOR VALUES FROM ('2025-10-01') TO ('2025-11-01');

-- CREATE TABLE audit_logs_2025_11 PARTITION OF audit_logs_partitioned
--     FOR VALUES FROM ('2025-11-01') TO ('2025-12-01');

-- ============================================
-- 5. VACUUM AND ANALYZE
-- ============================================

-- Regular maintenance commands (run periodically)
-- VACUUM ANALYZE submissions;
-- VACUUM ANALYZE submission_payloads;
-- VACUUM ANALYZE workflow_runs;
-- VACUUM ANALYZE report_sections;
-- VACUUM ANALYZE audit_logs;

-- ============================================
-- 6. CONNECTION POOLING SETTINGS
-- ============================================

-- Recommended PostgreSQL settings for connection pooling
-- Add these to postgresql.conf or set via ALTER SYSTEM

-- ALTER SYSTEM SET max_connections = 100;
-- ALTER SYSTEM SET shared_buffers = '256MB';
-- ALTER SYSTEM SET effective_cache_size = '1GB';
-- ALTER SYSTEM SET maintenance_work_mem = '64MB';
-- ALTER SYSTEM SET checkpoint_completion_target = 0.9;
-- ALTER SYSTEM SET wal_buffers = '16MB';
-- ALTER SYSTEM SET default_statistics_target = 100;
-- ALTER SYSTEM SET random_page_cost = 1.1;
-- ALTER SYSTEM SET effective_io_concurrency = 200;
-- ALTER SYSTEM SET work_mem = '4MB';
-- ALTER SYSTEM SET min_wal_size = '1GB';
-- ALTER SYSTEM SET max_wal_size = '4GB';

-- SELECT pg_reload_conf(); -- Reload configuration

-- ============================================
-- 7. QUERY PERFORMANCE MONITORING
-- ============================================

-- Enable pg_stat_statements extension for query monitoring
-- CREATE EXTENSION IF NOT EXISTS pg_stat_statements;

-- View slowest queries
-- SELECT 
--     query,
--     calls,
--     total_exec_time,
--     mean_exec_time,
--     max_exec_time
-- FROM pg_stat_statements
-- ORDER BY mean_exec_time DESC
-- LIMIT 10;

-- ============================================
-- 8. JSONB OPTIMIZATION
-- ============================================

-- Create GIN indexes on specific JSONB paths if needed
-- Example: Index on brand name in payload
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_payload_brand_name 
ON submission_payloads USING GIN ((payload -> 'brand' -> 'name'));

-- Example: Index on product functions
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_payload_functions 
ON submission_payloads USING GIN ((payload -> 'productBlueprint' -> 'functions'));

-- ============================================
-- 9. ARCHIVAL STRATEGY
-- ============================================

-- Function to archive old submissions
CREATE OR REPLACE FUNCTION archive_old_submissions(days_old INTEGER DEFAULT 180)
RETURNS INTEGER AS $$
DECLARE
    archived_count INTEGER;
BEGIN
    -- Create archive table if not exists
    CREATE TABLE IF NOT EXISTS submissions_archive (LIKE submissions INCLUDING ALL);
    CREATE TABLE IF NOT EXISTS submission_payloads_archive (LIKE submission_payloads INCLUDING ALL);
    CREATE TABLE IF NOT EXISTS workflow_runs_archive (LIKE workflow_runs INCLUDING ALL);
    CREATE TABLE IF NOT EXISTS report_sections_archive (LIKE report_sections INCLUDING ALL);
    
    -- Archive submissions
    WITH archived AS (
        INSERT INTO submissions_archive
        SELECT * FROM submissions
        WHERE status = 'completed'
        AND submitted_at < NOW() - (days_old || ' days')::INTERVAL
        RETURNING id
    )
    SELECT COUNT(*) INTO archived_count FROM archived;
    
    -- Archive related data
    INSERT INTO submission_payloads_archive
    SELECT sp.* FROM submission_payloads sp
    WHERE sp.submission_id IN (SELECT id FROM submissions_archive);
    
    INSERT INTO workflow_runs_archive
    SELECT wr.* FROM workflow_runs wr
    WHERE wr.submission_id IN (SELECT id FROM submissions_archive);
    
    INSERT INTO report_sections_archive
    SELECT rs.* FROM report_sections rs
    WHERE rs.submission_id IN (SELECT id FROM submissions_archive);
    
    -- Delete archived submissions (CASCADE will handle related tables)
    DELETE FROM submissions
    WHERE id IN (SELECT id FROM submissions_archive);
    
    RETURN archived_count;
END;
$$ LANGUAGE plpgsql;

-- Usage: SELECT archive_old_submissions(180); -- Archive submissions older than 180 days

-- ============================================
-- 10. MONITORING QUERIES
-- ============================================

-- Check table bloat
SELECT
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS total_size,
    pg_size_pretty(pg_relation_size(schemaname||'.'||tablename)) AS table_size,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename) - pg_relation_size(schemaname||'.'||tablename)) AS indexes_size
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;

-- Check index usage
SELECT
    schemaname,
    tablename,
    indexname,
    idx_scan,
    idx_tup_read,
    idx_tup_fetch,
    pg_size_pretty(pg_relation_size(indexrelid)) AS index_size
FROM pg_stat_user_indexes
WHERE schemaname = 'public'
ORDER BY idx_scan ASC;

-- Unused indexes (candidates for removal)
SELECT
    schemaname,
    tablename,
    indexname,
    pg_size_pretty(pg_relation_size(indexrelid)) AS index_size
FROM pg_stat_user_indexes
WHERE schemaname = 'public'
AND idx_scan = 0
AND indexrelname NOT LIKE '%_pkey';
