#!/bin/bash
# Suricata Universal Installer & Auto-Configurator (Ubuntu/Debian)
# One-shot script for VM / bare-metal IDS deployment

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

### ---------- Detect primary interface ----------
INTERFACE=$(ip route | awk '/default/ {print $5}' | head -n1)
[[ -n "$INTERFACE" ]] || err "Could not detect network interface"

log "Detected interface: $INTERFACE"

### ---------- Detect HOME_NET ----------
CIDR=$(ip route | awk '/src/ {print $1}' | head -n1)
[[ -n "$CIDR" ]] || CIDR="192.168.0.0/16"

HOME_NET="[$CIDR]"
log "Detected HOME_NET: $HOME_NET"

### ---------- Install Suricata ----------
log "Installing Suricata..."
apt-get update -qq
apt-get install -y software-properties-common gnupg2 curl jq

add-apt-repository -y ppa:oisf/suricata-stable
apt-get update -qq
apt-get install -y suricata suricata-update

### ---------- Backup config ----------
CFG="/etc/suricata/suricata.yaml"
[[ -f $CFG ]] || err "suricata.yaml not found"

cp "$CFG" "${CFG}.bak.$(date +%s)"
log "Backup created"

### ---------- Configure HOME_NET ----------
sed -i \
  -E "s|HOME_NET:.*|HOME_NET: \"$HOME_NET\"|g" \
  "$CFG"

### ---------- Configure interface (af-packet) ----------
if grep -q "af-packet:" "$CFG"; then
  sed -i -E "/af-packet:/,/^[^ ]/c\
af-packet:\n  - interface: $INTERFACE\n    threads: auto\n    cluster-id: 99\n    cluster-type: cluster_flow\n    defrag: yes" \
  "$CFG"
else
  err "af-packet section missing in suricata.yaml"
fi

### ---------- Ensure logging ----------
grep -q "eve-log:" "$CFG" || err "eve-log missing in config"

### ---------- Update rules ----------
log "Updating rules..."
suricata-update enable-source et/open
suricata-update

### ---------- Validate configuration ----------
log "Validating configuration..."
suricata -T -c "$CFG" || err "Configuration test failed"

### ---------- Enable & start service ----------
log "Starting Suricata..."
systemctl enable suricata
systemctl restart suricata

sleep 2
systemctl is-active --quiet suricata || err "Suricata failed to start"

### ---------- Final output ----------
log "Suricata is running successfully"
log "Interface : $INTERFACE"
log "HOME_NET  : $HOME_NET"
log "Logs      : /var/log/suricata/"
log "EVE JSON  : /var/log/suricata/eve.json"
