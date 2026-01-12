# Mini-SOC Platform: Suricata + Wazuh + Elastic Stack

A complete, modular, and containerized Security Operations Center (SOC) platform for intrusion detection, log correlation, and security monitoring.

## 📋 Project Overview

This project implements a Mini-SOC platform with:
- **Suricata** as Network Intrusion Detection System (NIDS)
- **Wazuh** as Host-based Intrusion Detection System (HIDS) and SIEM
- **Elastic Stack** (Elasticsearch, Logstash, Kibana) for log centralization and visualization
- **Automated deployment** via Docker containers and installation scripts
- **Pre-configured dashboards** for security monitoring
- **Attack simulation** environment for testing and validation

## 🏗️ Architecture
![SOC Architecture](/docs/architecture/Global_Architecture.png)

## 🚀 Quick Start

```bash
# Clone the repository
git clone https://github.com/your-username/mini-soc-platform.git
cd mini-soc-platform
