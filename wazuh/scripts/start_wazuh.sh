#!/bin/bash
set -e

echo "[+] Initializing Wazuh Manager"

# Apply main config
if [ -f /var/ossec/etc/ossec.conf.template ]; then
  cp /var/ossec/etc/ossec.conf.template /var/ossec/etc/ossec.conf
fi

# Ensure Suricata include exists
if ! grep -q ossec-suricata.conf /var/ossec/etc/ossec.conf; then
  echo '<include>/var/ossec/etc/ossec-suricata.conf</include>' \
    >> /var/ossec/etc/ossec.conf
fi

echo "[+] Starting Supervisor"
exec /usr/bin/supervisord -n
