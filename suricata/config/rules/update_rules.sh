#!/bin/bash

# Suricata Rule Update Script
# Updates Emerging Threats and OISF rules

set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}[*] Starting Suricata rule update...${NC}"

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}[!] This script must be run as root${NC}"
    exit 1
fi

# Backup current rules
echo "[*] Backing up current rules..."
backup_dir="/etc/suricata/rules/backup_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$backup_dir"
cp /etc/suricata/rules/*.rules "$backup_dir/" 2>/dev/null || true

# Update Suricata rules
echo "[*] Updating rules from sources..."
suricata-update

# Enable additional rule sources
echo "[*] Enabling rule sources..."
suricata-update enable-source et/open
suricata-update enable-source oisf/trafficid
suricata-update enable-source et/pro

# List enabled sources
echo "[*] Current rule sources:"
suricata-update list-sources

# Update again with all sources
suricata-update

# Check if custom rules exist and preserve them
if [ -f "/etc/suricata/rules/local.rules" ]; then
    echo "[*] Preserving custom local rules..."
    cp /etc/suricata/rules/local.rules /tmp/local.rules.bak
    suricata-update --no-merge
    cp /tmp/local.rules.bak /etc/suricata/rules/local.rules
    rm /tmp/local.rules.bak
fi

# Test configuration
echo "[*] Testing Suricata configuration..."
if suricata -T -c /etc/suricata/suricata.yaml; then
    echo -e "${GREEN}[*] Configuration test passed${NC}"
    
    # Reload Suricata if running
    if systemctl is-active --quiet suricata; then
        echo "[*] Reloading Suricata..."
        systemctl reload suricata
        echo -e "${GREEN}[*] Suricata reloaded with new rules${NC}"
    fi
else
    echo -e "${RED}[!] Configuration test failed, restoring backup${NC}"
    cp "$backup_dir"/*.rules /etc/suricata/rules/ 2>/dev/null || true
    exit 1
fi

echo -e "${GREEN}[*] Rule update completed successfully!${NC}"
echo "[*] Backup saved in: $backup_dir"
echo "[*] Rules directory: /etc/suricata/rules/"