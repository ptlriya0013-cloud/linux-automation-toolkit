#!/bin/bash
# disk-alert.sh — checks disk usage across mount points, alerts if any exceed threshold
# Designed to run frequently via cron; stays quiet unless there's a problem.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TOOLKIT_DIR="$SCRIPT_DIR"
source "$SCRIPT_DIR/config/cloudops.conf"
source "$SCRIPT_DIR/lib/common.sh"
TOOLKIT_DIR="$SCRIPT_DIR"

main() {
    local alert_triggered=0

    while read -r usage mount; do
        usage="${usage%\%}"   # strip trailing % if present

        if [ "$usage" -ge "$DISK_ALERT_THRESHOLD" ]; then
            log "WARN" "Disk alert: $mount is at ${usage}% (threshold ${DISK_ALERT_THRESHOLD}%)"
            alert_triggered=1
        fi
    done < <(df -h --output=pcent,target -x tmpfs -x devtmpfs | tail -n +2 | tr -d ' ' | sed 's/%/ /')

    if [ "$alert_triggered" -eq 1 ]; then
        log "WARN" "disk-alert.sh completed — one or more mount points exceeded threshold"
        exit 4
    else
        log "INFO" "disk-alert.sh completed — all mount points within threshold"
        exit 0
    fi
}

main "$@"