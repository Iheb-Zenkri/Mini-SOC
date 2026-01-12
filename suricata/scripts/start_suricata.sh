#!/bin/bash

# Suricata Startup Script for Docker Containers

set -e

# Default values
INTERFACE=${SURICATA_INTERFACE:-eth0}
CONFIG_FILE=${SURICATA_CONFIG:-/etc/suricata/suricata.yaml}
OPTIONS=${SURICATA_OPTIONS:-""}
LOG_DIR=${SURICATA_LOG_DIR:-/var/log/suricata}
RULES_DIR=${SURICATA_RULES_DIR:-/etc/suricata/rules}

# Create necessary directories
mkdir -p "$LOG_DIR"
mkdir -p "$RULES_DIR"

# Set ownership
chown -R suricata:suricata "$LOG_DIR" || true
chown -R suricata:suricata "$RULES_DIR" || true

# Update HOME_NET if environment variable is set
if [ -n "$HOME_NET" ]; then
    echo "Updating HOME_NET to: $HOME_NET"
    sed -i "s/HOME_NET: .*/HOME_NET: \"$HOME_NET\"/g" "$CONFIG_FILE"
fi

# Update interface in configuration if different
if grep -q "interface: eth0" "$CONFIG_FILE" && [ "$INTERFACE" != "eth0" ]; then
    echo "Updating interface from eth0 to $INTERFACE"
    sed -i "s/interface: eth0/interface: $INTERFACE/g" "$CONFIG_FILE"
fi

# Test configuration before starting
echo "Testing Suricata configuration..."
if suricata -T -c "$CONFIG_FILE"; then
    echo "Configuration test passed"
else
    echo "Configuration test failed!"
    exit 1
fi

# Update rules if needed
if [ "$UPDATE_RULES" = "true" ] || [ "$UPDATE_RULES" = "1" ]; then
    echo "Updating Suricata rules..."
    suricata-update
fi

# Set capabilities for the binary (for packet capture)
if [ "$SET_CAPABILITIES" = "true" ] || [ "$SET_CAPABILITIES" = "1" ]; then
    echo "Setting capabilities on Suricata binary..."
    setcap cap_net_raw,cap_net_admin=eip /usr/bin/suricata || true
fi

# Start Suricata
echo "Starting Suricata on interface: $INTERFACE"
echo "Command: suricata -c $CONFIG_FILE -i $INTERFACE $OPTIONS"

exec suricata -c "$CONFIG_FILE" -i "$INTERFACE" $OPTIONS