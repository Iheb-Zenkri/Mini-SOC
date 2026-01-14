FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV WAZUH_VERSION=4.7

########################################
# 1. Base dependencies
########################################
RUN apt-get update && apt-get install -y \
    curl \
    gnupg2 \
    lsb-release \
    apt-transport-https \
    supervisor \
    procps \
    net-tools \
    python3 \
    python3-pip \
    sudo \
 && rm -rf /var/lib/apt/lists/*

########################################
# 2. Wazuh repository
########################################
RUN curl -fsSL https://packages.wazuh.com/key/GPG-KEY-WAZUH | gpg --dearmor \
    -o /usr/share/keyrings/wazuh.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/wazuh.gpg] \
    https://packages.wazuh.com/4.x/apt stable main" \
    > /etc/apt/sources.list.d/wazuh.list

########################################
# 3. Install Wazuh Manager
########################################
RUN apt-get update && apt-get install -y \
    wazuh-manager \
 && rm -rf /var/lib/apt/lists/*

########################################
# 4. Required directories (defensive)
########################################
RUN mkdir -p \
    /var/ossec/etc/decoders \
    /var/ossec/etc/rules \
    /var/ossec/logs/suricata \
    /var/ossec/api/configuration

########################################
# 5. Configuration templates
########################################
COPY config/wazuh-manager/ossec.conf.template /var/ossec/etc/ossec.conf.template
COPY config/wazuh-manager/ossec.conf /var/ossec/etc/ossec-suricata.conf

########################################
# 6. Custom decoders & rules
########################################
COPY decoders/ /var/ossec/etc/decoders/
COPY rules/ /var/ossec/etc/rules/

########################################
# 7. Supervisor configuration
########################################
COPY config/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

########################################
# 8. Startup script
########################################
COPY scripts/start_wazuh.sh /usr/local/bin/start_wazuh.sh
RUN chmod +x /usr/local/bin/start_wazuh.sh

########################################
# 9. Ports
########################################
EXPOSE 1514/udp 1515/tcp 55000/tcp

########################################
# 10. Healthcheck
########################################
HEALTHCHECK --interval=30s --timeout=10s --retries=5 \
  CMD /var/ossec/bin/ossec-control status || exit 1

########################################
# 11. Entrypoint
########################################
ENTRYPOINT ["/usr/local/bin/start_wazuh.sh"]
