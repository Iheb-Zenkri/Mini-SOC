#!/bin/bash

# Suricata Monitoring Script
# Monitors Suricata service, logs, and performance

set -e

# Configuration
LOG_DIR="/var/log/suricata"
CONFIG_FILE="/etc/suricata/suricata.yaml"
ALERT_LOG="$LOG_DIR/fast.log"
EVE_LOG="$LOG_DIR/eve.json"
STATUS_FILE="/tmp/suricata_status.json"
CHECK_INTERVAL=60  # seconds
ALERT_THRESHOLD=100  # alerts per minute
CPU_THRESHOLD=80     # CPU percentage
MEMORY_THRESHOLD=512 # Memory in MB

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Log function
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a /var/log/suricata-monitor.log
}

# Check if Suricata process is running
check_process() {
    if pgrep -x "suricata" > /dev/null; then
        echo -e "${GREEN}Suricata process is running${NC}"
        return 0
    else
        echo -e "${RED}Suricata process is NOT running${NC}"
        return 1
    fi
}

# Check Suricata service status
check_service() {
    if systemctl is-active --quiet suricata; then
        echo -e "${GREEN}Suricata service is active${NC}"
        return 0
    else
        echo -e "${RED}Suricata service is NOT active${NC}"
        return 1
    fi
}

# Check log file growth
check_logs() {
    if [ -f "$ALERT_LOG" ]; then
        log_size=$(du -h "$ALERT_LOG" | cut -f1)
        log_lines=$(wc -l < "$ALERT_LOG" 2>/dev/null || echo "0")
        echo -e "${BLUE}Alert log: $log_size, $log_lines lines${NC}"
        
        # Check recent alert rate
        if [ $log_lines -gt 0 ]; then
            recent_alerts=$(tail -n 100 "$ALERT_LOG" | wc -l)
            echo -e "${BLUE}Recent alerts (last 100 lines): $recent_alerts${NC}"
            
            if [ $recent_alerts -gt $ALERT_THRESHOLD ]; then
                echo -e "${YELLOW}Warning: High alert rate detected${NC}"
                return 2
            fi
        fi
        return 0
    else
        echo -e "${YELLOW}Warning: Alert log not found${NC}"
        return 1
    fi
}

# Check resource usage
check_resources() {
    if pgrep -x "suricata" > /dev/null; then
        pid=$(pgrep -x "suricata" | head -n1)
        
        # CPU usage
        cpu_usage=$(ps -p $pid -o %cpu --no-headers 2>/dev/null | awk '{print int($1)}')
        if [ -n "$cpu_usage" ]; then
            echo -e "${BLUE}CPU usage: ${cpu_usage}%${NC}"
            if [ $cpu_usage -gt $CPU_THRESHOLD ]; then
                echo -e "${YELLOW}Warning: High CPU usage${NC}"
            fi
        fi
        
        # Memory usage
        mem_usage=$(ps -p $pid -o rss --no-headers 2>/dev/null | awk '{print int($1/1024)}')
        if [ -n "$mem_usage" ]; then
            echo -e "${BLUE}Memory usage: ${mem_usage}MB${NC}"
            if [ $mem_usage -gt $MEMORY_THRESHOLD ]; then
                echo -e "${YELLOW}Warning: High memory usage${NC}"
            fi
        fi
        
        # Thread count
        threads=$(ps -L -p $pid | wc -l)
        echo -e "${BLUE}Thread count: $((threads - 1))${NC}"
    fi
}

# Check rule updates
check_rules() {
    rules_dir="/etc/suricata/rules"
    if [ -d "$rules_dir" ]; then
        rule_count=$(find "$rules_dir" -name "*.rules" | wc -l)
        last_update=$(find "$rules_dir" -name "*.rules" -exec stat -c %Y {} \; | sort -n | tail -1)
        current_time=$(date +%s)
        days_since_update=$(( (current_time - last_update) / 86400 ))
        
        echo -e "${BLUE}Rule files: $rule_count${NC}"
        echo -e "${BLUE}Days since last update: $days_since_update${NC}"
        
        if [ $days_since_update -gt 7 ]; then
            echo -e "${YELLOW}Warning: Rules are older than 7 days${NC}"
            return 1
        fi
    fi
}

