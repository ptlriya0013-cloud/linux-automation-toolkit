#!/bin/bash
# user-create.sh — creates a new Linux user with home directory
# Usage: user-create.sh <username> [--sudo] [--dry-run]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TOOLKIT_DIR="$SCRIPT_DIR"
source "$SCRIPT_DIR/config/cloudops.conf"
source "$SCRIPT_DIR/lib/common.sh"
TOOLKIT_DIR="$SCRIPT_DIR"

USERNAME=""
GRANT_SUDO=0
DRY_RUN=0

parse_args() {
    if [ $# -eq 0 ]; then
        error_exit "Usage: user-create.sh <username> [--sudo] [--dry-run]" 2
    fi

    USERNAME="$1"
    shift

    for arg in "$@"; do
        case "$arg" in
            --sudo)
                GRANT_SUDO=1
                ;;
            --dry-run)
                DRY_RUN=1
                ;;
            *)
                error_exit "Unknown argument: $arg" 2
                ;;
        esac
    done
}

validate_username() {
    if ! [[ "$USERNAME" =~ ^[a-z_][a-z0-9_-]{2,31}$ ]]; then
        error_exit "Invalid username: '$USERNAME'. Must be lowercase, start with a letter/underscore, 3-32 chars." 2
    fi

    if id "$USERNAME" &>/dev/null; then
        error_exit "User '$USERNAME' already exists" 1
    fi
}

main() {
    parse_args "$@"
    validate_username

    log "INFO" "===== User creation started: $USERNAME ====="

    if [ "$DRY_RUN" -eq 1 ]; then
        log "INFO" "[DRY RUN] Would create user: $USERNAME (sudo: $GRANT_SUDO)"
        exit 0
    fi

    require_command "useradd"

    if useradd -m -s /bin/bash "$USERNAME"; then
        log "INFO" "User '$USERNAME' created with home directory"
    else
        error_exit "Failed to create user '$USERNAME'" 1
    fi

    if [ "$GRANT_SUDO" -eq 1 ]; then
        usermod -aG sudo "$USERNAME"
        log "INFO" "Granted sudo privileges to '$USERNAME'"
    fi

    log "INFO" "===== User creation finished: $USERNAME ====="
    exit 0
}

main "$@"