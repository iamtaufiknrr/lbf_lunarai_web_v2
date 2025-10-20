-- ============================================================================
-- LBF Technoglow Simulator - Main Database Schema
-- Version: 1.0.0
-- Compatible with: PostgreSQL 15+ (Neon Postgres)
-- Created: October 20, 2025
-- ============================================================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================================
-- TABLE: submissions
-- Purpose: Track all form submissions
-- ============================================================================
CREATE TABLE IF NOT EXISTS submissions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    submitted_at TIMESTAMP NOT NULL DEFAULT NOW(),
    target_environment VARCHAR(20) NOT NULL CHECK (target_environment IN ('test', 'production')),
    brand_name VARCHAR(255) NOT NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'queued' CHECK (status IN ('queued', 'running', 'completed', 'error')),
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Indexes for submissions
CREATE INDEX IF NOT EXISTS idx_submissions_status ON submissions(status);
CREATE INDEX IF NOT EXISTS idx_submissions_created_at ON submissions(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_submissions_brand_name ON submissions(brand_name);
CREATE INDEX IF NOT EXISTS idx_submissions_environment ON submissions(target_environment);

-- ============================================================================
-- TABLE: submission_payloads
-- Purpose: Store complete form data as JSONB
-- ============================================================================
CREATE TABLE IF NOT EXISTS submission_payloads (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    submission_id UUID NOT NULL REFERENCES submissions(id) ON DELETE CASCADE,
    payload JSONB NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Indexes for submission_payloads
CREATE INDEX IF NOT EXISTS idx_submission_payloads_submission_id ON submission_payloads(submission_id);
CREATE INDEX IF NOT EXISTS idx_submission_payloads_payload_gin ON submission_payloads USING GIN (payload);

-- ============================================================================
-- TABLE: workflow_runs
-- Purpose: Track n8n workflow executions
-- ============================================================================
CREATE TABLE IF NOT EXISTS workflow_runs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    submission_id UUID NOT NULL REFERENCES submissions(id) ON DELETE CASCADE,
    webhook_url TEXT NOT NULL,
    webhook_response JSONB,
    status VARCHAR(50) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'running', 'completed', 'error')),
    retry_count INTEGER NOT NULL DEFAULT 0,
    last_error TEXT,
    started_at TIMESTAMP NOT NULL DEFAULT NOW(),
    completed_at TIMESTAMP,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Indexes for workflow_runs
CREATE INDEX IF NOT EXISTS idx_workflow_runs_submission_id ON workflow_runs(submission_id);
CREATE INDEX IF NOT EXISTS idx_workflow_runs_status ON workflow_runs(status);
CREATE INDEX IF NOT EXISTS idx_workflow_runs_started_at ON workflow_runs(started_at DESC);