# Generate status JSON
generate_status() {
    status=$({
        echo "{"
        echo "  \"timestamp\": \"$(date -Iseconds)\","
        echo "  \"process_running\": $(check_process > /dev/null 2>&1 && echo "true" || echo "false"),"
        echo "  \"service_active\": $(check_service > /dev/null 2>&1 && echo "true" || echo "false"),"
        echo "  \"alert_count\": $(tail -n 100 "$ALERT_LOG" 2>/dev/null | wc -l || echo "0"),"
        echo "  \"log_size\": \"$(du -h "$ALERT_LOG" 2>/dev/null | cut -f1 || echo "0")\""
        echo "}"
    } 2>/dev/null)
    
    echo "$status" > "$STATUS_FILE"
}

# Send alert (placeholder for email/webhook integration)
send_alert() {
    local message="$1"
    log_message "ALERT: $message"
    
    # Example: Send to syslog
    logger -t suricata-monitor "ALERT: $message"
    
    # TODO: Add email/webhook integration here
    # curl -X POST -H "Content-Type: application/json" \
    #      -d "{\"text\":\"$message\"}" \
    #      https://hooks.slack.com/services/XXX/YYY/ZZZ
}

# Main monitoring function
monitor() {
    log_message "Starting Suricata monitoring"
    
    while true; do
        echo ""
        echo "=" * 60
        echo "Suricata Monitoring - $(date)"
        echo "=" * 60
        
        # Run checks
        echo -e "\n${BLUE}[1/5] Checking process...${NC}"
        if ! check_process; then
            send_alert "Suricata process is not running"
        fi
        
        echo -e "\n${BLUE}[2/5] Checking service...${NC}"
        if ! check_service; then
            send_alert "Suricata service is not active"
        fi
        
        echo -e "\n${BLUE}[3/5] Checking logs...${NC}"
        check_logs
        log_result=$?
        if [ $log_result -eq 2 ]; then
            send_alert "High alert rate detected"
        fi
        
        echo -e "\n${BLUE}[4/5] Checking resources...${NC}"
        check_resources
        
        echo -e "\n${BLUE}[5/5] Checking rules...${NC}"
        check_rules
        
        # Generate status file
        generate_status
        
        echo -e "\n${GREEN}Monitoring cycle completed. Next check in ${CHECK_INTERVAL} seconds.${NC}"
        sleep $CHECK_INTERVAL
    done
}

# Start/stop/status commands
case "$1" in
    start)
        echo "Starting Suricata monitor..."
        monitor &
        echo $! > /var/run/suricata-monitor.pid
        ;;
    stop)
        if [ -f /var/run/suricata-monitor.pid ]; then
            pid=$(cat /var/run/suricata-monitor.pid)
            kill $pid
            rm /var/run/suricata-monitor.pid
            echo "Stopped Suricata monitor"
        else
            echo "Suricata monitor is not running"
        fi
        ;;
    status)
        if [ -f /var/run/suricata-monitor.pid ]; then
            pid=$(cat /var/run/suricata-monitor.pid)
            if ps -p $pid > /dev/null; then
                echo "Suricata monitor is running (PID: $pid)"
                if [ -f "$STATUS_FILE" ]; then
                    cat "$STATUS_FILE" | python3 -m json.tool 2>/dev/null || cat "$STATUS_FILE"
                fi
            else
                echo "Suricata monitor PID file exists but process is not running"
            fi
        else
            echo "Suricata monitor is not running"
        fi
        ;;
    *)
        echo "Usage: $0 {start|stop|status}"
        echo ""
        echo "Manual check:"
        check_process
        check_service
        check_logs
        check_resources
        check_rules
        exit 1
        ;;
esac