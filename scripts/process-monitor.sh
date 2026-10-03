#!/bin/bash
# process-monitor.sh — reports top CPU/memory processes and total process count

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TOOLKIT_DIR="$SCRIPT_DIR"
source "$SCRIPT_DIR/config/cloudops.conf"
source "$SCRIPT_DIR/lib/common.sh"
TOOLKIT_DIR="$SCRIPT_DIR"
top_cpu_processes() {
    log "INFO" "Fetching top 5 CPU-consuming processes"
    ps -eo pid,comm,%cpu --sort=-%cpu | head -n 6
}

top_memory_processes() {
    log "INFO" "Fetching top 5 memory-consuming processes"
    ps -eo pid,comm,%mem --sort=-%mem | head -n 6
}

total_process_count() {
    local count
    count=$(ps -e --no-headers | wc -l)
    log "INFO" "Total running processes: $count"
    echo "$count"
}

main() {
    log "INFO" "===== Process monitor started ====="

    echo ""
    echo "===== Top 5 CPU-consuming processes ====="
    top_cpu_processes

    echo ""
    echo "===== Top 5 Memory-consuming processes ====="
    top_memory_processes

    local total
    total=$(total_process_count)
    echo ""
    echo "Total running processes: $total"

    log "INFO" "===== Process monitor finished ====="
    exit 0
}

main "$@"