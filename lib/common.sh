#!/bin/bash
# common.sh — shared functions for the Linux Server Automation Toolkit
# This file is sourced by every script in scripts/, never run directly.

log() {
    local level="$1"
    local message="$2"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
   echo "[$timestamp] [$level] $message" | tee -a "$LOG_DIR/cloudops.log" >&2
}


# --- Exit code conventions ---
# 0 = success
# 1 = general error (unexpected failure)
# 2 = invalid usage / bad arguments
# 3 = missing dependency or required file
# 4 = threshold breached (e.g. disk alert triggered) — not necessarily a bug, but actionable

error_exit() {
    local message="$1"
    local exit_code="${2:-1}"   # default to 1 if no code given
    log "ERROR" "$message"
    exit "$exit_code"
}



require_command() {
    local cmd="$1"
    if ! command -v "$cmd" &> /dev/null; then
        error_exit "Required command '$cmd' not found. Please install it." 3
    fi
}