-- ============================================
-- LBF TECHNOGLOW SIMULATOR DATABASE SCHEMA
-- ============================================
-- Version: 1.0.0
-- Database: PostgreSQL 15+
-- Purpose: Complete schema for LBF Technoglow Simulator

-- ============================================
-- TABLE: submissions
-- ============================================
CREATE TABLE submissions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    submitted_at TIMESTAMP NOT NULL DEFAULT NOW(),
    target_environment VARCHAR(20) NOT NULL,
    brand_name VARCHAR(255) NOT NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'queued',
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Indexes for submissions
CREATE INDEX idx_submissions_status ON submissions(status);
CREATE INDEX idx_submissions_brand_name ON submissions(brand_name);
CREATE INDEX idx_submissions_created_at ON submissions(created_at DESC);
CREATE INDEX idx_submissions_environment ON submissions(target_environment);

-- ============================================
-- TABLE: submission_payloads
-- ============================================
CREATE TABLE submission_payloads (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    submission_id UUID NOT NULL REFERENCES submissions(id) ON DELETE CASCADE,
    payload JSONB NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Indexes for submission_payloads
CREATE INDEX idx_submission_payloads_submission_id ON submission_payloads(submission_id);
CREATE INDEX idx_submission_payloads_payload ON submission_payloads USING GIN(payload);

-- ============================================
-- TABLE: workflow_runs
-- ============================================
CREATE TABLE workflow_runs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    submission_id UUID NOT NULL REFERENCES submissions(id) ON DELETE CASCADE,
    webhook_url TEXT NOT NULL,
    webhook_response JSONB,
    status VARCHAR(50) NOT NULL DEFAULT 'pending',
    retry_count INTEGER NOT NULL DEFAULT 0,
    last_error TEXT,
    started_at TIMESTAMP NOT NULL DEFAULT NOW(),
    completed_at TIMESTAMP,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Indexes for workflow_runs
CREATE INDEX idx_workflow_runs_submission_id ON workflow_runs(submission_id);
CREATE INDEX idx_workflow_runs_status ON workflow_runs(status);
CREATE INDEX idx_workflow_runs_started_at ON workflow_runs(started_at DESC);

-- ============================================
-- TABLE: report_sections
-- ============================================
CREATE TABLE report_sections (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    submission_id UUID NOT NULL REFERENCES submissions(id) ON DELETE CASCADE,
    section_type VARCHAR(100) NOT NULL,
    section_data JSONB NOT NULL,
    "order" INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Indexes for report_sections
CREATE INDEX idx_report_sections_submission_id ON report_sections(submission_id);
CREATE INDEX idx_report_sections_type ON report_sections(section_type);
CREATE INDEX idx_report_sections_order ON report_sections("order");
CREATE INDEX idx_report_sections_submission_order ON report_sections(submission_id, "order");

-- ============================================
-- TABLE: audit_logs
-- ============================================
CREATE TABLE audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    submission_id UUID REFERENCES submissions(id) ON DELETE SET NULL,
    action VARCHAR(100) NOT NULL,
    actor_type VARCHAR(50) NOT NULL,
    metadata JSONB,
    ip_address VARCHAR(45),
    user_agent TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Indexes for audit_logs
CREATE INDEX idx_audit_logs_submission_id ON audit_logs(submission_id);
CREATE INDEX idx_audit_logs_action ON audit_logs(action);
CREATE INDEX idx_audit_logs_created_at ON audit_logs(created_at DESC);
CREATE INDEX idx_audit_logs_actor_type ON audit_logs(actor_type);

-- ============================================
-- TRIGGERS
-- ============================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for submissions table
CREATE TRIGGER update_submissions_updated_at 
BEFORE UPDATE ON submissions
FOR EACH ROW 
EXECUTE FUNCTION update_updated_at_column();

-- Trigger for workflow_runs table
CREATE TRIGGER update_workflow_runs_updated_at 
BEFORE UPDATE ON workflow_runs
FOR EACH ROW 
EXECUTE FUNCTION update_updated_at_column();

-- Trigger for report_sections table
CREATE TRIGGER update_report_sections_updated_at 
BEFORE UPDATE ON report_sections
FOR EACH ROW 
EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- COMMENTS
-- ============================================

COMMENT ON TABLE submissions IS 'Main table storing submission metadata';
COMMENT ON TABLE submission_payloads IS 'Stores complete submission payload as JSONB';
COMMENT ON TABLE workflow_runs IS 'Tracks n8n workflow execution status';
COMMENT ON TABLE report_sections IS 'Stores generated report sections from AI agents';
COMMENT ON TABLE audit_logs IS 'Audit trail for all system actions';

-- ============================================
-- INITIAL DATA (Optional)
-- ============================================

-- Insert sample data for testing (uncomment if needed)
-- INSERT INTO submissions (brand_name, target_environment, status) 
-- VALUES ('Test Brand', 'test', 'queued');
