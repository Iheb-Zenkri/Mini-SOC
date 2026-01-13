# Wazuh Service Setup Guide

This guide provides instructions for deploying and managing your Wazuh manager using either manual installation or Docker Compose.

## Overview

Wazuh is a comprehensive security monitoring platform that provides threat detection, integrity monitoring, incident response, and compliance management capabilities.

![Wazuh Architecture](../docs/architecture/wazuh-architecture.png)

## Prerequisites

- Linux-based operating system
- Root or sudo privileges
- Docker and Docker Compose (for containerized deployment)
- Minimum 4GB RAM and 2 CPU cores recommended

## Installation Methods

### Method 1: Manual Installation

Use the provided installation script for a traditional deployment:

```bash
# Navigate to the scripts directory
cd scripts

# Make the script executable
chmod +x install_wazuh.sh

# Run the installation script
sudo ./install_wazuh.sh
```

The script will handle all necessary dependencies and configuration automatically.

### Method 2: Docker Compose

For containerized deployment with easier management:

```bash
# Start Wazuh services
docker compose up -d

# View running containers
docker compose ps

# View logs
docker compose logs -f

# Stop services
docker compose down

# Stop and remove volumes (caution: deletes data)
docker compose down -v
```

## Installing a Wazuh Agent (Optional)

```bash
# Navigate to the scripts directory
cd scripts

# Make the script executable
chmod +x install_wazuh_agent.sh

# Run the installation script
sudo ./install_wazuh_agent.sh
```

## Common Commands

### Docker Compose Management

```bash
# Restart services
docker compose restart

# Update containers
docker compose pull
docker compose up -d

# Check service status
docker compose ps
```

## Documentation

For detailed documentation, visit: https://documentation.wazuh.com/

## Support

- Official Documentation: https://documentation.wazuh.com/
- Community Support: https://wazuh.com/community/
- GitHub Issues: https://github.com/wazuh/wazuh