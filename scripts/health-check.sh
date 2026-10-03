#!/bin/bash
# health-check.sh — checks CPU, memory, and disk usage, reports pass/fail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TOOLKIT_DIR="$SCRIPT_DIR"
source "$SCRIPT_DIR/config/cloudops.conf"
source "$SCRIPT_DIR/lib/common.sh"
TOOLKIT_DIR="$SCRIPT_DIR"

check_cpu() {
    local cpu_idle1 cpu_total1 cpu_idle2 cpu_total2 cpu_usage

    read -r _ user1 nice1 system1 idle1 iowait1 irq1 softirq1 _ < /proc/stat
    cpu_idle1=$((idle1 + iowait1))
    cpu_total1=$((user1 + nice1 + system1 + idle1 + iowait1 + irq1 + softirq1))

    sleep 1

    read -r _ user2 nice2 system2 idle2 iowait2 irq2 softirq2 _ < /proc/stat
    cpu_idle2=$((idle2 + iowait2))
    cpu_total2=$((user2 + nice2 + system2 + idle2 + iowait2 + irq2 + softirq2))

    local total_diff=$((cpu_total2 - cpu_total1))
    local idle_diff=$((cpu_idle2 - cpu_idle1))

    cpu_usage=$(( (100 * (total_diff - idle_diff)) / total_diff ))

    log "INFO" "CPU usage: ${cpu_usage}%"
    echo "$cpu_usage"
}


check_memory() {
    local mem_total mem_available mem_used_percent

    mem_total=$(awk '/^MemTotal:/ {print $2}' /proc/meminfo)
    mem_available=$(awk '/^MemAvailable:/ {print $2}' /proc/meminfo)

    mem_used_percent=$(( (100 * (mem_total - mem_available)) / mem_total ))

    log "INFO" "Memory usage: ${mem_used_percent}%"
    echo "$mem_used_percent"
}


check_disk() {
    local disk_usage_percent

    disk_usage_percent=$(df / | awk 'NR==2 {gsub("%","",$5); print $5}')

    log "INFO" "Disk usage (/): ${disk_usage_percent}%"

    if [ "$disk_usage_percent" -ge "$DISK_ALERT_THRESHOLD" ]; then
        log "WARN" "Disk usage ${disk_usage_percent}% exceeds threshold ${DISK_ALERT_THRESHOLD}%"
    fi

    echo "$disk_usage_percent"
}


main() {
    log "INFO" "===== Health check started ====="

    local cpu_usage memory_usage disk_usage
    local overall_status="PASS"

    cpu_usage=$(check_cpu)
    memory_usage=$(check_memory)
    disk_usage=$(check_disk)

    if [ "$disk_usage" -ge "$DISK_ALERT_THRESHOLD" ]; then
        overall_status="FAIL"
    fi

    echo ""
    echo "===== Health Check Summary ====="
    echo "CPU Usage:     ${cpu_usage}%"
    echo "Memory Usage:  ${memory_usage}%"
    echo "Disk Usage:    ${disk_usage}%  (threshold: ${DISK_ALERT_THRESHOLD}%)"
    echo "Overall:       ${overall_status}"
    echo "================================="

    log "INFO" "===== Health check finished — status: $overall_status ====="

    if [ "$overall_status" == "FAIL" ]; then
        exit 4
    else
        exit 0
    fi
}

main "$@"
