#!/bin/bash
# user-delete.sh — deletes a Linux user and optionally their home directory
# Usage: user-delete.sh <username> [--remove-home] [--force]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TOOLKIT_DIR="$SCRIPT_DIR"
source "$SCRIPT_DIR/config/cloudops.conf"
source "$SCRIPT_DIR/lib/common.sh"

USERNAME=""
REMOVE_HOME=0
FORCE=0

parse_args() {
    if [ $# -eq 0 ]; then
        error_exit "Usage: user-delete.sh <username> [--remove-home] [--force]" 2
    fi

    USERNAME="$1"
    shift

    for arg in "$@"; do
        case "$arg" in
            --remove-home)
                REMOVE_HOME=1
                ;;
            --force)
                FORCE=1
                ;;
            *)
                error_exit "Unknown argument: $arg" 2
                ;;
        esac
    done
}

validate_target() {
    if ! id "$USERNAME" &>/dev/null; then
        error_exit "User '$USERNAME' does not exist" 1
    fi

    local protected_users=("root" "riya0519" "$(whoami)")
    for protected in "${protected_users[@]}"; do
        if [ "$USERNAME" == "$protected" ]; then
            error_exit "Refusing to delete protected/current user: '$USERNAME'" 2
        fi
    done
}

main() {
    parse_args "$@"
    validate_target

    log "INFO" "===== User deletion started: $USERNAME ====="

    if [ "$FORCE" -ne 1 ]; then
        error_exit "Refusing to delete '$USERNAME' without --force flag (safety check)" 2
    fi

    local userdel_opts=""
    if [ "$REMOVE_HOME" -eq 1 ]; then
        userdel_opts="-r"
        log "INFO" "Will also remove home directory for '$USERNAME'"
    fi

    if userdel $userdel_opts "$USERNAME"; then
        log "INFO" "User '$USERNAME' deleted successfully"
    else
        error_exit "Failed to delete user '$USERNAME'" 1
    fi

    log "INFO" "===== User deletion finished: $USERNAME ====="
    exit 0
}

main "$@"