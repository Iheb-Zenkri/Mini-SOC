#!/bin/bash

# Suricata Startup Script for Docker Containers

set -e

# Default values
INTERFACE=${SURICATA_INTERFACE:-eth0}
CONFIG_FILE=/etc/suricata/suricata.yaml
TEMPLATE=/etc/suricata/suricata.yaml.tpl
LOG_DIR=/var/log/suricata
OPTIONS=${SURICATA_OPTIONS:-""}
UPDATE_RULES=${SURICATA_UPDATE_RULES:-"false"}
SET_CAPABILITIES=${SURICATA_SET_CAPABILITIES:-"false"}

# Create necessary directories
mkdir -p "$LOG_DIR"
chown -R root:root "$LOG_DIR"
chmod -R 755 "$LOG_DIR"


# Copy template to runtime config
if [ -f "$TEMPLATE" ]; then
    cp "$TEMPLATE" "$CONFIG_FILE"
else
    echo "Template not found: $TEMPLATE"
    exit 1
fi

# Update HOME_NET if environment variable is set
if [ -n "$HOME_NET" ]; then
    echo "Updating HOME_NET to: $HOME_NET"
    sed -i "s|^HOME_NET:.*|HOME_NET: \"$HOME_NET\"|g" "$CONFIG_FILE"
fi

# Update interface in configuration if different
if grep -q "interface: eth0" "$CONFIG_FILE" && [ "$INTERFACE" != "eth0" ]; then
    echo "Updating interface from eth0 to $INTERFACE"
    sed -i "s/interface: eth0/interface: $INTERFACE/g" "$CONFIG_FILE"
fi

# Update rules if needed
mkdir -p /etc/suricata/rules
touch /etc/suricata/rules/local.rules
touch /etc/suricata/rules/suricata.rules
if [ "$UPDATE_RULES" = "true" ] || [ "$UPDATE_RULES" = "1" ]; then
    echo "Updating Suricata rules..."
    suricata-update
fi

# Test configuration before starting
echo "Testing Suricata configuration..."
if suricata -T -c "$CONFIG_FILE"; then
    echo "Configuration test passed"
else
    echo "Configuration test failed!"
    exit 1
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