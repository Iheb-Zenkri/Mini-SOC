#!/bin/bash
# Wazuh Manager Startup Script for Docker Containers (Supervisord version)
set -euo pipefail

# --------------------------
# Environment defaults
# --------------------------
MANAGER_IP=${WAZUH_MANAGER_IP:-0.0.0.0}

# --------------------------
# Logging function
# --------------------------
log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"; }

# --------------------------
# Initialize directories
# --------------------------
log "Initializing Wazuh Manager directories..."
dirs=(
    /var/ossec/api/configuration
    /var/ossec/etc
    /var/ossec/logs
    /var/ossec/queue
    /var/ossec/var/multigroups
    /var/ossec/integrations
    /var/ossec/active-response/bin
    /var/ossec/agentless
    /var/ossec/wodles
)
for d in "${dirs[@]}"; do mkdir -p "$d"; done
chown -R wazuh:wazuh /var/ossec || true

# --------------------------
# Copy template config
# --------------------------
log "Copying Wazuh Manager configuration template..."
cp -n /var/ossec/etc/ossec.conf.template /var/ossec/etc/ossec.conf

# --------------------------
# Configure Wazuh Manager
# --------------------------
log "Configuring Wazuh Manager..."
sed -i "s|<address>.*</address>|<address>${MANAGER_IP}</address>|" /var/ossec/etc/ossec.conf

# --------------------------
# Start supervisord
# --------------------------
log "Starting supervisord to manage Wazuh Manager..."
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
