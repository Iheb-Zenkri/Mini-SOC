#!/bin/bash
# Wazuh Manager Universal Installer & Auto-Configurator (Ubuntu/Debian)
# One-shot script for VM / bare-metal deployment (Manager only)

set -euo pipefail

### ---------- Helpers ----------
log() { echo "[+] $1"; }
warn() { echo "[!] $1"; }
err() { echo "[X] $1" >&2; exit 1; }

### ---------- Root check ----------
[[ $EUID -eq 0 ]] || err "Run as root"

### ---------- OS check ----------
. /etc/os-release || err "Cannot detect OS"
[[ "$ID" =~ (ubuntu|debian) ]] || err "Unsupported OS: $ID"
log "Detected OS: $PRETTY_NAME"

### ---------- Detect IP address ----------
IP_ADDRESS=$(hostname -I | awk '{print $1}')
[[ -n "$IP_ADDRESS" ]] || err "Could not detect IP address"
log "Detected IP address: $IP_ADDRESS"

### ---------- Install prerequisites ----------
log "Installing prerequisites..."
apt-get update -qq
apt-get install -y curl apt-transport-https lsb-release gnupg2 sudo

### ---------- Add Wazuh repository ----------
log "Adding Wazuh repository..."
curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | gpg --dearmor > /usr/share/keyrings/wazuh.gpg
echo "deb [signed-by=/usr/share/keyrings/wazuh.gpg] https://packages.wazuh.com/4.x/apt/ stable main" | tee /etc/apt/sources.list.d/wazuh.list

### ---------- Install Wazuh Manager ----------
log "Installing Wazuh Manager..."
apt-get update -qq
apt-get install -y wazuh-manager

### ---------- Start Wazuh Manager ----------
log "Starting Wazuh Manager..."
systemctl daemon-reload
systemctl enable wazuh-manager
systemctl start wazuh-manager

### ---------- Final output ----------
log "==============================================="
log "Wazuh Manager installation completed successfully!"
log "==============================================="
log "Manager IP: ${IP_ADDRESS}"
log ""
log "Service status:"
log "  Wazuh Manager: $(systemctl is-active wazuh-manager)"
log ""
log "First steps:"
log "1. Configure /var/ossec/etc/ossec.conf according to your environment"
log "2. Add agents using Wazuh agent registration"
log "==============================================="