-- ============================================================================
-- TABLE: report_sections
-- Purpose: Store generated report sections from AI agents
-- ============================================================================
CREATE TABLE IF NOT EXISTS report_sections (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    submission_id UUID NOT NULL REFERENCES submissions(id) ON DELETE CASCADE,
    section_type VARCHAR(100) NOT NULL,
    section_data JSONB NOT NULL,
    "order" INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Indexes for report_sections
CREATE INDEX IF NOT EXISTS idx_report_sections_submission_id ON report_sections(submission_id);
CREATE INDEX IF NOT EXISTS idx_report_sections_type ON report_sections(section_type);
CREATE INDEX IF NOT EXISTS idx_report_sections_order ON report_sections("order");
CREATE INDEX IF NOT EXISTS idx_report_sections_data_gin ON report_sections USING GIN (section_data);

-- ============================================================================
-- TABLE: audit_logs
-- Purpose: Complete audit trail for all operations
-- ============================================================================
CREATE TABLE IF NOT EXISTS audit_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    submission_id UUID REFERENCES submissions(id) ON DELETE SET NULL,
    action VARCHAR(100) NOT NULL,
    actor_type VARCHAR(50) NOT NULL CHECK (actor_type IN ('user', 'system', 'agent')),
    metadata JSONB,
    ip_address VARCHAR(45),
    user_agent TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Indexes for audit_logs
CREATE INDEX IF NOT EXISTS idx_audit_logs_submission_id ON audit_logs(submission_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_action ON audit_logs(action);
CREATE INDEX IF NOT EXISTS idx_audit_logs_created_at ON audit_logs(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_audit_logs_actor_type ON audit_logs(actor_type);

-- ============================================================================
-- TRIGGERS: Auto-update timestamps
-- ============================================================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for submissions
DROP TRIGGER IF EXISTS update_submissions_updated_at ON submissions;
CREATE TRIGGER update_submissions_updated_at
    BEFORE UPDATE ON submissions
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Trigger for workflow_runs
DROP TRIGGER IF EXISTS update_workflow_runs_updated_at ON workflow_runs;
CREATE TRIGGER update_workflow_runs_updated_at
    BEFORE UPDATE ON workflow_runs
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Trigger for report_sections
DROP TRIGGER IF EXISTS update_report_sections_updated_at ON report_sections;
CREATE TRIGGER update_report_sections_updated_at
    BEFORE UPDATE ON report_sections
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- VIEWS: Useful queries
-- ============================================================================

-- View: Complete submission details
CREATE OR REPLACE VIEW v_submission_details AS
SELECT 
    s.id,
    s.submitted_at,
    s.target_environment,
    s.brand_name,
    s.status,
    sp.payload,
    wr.webhook_url,
    wr.status AS workflow_status,
    wr.retry_count,
    wr.started_at AS workflow_started_at,
    wr.completed_at AS workflow_completed_at,
    COUNT(DISTINCT rs.id) AS report_sections_count,
    s.created_at,
    s.updated_at
FROM submissions s
LEFT JOIN submission_payloads sp ON s.id = sp.submission_id
LEFT JOIN workflow_runs wr ON s.id = wr.submission_id
LEFT JOIN report_sections rs ON s.id = rs.submission_id
GROUP BY s.id, sp.payload, wr.webhook_url, wr.status, wr.retry_count, wr.started_at, wr.completed_at;

-- View: Recent submissions summary
CREATE OR REPLACE VIEW v_recent_submissions AS
SELECT 
    s.id,
    s.submitted_at,
    s.brand_name,
    s.status,
    s.target_environment,
    wr.status AS workflow_status,
    COUNT(DISTINCT rs.id) AS sections_completed
FROM submissions s
LEFT JOIN workflow_runs wr ON s.id = wr.submission_id
LEFT JOIN report_sections rs ON s.id = rs.submission_id
WHERE s.created_at >= NOW() - INTERVAL '7 days'
GROUP BY s.id, wr.status
ORDER BY s.created_at DESC;

-- ============================================================================
-- FUNCTIONS: Helper functions
-- ============================================================================

-- Function: Get submission status
CREATE OR REPLACE FUNCTION get_submission_status(p_submission_id UUID)
RETURNS TABLE (
    submission_id UUID,
    status VARCHAR,
    workflow_status VARCHAR,
    sections_count BIGINT,
    last_updated TIMESTAMP
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        s.id,
        s.status,
        wr.status AS workflow_status,
        COUNT(DISTINCT rs.id) AS sections_count,
        s.updated_at
    FROM submissions s
    LEFT JOIN workflow_runs wr ON s.id = wr.submission_id
    LEFT JOIN report_sections rs ON s.id = rs.submission_id
    WHERE s.id = p_submission_id
    GROUP BY s.id, wr.status;
END;
$$ LANGUAGE plpgsql;

-- Function: Get report sections by submission
CREATE OR REPLACE FUNCTION get_report_sections(p_submission_id UUID)
RETURNS TABLE (
    section_type VARCHAR,
    section_data JSONB,
    section_order INTEGER,
    created_at TIMESTAMP
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        rs.section_type,
        rs.section_data,
        rs."order",
        rs.created_at
    FROM report_sections rs
    WHERE rs.submission_id = p_submission_id
    ORDER BY rs."order" ASC;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- COMMENTS: Table and column documentation
-- ============================================================================

COMMENT ON TABLE submissions IS 'Main table tracking all form submissions';
COMMENT ON TABLE submission_payloads IS 'Complete form data stored as JSONB';
COMMENT ON TABLE workflow_runs IS 'n8n workflow execution tracking';
COMMENT ON TABLE report_sections IS 'Generated report sections from AI agents';
COMMENT ON TABLE audit_logs IS 'Complete audit trail for all operations';

COMMENT ON COLUMN submissions.target_environment IS 'test or production environment';
COMMENT ON COLUMN submissions.status IS 'queued, running, completed, or error';
COMMENT ON COLUMN workflow_runs.retry_count IS 'Number of retry attempts';
COMMENT ON COLUMN report_sections."order" IS 'Display order of sections';

-- ============================================================================
-- GRANTS: Set appropriate permissions (adjust as needed)
-- ============================================================================

-- Grant permissions to application user (replace 'app_user' with your actual user)
-- GRANT SELECT, INSERT, UPDATE ON ALL TABLES IN SCHEMA public TO app_user;
-- GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO app_user;
-- GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO app_user;

-- ============================================================================
-- VERIFICATION QUERIES
-- ============================================================================

-- Verify tables created
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
  AND table_name IN ('submissions', 'submission_payloads', 'workflow_runs', 'report_sections', 'audit_logs')
ORDER BY table_name;

-- Verify indexes created
SELECT tablename, indexname 
FROM pg_indexes 
WHERE schemaname = 'public' 
  AND tablename IN ('submissions', 'submission_payloads', 'workflow_runs', 'report_sections', 'audit_logs')
ORDER BY tablename, indexname;

-- Verify views created
SELECT table_name 
FROM information_schema.views 
WHERE table_schema = 'public'
ORDER BY table_name;

-- ============================================================================
-- END OF SCHEMA
-- ============================================================================

-- Success message
DO $$
BEGIN
    RAISE NOTICE '✅ LBF Technoglow Simulator schema created successfully!';
    RAISE NOTICE 'Tables: submissions, submission_payloads, workflow_runs, report_sections, audit_logs';
    RAISE NOTICE 'Views: v_submission_details, v_recent_submissions';
    RAISE NOTICE 'Functions: get_submission_status, get_report_sections';
END $$;
