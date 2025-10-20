#!/bin/bash

# ============================================
# BACKUP & RESTORE SCRIPT
# LBF Technoglow Simulator Database
# ============================================

# Configuration
BACKUP_DIR="/backups/lbf_techno"
DATABASE_URL="${DATABASE_URL:-postgresql://user:password@host/database}"
S3_BUCKET="${S3_BUCKET:-}"
RETENTION_DAYS=30

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# ============================================
# FUNCTIONS
# ============================================

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# ============================================
# BACKUP FUNCTION
# ============================================

backup_database() {
    local DATE=$(date +%Y%m%d_%H%M%S)
    local BACKUP_FILE="$BACKUP_DIR/backup_$DATE.sql.gz"
    
    log_info "Starting database backup..."
    
    # Create backup directory if not exists
    mkdir -p "$BACKUP_DIR"
    
    # Perform backup
    if pg_dump "$DATABASE_URL" | gzip > "$BACKUP_FILE"; then
        log_info "Backup created successfully: $BACKUP_FILE"
        
        # Get file size
        local SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
        log_info "Backup size: $SIZE"
        
        # Upload to S3 if configured
        if [ -n "$S3_BUCKET" ]; then
            log_info "Uploading to S3..."
            if aws s3 cp "$BACKUP_FILE" "s3://$S3_BUCKET/backups/"; then
                log_info "Uploaded to S3 successfully"
            else
                log_error "Failed to upload to S3"
            fi
        fi
        
        # Cleanup old backups
        cleanup_old_backups
        
        return 0
    else
        log_error "Backup failed!"
        return 1
    fi
}

# ============================================
# RESTORE FUNCTION
# ============================================

restore_database() {
    local BACKUP_FILE="$1"
    
    if [ -z "$BACKUP_FILE" ]; then
        log_error "Please provide backup file path"
        echo "Usage: $0 restore <backup_file>"
        return 1
    fi
    
    if [ ! -f "$BACKUP_FILE" ]; then
        log_error "Backup file not found: $BACKUP_FILE"
        return 1
    fi
    
    log_warn "WARNING: This will restore the database from backup"
    log_warn "Current data will be overwritten!"
    read -p "Are you sure? (yes/no): " CONFIRM
    
    if [ "$CONFIRM" != "yes" ]; then
        log_info "Restore cancelled"
        return 0
    fi
    
    log_info "Starting database restore..."
    
    # Restore database
    if gunzip -c "$BACKUP_FILE" | psql "$DATABASE_URL"; then
        log_info "Database restored successfully"
        
        # Verify restoration
        verify_restore
        
        return 0
    else
        log_error "Restore failed!"
        return 1
    fi
}

# ============================================
# CLEANUP OLD BACKUPS
# ============================================

cleanup_old_backups() {
    log_info "Cleaning up old backups (older than $RETENTION_DAYS days)..."
    
    local DELETED_COUNT=$(find "$BACKUP_DIR" -name "backup_*.sql.gz" -mtime +$RETENTION_DAYS -delete -print | wc -l)
    
    if [ "$DELETED_COUNT" -gt 0 ]; then
        log_info "Deleted $DELETED_COUNT old backup(s)"
    else
        log_info "No old backups to delete"
    fi
}

# ============================================
# VERIFY RESTORE
# ============================================

verify_restore() {
    log_info "Verifying database restoration..."
    
    # Check if tables exist
    local TABLE_COUNT=$(psql "$DATABASE_URL" -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public';")
    
    if [ "$TABLE_COUNT" -gt 0 ]; then
        log_info "Verification passed: Found $TABLE_COUNT tables"
        
        # Check submissions count
        local SUBMISSION_COUNT=$(psql "$DATABASE_URL" -t -c "SELECT COUNT(*) FROM submissions;")
        log_info "Total submissions: $SUBMISSION_COUNT"
    else
        log_error "Verification failed: No tables found"
        return 1
    fi
}

# ============================================
# LIST BACKUPS
# ============================================

list_backups() {
    log_info "Available backups in $BACKUP_DIR:"
    echo ""
    
    if [ -d "$BACKUP_DIR" ]; then
        ls -lh "$BACKUP_DIR"/backup_*.sql.gz 2>/dev/null | awk '{print $9, "(" $5 ")", $6, $7, $8}'
    else
        log_warn "Backup directory not found"
    fi
}

# ============================================
# BACKUP SPECIFIC TABLES
# ============================================

backup_tables() {
    local DATE=$(date +%Y%m%d_%H%M%S)
    local TABLES=("submissions" "submission_payloads" "workflow_runs" "report_sections" "audit_logs")
    
    log_info "Starting selective table backup..."
    
    mkdir -p "$BACKUP_DIR/tables_$DATE"
    
    for TABLE in "${TABLES[@]}"; do
        log_info "Backing up table: $TABLE"
        pg_dump "$DATABASE_URL" -t "$TABLE" | gzip > "$BACKUP_DIR/tables_$DATE/${TABLE}.sql.gz"
    done
    
    log_info "Table backups completed in: $BACKUP_DIR/tables_$DATE"
}

# ============================================
# EXPORT TO CSV
# ============================================

export_to_csv() {
    local DATE=$(date +%Y%m%d_%H%M%S)
    local EXPORT_DIR="$BACKUP_DIR/csv_export_$DATE"
    
    log_info "Exporting data to CSV..."
    
    mkdir -p "$EXPORT_DIR"
    
    # Export submissions
    psql "$DATABASE_URL" -c "\COPY (SELECT * FROM submissions) TO '$EXPORT_DIR/submissions.csv' WITH CSV HEADER"
    
    # Export workflow_runs
    psql "$DATABASE_URL" -c "\COPY (SELECT * FROM workflow_runs) TO '$EXPORT_DIR/workflow_runs.csv' WITH CSV HEADER"
    
    # Export report_sections
    psql "$DATABASE_URL" -c "\COPY (SELECT id, submission_id, section_type, order, created_at FROM report_sections) TO '$EXPORT_DIR/report_sections.csv' WITH CSV HEADER"
    
    log_info "CSV export completed in: $EXPORT_DIR"
}

# ============================================
# MAIN SCRIPT
# ============================================

case "$1" in
    backup)
        backup_database
        ;;
    restore)
        restore_database "$2"
        ;;
    list)
        list_backups
        ;;
    cleanup)
        cleanup_old_backups
        ;;
    tables)
        backup_tables
        ;;
    csv)
        export_to_csv
        ;;
    verify)
        verify_restore
        ;;
    *)
        echo "LBF Technoglow Simulator - Database Backup & Restore"
        echo ""
        echo "Usage: $0 {backup|restore|list|cleanup|tables|csv|verify}"
        echo ""
        echo "Commands:"
        echo "  backup          - Create full database backup"
        echo "  restore <file>  - Restore database from backup file"
        echo "  list            - List available backups"
        echo "  cleanup         - Remove old backups"
        echo "  tables          - Backup individual tables"
        echo "  csv             - Export data to CSV files"
        echo "  verify          - Verify database integrity"
        echo ""
        echo "Environment Variables:"
        echo "  DATABASE_URL    - PostgreSQL connection string"
        echo "  BACKUP_DIR      - Backup directory (default: /backups/lbf_techno)"
        echo "  S3_BUCKET       - S3 bucket for remote backup (optional)"
        echo "  RETENTION_DAYS  - Backup retention period (default: 30)"
        exit 1
        ;;
esac

exit $?
