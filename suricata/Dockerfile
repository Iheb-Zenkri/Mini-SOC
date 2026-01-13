FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y \
      suricata \
      suricata-update \
      iproute2 \
      jq \
    && rm -rf /var/lib/apt/lists/*

COPY scripts/start_suricata.sh /usr/local/bin/start_suricata.sh
COPY config/suricata.yaml /etc/suricata/suricata.yaml.tpl
COPY config/rules /etc/suricata/rules
RUN chmod +x /usr/local/bin/start_suricata.sh

ENTRYPOINT ["/usr/local/bin/start_suricata.sh"]
