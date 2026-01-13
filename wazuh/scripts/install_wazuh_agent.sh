#!/bin/bash
# Wazuh Agent Installer
# Install and register agent with Wazuh Manager

set -euo pipefail

### ---------- Helpers ----------
log() { echo "[+] $1"; }
warn() { echo "[!] $1"; }
err() { echo "[X] $1" >&2; exit 1; }

### ---------- Root check ----------
[[ $EUID -eq 0 ]] || err "Run as root"

### ---------- Parameters ----------
WAZUH_MANAGER=${1:-""}
AGENT_NAME=${2:-"$(hostname)"}
AGENT_GROUP=${3:-"default"}

if [[ -z "$WAZUH_MANAGER" ]]; then
    echo "Usage: $0 <wazuh_manager_ip> [agent_name] [agent_group]"
    echo "Example: $0 192.168.1.100 my-server production"
    exit 1
fi

### ---------- OS check ----------
. /etc/os-release || err "Cannot detect OS"

log "Detected OS: $PRETTY_NAME"

### ---------- Install prerequisites ----------
log "Installing prerequisites..."
apt-get update -qq
apt-get install -y curl apt-transport-https lsb-release gnupg2

### ---------- Add Wazuh repository ----------
log "Adding Wazuh repository..."
curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | gpg --dearmor > /usr/share/keyrings/wazuh.gpg
echo "deb [signed-by=/usr/share/keyrings/wazuh.gpg] https://packages.wazuh.com/4.x/apt/ stable main" | tee /etc/apt/sources.list.d/wazuh.list

### ---------- Install Wazuh Agent ----------
log "Installing Wazuh Agent..."
apt-get update -qq
apt-get install -y wazuh-agent

### ---------- Configure Agent ----------
log "Configuring agent to connect to ${WAZUH_MANAGER}..."
sed -i "s/MANAGER_IP/${WAZUH_MANAGER}/g" /var/ossec/etc/ossec.conf
sed -i "s/<agent_name>.*<\/agent_name>/<agent_name>${AGENT_NAME}<\/agent_name>/g" /var/ossec/etc/ossec.conf
sed -i "s/<agent_config profile=.*\/>/<agent_config profile=\"${AGENT_GROUP}\"\/>/g" /var/ossec/etc/ossec.conf

### ---------- Start and enroll Agent ----------
log "Starting Wazuh Agent..."
systemctl daemon-reload
systemctl enable wazuh-agent

# If agent is already registered, just start it
if [[ -f /var/ossec/etc/client.keys ]]; then
    log "Agent already registered, restarting..."
    systemctl restart wazuh-agent
else
    log "Registering agent with manager..."
    /var/ossec/bin/agent-auth -m ${WAZUH_MANAGER} -A ${AGENT_NAME} -G ${AGENT_GROUP}
    systemctl start wazuh-agent
fi

### ---------- Final output ----------
log "==============================================="
log "Wazuh Agent installation completed!"
log "==============================================="
log "Agent Name: ${AGENT_NAME}"
log "Agent Group: ${AGENT_GROUP}"
log "Manager IP: ${WAZUH_MANAGER}"
log "Agent Status: $(systemctl is-active wazuh-agent)"
log ""
log "Agent files:"
log "  Configuration: /var/ossec/etc/ossec.conf"
log "  Logs: /var/ossec/logs/"
log "  Binary: /var/ossec/bin/"
log "==============================================="