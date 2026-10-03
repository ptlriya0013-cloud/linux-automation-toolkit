#!/bin/bash
# backup.sh — creates a timestamped compressed backup of a target directory
# Rotates old backups beyond BACKUP_RETENTION_COUNT

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TOOLKIT_DIR="$SCRIPT_DIR"
source "$SCRIPT_DIR/config/cloudops.conf"
source "$SCRIPT_DIR/lib/common.sh"
TOOLKIT_DIR="$SCRIPT_DIR"

BACKUP_SOURCE="${1:-$SCRIPT_DIR}"
BACKUP_RETENTION_COUNT=5

main() {
    log "INFO" "===== Backup started ====="
    log "INFO" "Source: $BACKUP_SOURCE"

    if [ ! -d "$BACKUP_SOURCE" ]; then
        error_exit "Backup source directory does not exist: $BACKUP_SOURCE" 3
    fi

    mkdir -p "$BACKUP_DIR"

    local timestamp
    timestamp=$(date '+%Y%m%d_%H%M%S')
    local source_name
    source_name=$(basename "$BACKUP_SOURCE")
    local backup_file="$BACKUP_DIR/${source_name}_${timestamp}.tar.gz"

    if tar -czf "$backup_file" --exclude="logs" --exclude=".git" -C "$(dirname "$BACKUP_SOURCE")" "$source_name"; then
        local size
        size=$(du -h "$backup_file" | cut -f1)
        log "INFO" "Backup created: $backup_file ($size)"
    else
        error_exit "Backup failed for $BACKUP_SOURCE" 1
    fi

    log "INFO" "Checking for old backups to rotate (keeping newest $BACKUP_RETENTION_COUNT)"
    local old_backups
    old_backups=$(ls -1t "$BACKUP_DIR"/${source_name}_*.tar.gz 2>/dev/null | tail -n +$((BACKUP_RETENTION_COUNT + 1)))

    if [ -n "$old_backups" ]; then
        echo "$old_backups" | while read -r old_file; do
            rm -f "$old_file"
            log "INFO" "Rotated out old backup: $old_file"
        done
    else
        log "INFO" "No old backups to rotate"
    fi

    log "INFO" "===== Backup finished ====="
    exit 0
}

main "$@"