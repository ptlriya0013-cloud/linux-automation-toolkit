#!/bin/bash
# log-cleanup.sh — deletes log files older than LOG_RETENTION_DAYS
# Supports --dry-run to preview deletions without actually deleting anything

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TOOLKIT_DIR="$SCRIPT_DIR"
source "$SCRIPT_DIR/config/cloudops.conf"
source "$SCRIPT_DIR/lib/common.sh"
TOOLKIT_DIR="$SCRIPT_DIR"

DRY_RUN=0

parse_args() {
    for arg in "$@"; do
        case "$arg" in
            --dry-run)
                DRY_RUN=1
                ;;
            *)
                error_exit "Unknown argument: $arg (usage: log-cleanup.sh [--dry-run])" 2
                ;;
        esac
    done
}

main() {
    parse_args "$@"

    if [ "$DRY_RUN" -eq 1 ]; then
        log "INFO" "===== Log cleanup started (DRY RUN — no files will be deleted) ====="
    else
        log "INFO" "===== Log cleanup started ====="
    fi

    local deleted_count=0

    while IFS= read -r -d '' file; do
        if [ "$DRY_RUN" -eq 1 ]; then
            log "INFO" "[DRY RUN] Would delete: $file"
        else
            rm -f "$file"
            log "INFO" "Deleted: $file"
        fi
        deleted_count=$((deleted_count + 1))
    done < <(find "$LOG_DIR" -type f -name "*.log" -mtime "+$LOG_RETENTION_DAYS" -print0)

    log "INFO" "===== Log cleanup finished — $deleted_count file(s) processed ====="
    exit 0
}

main "$@"