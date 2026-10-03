require_command() {
    local cmd="$1"
    if ! command -v "$cmd" &> /dev/null; then
        error_exit "Required command '$cmd' not found. Please install it." 3
    fi
}

#!/bin/bash
# database-backup.sh — creates a compressed mysqldump backup of the configured database
# Credentials come from ~/.my.cnf, never hardcoded here

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TOOLKIT_DIR="$SCRIPT_DIR"
source "$SCRIPT_DIR/config/cloudops.conf"
source "$SCRIPT_DIR/lib/common.sh"
TOOLKIT_DIR="$SCRIPT_DIR"

DB_BACKUP_RETENTION_COUNT=5

main() {
    log "INFO" "===== Database backup started ====="
    log "INFO" "Database: $DB_NAME"

    require_command "mysqldump"

    if [ ! -f "$HOME/.my.cnf" ]; then
        error_exit ".my.cnf credentials file not found at $HOME/.my.cnf" 3
    fi

    mkdir -p "$BACKUP_DIR"

    local timestamp
    timestamp=$(date '+%Y%m%d_%H%M%S')
    local dump_file="$BACKUP_DIR/${DB_NAME}_${timestamp}.sql.gz"

    if mysqldump --no-tablespaces "$DB_NAME" | gzip > "$dump_file"; then
        local size
        size=$(du -h "$dump_file" | cut -f1)
        log "INFO" "Database backup created: $dump_file ($size)"
    else
        rm -f "$dump_file"
        error_exit "Database backup failed for $DB_NAME" 1
    fi

    log "INFO" "Checking for old database backups to rotate (keeping newest $DB_BACKUP_RETENTION_COUNT)"
    local old_backups
    old_backups=$(ls -1t "$BACKUP_DIR"/${DB_NAME}_*.sql.gz 2>/dev/null | tail -n +$((DB_BACKUP_RETENTION_COUNT + 1)))

    if [ -n "$old_backups" ]; then
        echo "$old_backups" | while read -r old_file; do
            rm -f "$old_file"
            log "INFO" "Rotated out old database backup: $old_file"
        done
    else
        log "INFO" "No old database backups to rotate"
    fi

    log "INFO" "===== Database backup finished ====="
    exit 0
}

main "$@"