# Suricata Configuration Guide

## Overview

This document describes the configuration of Suricata NIDS for the Mini-SOC platform.

## Main Configuration File

The primary configuration file is `suricata.yaml`. Key sections include:

### Network Variables
```yaml
vars:
  address-groups:
    HOME_NET: "[192.168.0.0/16,10.0.0.0/8,172.16.0.0/12]"
    EXTERNAL_NET: "!$HOME_NET"
```

### Interface Configuration
```yaml
af-packet:
  - interface: eth0
    cluster-id: 99
    cluster-type: cluster_flow
    threads: 2
```

### Logging Configuration
```yaml
logging:
  - eve-log:
      enabled: yes
      filename: eve.json
      types:
        - alert
        - http
        - dns
        - tls
```