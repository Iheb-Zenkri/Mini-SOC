# Wazuh Service Setup Guide

This guide provides instructions for deploying and managing your Wazuh service using either manual installation or Docker Compose.

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

## Accessing Wazuh

After installation, access the Wazuh dashboard:

- **URL**: `https://localhost` or `https://<your-server-ip>`
- **Default credentials**: Check the installation output or docker compose logs for credentials

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

### Service Health Check

```bash
# Check if services are running
curl -k https://localhost

# View container resource usage
docker stats
```

## Troubleshooting

- **Port conflicts**: Ensure ports 443, 1514, 1515, and 55000 are available
- **Permission issues**: Run installation commands with sudo
- **Container issues**: Check logs with `docker compose logs`
- **Memory issues**: Ensure adequate system resources are available

## Next Steps

1. Change default credentials immediately after first login
2. Configure agents to connect to your Wazuh manager
3. Review and customize security rules
4. Set up alerting and notification channels

## Documentation

For detailed documentation, visit: https://documentation.wazuh.com/

## Support

- Official Documentation: https://documentation.wazuh.com/
- Community Support: https://wazuh.com/community/
- GitHub Issues: https://github.com/wazuh/wazuh