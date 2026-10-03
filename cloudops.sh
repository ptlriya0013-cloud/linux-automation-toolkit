#!/bin/bash
# cloudops.sh — unified CLI wrapper for the Linux Server Automation Toolkit
# Usage: cloudops.sh <command> [args...]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOLKIT_DIR="$SCRIPT_DIR"
source "$SCRIPT_DIR/config/cloudops.conf"
source "$SCRIPT_DIR/lib/common.sh"

print_usage() {
    cat << EOF
cloudops.sh — Linux Server Automation Toolkit

Usage: ./cloudops.sh <command> [args...]

Commands:
  health                    Run full system health check
  disk                      Check disk usage across mount points
  processes                 Show top CPU/memory processes
  logs [--dry-run]          Clean up old log files
  backup                    Back up the toolkit directory
  db-backup                 Back up the configured database
  user-create <name> [...]  Create a new Linux user
  user-delete <name> [...]  Delete a Linux user
  services <service-name>   Restart a systemd service
  deploy                    Deploy with health check + rollback

Examples:
  ./cloudops.sh health
  ./cloudops.sh user-create alice --sudo
  ./cloudops.sh services mysql
EOF
}

main() {
    if [ $# -eq 0 ]; then
        print_usage
        exit 2
    fi

    local command="$1"
    shift

    case "$command" in
        health)
            "$SCRIPT_DIR/scripts/health-check.sh" "$@"
            ;;
        disk)
            "$SCRIPT_DIR/scripts/disk-alert.sh" "$@"
            ;;
        processes)
            "$SCRIPT_DIR/scripts/process-monitor.sh" "$@"
            ;;
        logs)
            "$SCRIPT_DIR/scripts/log-cleanup.sh" "$@"
            ;;
        backup)
            "$SCRIPT_DIR/scripts/backup.sh" "$@"
            ;;
        db-backup)
            "$SCRIPT_DIR/scripts/database-backup.sh" "$@"
            ;;
        user-create)
            "$SCRIPT_DIR/scripts/user-create.sh" "$@"
            ;;
        user-delete)
            "$SCRIPT_DIR/scripts/user-delete.sh" "$@"
            ;;
        services)
            "$SCRIPT_DIR/scripts/service-restart.sh" "$@"
            ;;
        deploy)
            "$SCRIPT_DIR/scripts/deployment.sh" "$@"
            ;;
        -h|--help|help)
            print_usage
            exit 0
            ;;
        *)
            log "ERROR" "Unknown command: $command"
            print_usage
            exit 2
            ;;
    esac

    exit $?
}

main "$@"