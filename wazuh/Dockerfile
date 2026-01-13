# Wazuh Manager Single-Node Dockerfile with Supervisor
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# --------------------------
# 1. Install prerequisites
# --------------------------
RUN apt-get update && \
    apt-get install -y \
        curl \
        apt-transport-https \
        lsb-release \
        gnupg2 \
        python3 \
        python3-pip \
        supervisor \
        procps \
        net-tools \
        sudo \
    && rm -rf /var/lib/apt/lists/*

# --------------------------
# 2. Add Wazuh repository
# --------------------------
RUN curl -fsSL https://packages.wazuh.com/key/GPG-KEY-WAZUH | gpg --dearmor > /usr/share/keyrings/wazuh.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/wazuh.gpg] https://packages.wazuh.com/4.x/apt/ stable main" | tee /etc/apt/sources.list.d/wazuh.list

# --------------------------
# 3. Install Wazuh Manager only
# --------------------------
RUN apt-get update && \
    apt-get install -y \
        wazuh-manager \
    && rm -rf /var/lib/apt/lists/*

# --------------------------
# 4. Create necessary directories for Wazuh Manager
# --------------------------
RUN mkdir -p \
    /var/ossec/api/configuration \
    /var/ossec/etc \
    /var/ossec/logs \
    /var/ossec/queue \
    /var/ossec/var/multigroups \
    /var/ossec/integrations \
    /var/ossec/active-response/bin \
    /var/ossec/agentless \
    /var/ossec/wodles

# --------------------------
# 5. Copy Wazuh Manager configuration template
# --------------------------
COPY config/wazuh-manager/ossec.conf /var/ossec/etc/ossec.conf.template

# --------------------------
# 6. Supervisor configuration
# --------------------------
COPY config/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# --------------------------
# 7. Startup script
# --------------------------
COPY scripts/start_wazuh.sh /usr/local/bin/start_wazuh.sh
RUN chmod +x /usr/local/bin/start_wazuh.sh

# --------------------------
# 8. Expose Wazuh Manager ports
# --------------------------
EXPOSE 1514/udp 1515/tcp 55000/tcp

# --------------------------
# 9. Healthcheck (Manager)
# --------------------------
HEALTHCHECK --interval=30s --timeout=10s --retries=3 \
  CMD /var/ossec/bin/ossec-control status || exit 1

# --------------------------
# 10. Entrypoint
# --------------------------
ENTRYPOINT ["/usr/local/bin/start_wazuh.sh"]
