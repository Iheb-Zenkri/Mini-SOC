# Suricata NIDS - Network Intrusion Detection System

This module deploys Suricata as a Network Intrusion Detection System (NIDS) for monitoring network traffic and detecting security threats.

## 📋 Features

- Real-time network traffic analysis
- Signature-based intrusion detection
- Protocol analysis and anomaly detection
- JSON (EVE) output format
- Integration with Elastic Stack
- Custom rule support
- Automated rule updates

## 🚀 Quick Start

### Using Docker (Recommended)

```bash
# Build and run Suricata container
docker-compose -f docker-compose.yml up --build -d

# View logs
docker logs suricata -f
```
### Manual Installation
```bash
# Run installation script
chmod +x scripts/install_suricata.sh
sudo ./scripts/install_suricata.sh

# Start Suricata
sudo systemctl start suricata
```

## 🛠️ Configuration

### 📄 Main Configuration File

**Location:**  
`config/suricata.yaml`

This file defines the core behavior of the Suricata engine.

#### 🔑 Key Sections

- **`vars`**  
  Network variables and the `HOME_NET` definition.

- **`af-packet`**  
  Interface configuration for high-performance packet capture.

- **`outputs`**  
  Logging configuration, including **EVE JSON** output for SIEM integration.

- **`rules`**  
  Rule loading, categorization, and management.

---

### 🧩 Custom Rules

Add custom detection rules to: config/rules/local.rules

#### ✏️ Example Rule

```suricata
alert tcp any any -> $HOME_NET 22 (
  msg:"SSH Brute Force Attempt";
  flow:to_server;
  threshold:type threshold, track by_src, count 5, seconds 60;
  sid:1000001;
  rev:1;
)
```




