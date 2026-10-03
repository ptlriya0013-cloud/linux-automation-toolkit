#!/bin/bash
# deployment.sh — deploys the toolkit to a target directory with health-check verification and automatic rollback
# Usage: deployment.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TOOLKIT_DIR="$SCRIPT_DIR"
source "$SCRIPT_DIR/config/cloudops.conf"
source "$SCRIPT_DIR/lib/common.sh"

DEPLOY_DIR="$HOME/deployed-toolkit"
DEPLOY_BACKUP_DIR="$HOME/deployed-toolkit-backup"

rollback() {
    log "ERROR" "Deployment failed health check — rolling back"

    if [ -d "$DEPLOY_BACKUP_DIR" ]; then
        rm -rf "$DEPLOY_DIR"
        mv "$DEPLOY_BACKUP_DIR" "$DEPLOY_DIR"
        log "INFO" "Rollback complete — previous version restored"
    else
        log "WARN" "No previous backup found — nothing to roll back to"
    fi

    exit 1
}

main() {
    log "INFO" "===== Deployment started ====="

    if [ -d "$DEPLOY_DIR" ]; then
        rm -rf "$DEPLOY_BACKUP_DIR"
        mv "$DEPLOY_DIR" "$DEPLOY_BACKUP_DIR"
        log "INFO" "Backed up current deployment to $DEPLOY_BACKUP_DIR"
    else
        log "INFO" "No existing deployment found — this is a fresh deploy"
    fi

    mkdir -p "$DEPLOY_DIR"
    rsync -a --exclude=".git" --exclude="logs" "$SCRIPT_DIR/" "$DEPLOY_DIR/"
    log "INFO" "New version copied to $DEPLOY_DIR"

    log "INFO" "Running post-deploy health check..."
    if "$DEPLOY_DIR/scripts/health-check.sh" > /dev/null 2>&1; then
        log "INFO" "Post-deploy health check passed"
    else
        rollback
    fi

    rm -rf "$DEPLOY_BACKUP_DIR"
    log "INFO" "===== Deployment finished successfully ====="
    exit 0
}

main "$@"