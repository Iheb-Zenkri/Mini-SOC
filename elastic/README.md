# Elastic Stack for Mini-SOC

This directory contains the Elastic Stack configuration for the Mini-SOC project, including Elasticsearch, Kibana, Logstash, and Filebeat.

## Overview

The Elastic Stack is used for centralized log aggregation, analysis, and visualization. It collects logs from various security tools (Suricata, Wazuh) and provides a unified dashboard for monitoring and investigation.

### Components

- **Elasticsearch**: Search and analytics engine for storing and querying logs
- **Kibana**: Visualization and exploration platform for Elasticsearch data
- **Logstash**: Log processing and forwarding pipeline
- **Filebeat**: Lightweight log shipper for sending logs to Logstash/Elasticsearch

## Prerequisites

- Docker and Docker Compose installed
- Sufficient disk space for log storage (recommend 10GB+)
- Port availability: 5601 (Kibana), 9200 (Elasticsearch), 5000 (Logstash)

## Quick Start

### Option 1: Docker Compose (Recommended)

#### 1. Build and Start Services

```bash
docker compose build
docker compose up -d
```

#### 2. Verify Services

```bash
# Check if containers are running
docker compose ps

# Test Elasticsearch connectivity
curl http://localhost:9200

# Access Kibana
open http://localhost:5601
```

### Option 2: Manual Installation

For manual installation on your host system without Docker:

#### Prerequisites
- Java Development Kit (JDK) 11 or higher
- 2GB RAM minimum (4GB+ recommended)
- Available disk space for logs and indexes

#### Installation Steps

```bash
# Make the script executable
chmod +x scripts/install_elastic.sh

# Run the installation script
./scripts/install_elastic.sh
```

The script will:
1. Download Elasticsearch, Kibana, Logstash, and Filebeat
2. Install necessary dependencies
3. Configure services
4. Set up systemd services for automatic startup

#### Manual Configuration

After installation, edit the configuration files:
- `configs/elasticsearch.yml` - Elasticsearch configuration
- `configs/kibana.yml` - Kibana configuration
- `configs/logstash.conf` - Logstash pipeline
- `configs/filebeat.yml` - Filebeat configuration

#### Start Services Manually

```bash
# Start Elasticsearch
elasticsearch -d

# Start Kibana
kibana &

# Start Logstash
logstash -f configs/logstash.conf &

# Start Filebeat
filebeat -c configs/filebeat.yml &
```

Or use systemd if services were installed:

```bash
sudo systemctl start elasticsearch
sudo systemctl start kibana
sudo systemctl start logstash
sudo systemctl start filebeat
```

## Configuration Files

### `elasticsearch.yml`
Main Elasticsearch configuration including:
- Cluster settings
- Network configuration
- Security settings (if applicable)

### `kibana.yml`
Kibana configuration for:
- Elasticsearch connection
- Server settings
- Plugin configuration

### `logstash.conf`
Log processing pipeline configuration:
- Input sources (Filebeat)
- Filters and transformations
- Output destinations

### `filebeat.yml`
Filebeat configuration for:
- Log file paths to monitor
- Output destinations (Logstash/Elasticsearch)
- Processing options

## Accessing the Stack

- **Kibana UI**: http://localhost:5601
- **Elasticsearch API**: http://localhost:9200
- **Logstash Beats Input**: localhost:5000

## Managing Services

### View Logs
```bash
# View service logs
docker compose logs -f

# View specific service logs
docker compose logs -f elasticsearch
docker compose logs -f kibana
```

### Stop Services
```bash
docker compose down
```

### Remove Volumes (WARNING: Deletes data)
```bash
docker compose down -v
```

## Integration with Other Components

- **Suricata**: Filebeat collects IDS alerts and forwards to Logstash
- **Wazuh**: Logs are collected and indexed in Elasticsearch for centralized analysis

## References

- [Elasticsearch Documentation](https://www.elastic.co/guide/en/elasticsearch/reference/current/index.html)
- [Kibana Documentation](https://www.elastic.co/guide/en/kibana/current/index.html)
- [Logstash Documentation](https://www.elastic.co/guide/en/logstash/current/index.html)
- [Filebeat Documentation](https://www.elastic.co/guide/en/beats/filebeat/current/index.html)
