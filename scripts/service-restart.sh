#!/bin/bash
# service-restart.sh — safely restarts a systemd service with before/after status checks
# Usage: service-restart.sh <service-name>

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TOOLKIT_DIR="$SCRIPT_DIR"
source "$SCRIPT_DIR/config/cloudops.conf"
source "$SCRIPT_DIR/lib/common.sh"

SERVICE_NAME=""

parse_args() {
    if [ $# -ne 1 ]; then
        error_exit "Usage: service-restart.sh <service-name>" 2
    fi
    SERVICE_NAME="$1"
}

service_exists() {
    systemctl list-unit-files "${SERVICE_NAME}.service" 2>/dev/null | grep -q "${SERVICE_NAME}.service"
}

main() {
    parse_args "$@"

    log "INFO" "===== Service restart started: $SERVICE_NAME ====="

    require_command "systemctl"

    if ! service_exists; then
        error_exit "Service '$SERVICE_NAME' does not exist" 3
    fi

    local status_before
    status_before=$(systemctl is-active "$SERVICE_NAME" 2>/dev/null)
    log "INFO" "Status before restart: $status_before"

    if sudo systemctl restart "$SERVICE_NAME"; then
        log "INFO" "Restart command issued for '$SERVICE_NAME'"
    else
        error_exit "Failed to issue restart for '$SERVICE_NAME'" 1
    fi

    sleep 2

    local status_after
    status_after=$(systemctl is-active "$SERVICE_NAME" 2>/dev/null)
    log "INFO" "Status after restart: $status_after"

    if [ "$status_after" == "active" ]; then
        log "INFO" "===== Service restart finished: $SERVICE_NAME is active ====="
        exit 0
    else
        log "ERROR" "Service '$SERVICE_NAME' is not active after restart (status: $status_after)"
        exit 1
    fi
}

main "$@"