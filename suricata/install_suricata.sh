#!/bin/bash

# Suricata Installation Script for Ubuntu/Debian
# Part of Mini-SOC Platform

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}[*]${NC} $1"
}

print_error() {
    echo -e "${RED}[!]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    print_error "This script must be run as root"
    exit 1
fi

# Detect distribution
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$NAME
    VER=$VERSION_ID
else
    print_error "Cannot detect OS version"
    exit 1
fi

print_status "Detected OS: $OS $VER"

# Install Suricata based on OS
install_suricata() {
    print_status "Installing Suricata NIDS..."
    
    case $OS in
        *Ubuntu*|*Debian*)
            # Add Suricata repository
            apt-get update
            apt-get install -y software-properties-common gnupg2 wget
            add-apt-repository -y ppa:oisf/suricata-stable
            
            # Update and install
            apt-get update
            apt-get install -y suricata suricata-update
            
            # Install dependencies
            apt-get install -y jq curl libpcre3 libpcre3-dbg libyaml-0-2 \
                libcap-ng-dev libcap-ng0 libmagic-dev libjansson-dev \
                libpcap-dev libnet1-dev libnetfilter-queue-dev \
                libnetfilter-queue1 libnfnetlink-dev libnfnetlink0
            ;;
        
        *CentOS*|*Red*Hat*|*Fedora*)
            # EPEL repository
            yum install -y epel-release
            
            # Install Suricata
            yum install -y suricata suricata-update
            
            # Install dependencies
            yum install -y jq curl libpcap libpcap-devel libnet libnet-devel \
                libyaml libyaml-devel jansson jansson-devel \
                libcap-ng libcap-ng-devel libnetfilter_queue \
                libnetfilter_queue-devel
            ;;
        
        *)
            print_error "Unsupported OS: $OS"
            exit 1
            ;;
    esac
    
    print_status "Suricata installation completed"
}

# Configure Suricata
configure_suricata() {
    print_status "Configuring Suricata..."
    
    # Backup original config
    if [ -f /etc/suricata/suricata.yaml ]; then
        cp /etc/suricata/suricata.yaml /etc/suricata/suricata.yaml.backup
    fi
    
    # Copy our configuration
    if [ -f "config/suricata.yaml" ]; then
        cp config/suricata.yaml /etc/suricata/suricata.yaml
        print_status "Configuration file copied"
    else
        print_warning "Custom configuration not found, using default"
    fi
    
    # Copy custom rules
    if [ -f "config/rules/local.rules" ]; then
        cp config/rules/local.rules /etc/suricata/rules/
        print_status "Custom rules copied"
    fi
    
    # Update HOME_NET in configuration
    local_ip=$(hostname -I | awk '{print $1}')
    sed -i "s/HOME_NET: \"\[192.168.0.0/16,10.0.0.0/8,172.16.0.0/12\]\"/HOME_NET: \"\[$local_ip\/32\]\"/g" /etc/suricata/suricata.yaml
    
    # Enable rule sources and update
    print_status "Updating Suricata rules..."
    suricata-update enable-source et/open
    suricata-update enable-source oisf/trafficid
    suricata-update
    
    print_status "Configuration completed"
}

# Set up service
setup_service() {
    print_status "Setting up Suricata service..."
    
    # Test configuration
    print_status "Testing Suricata configuration..."
    suricata -T -c /etc/suricata/suricata.yaml
    
    # Enable and start service
    systemctl enable suricata
    systemctl start suricata
    
    print_status "Checking service status..."
    systemctl status suricata --no-pager
    
    print_status "Service setup completed"
}

# Set up log rotation
setup_log_rotation() {
    print_status "Setting up log rotation..."
    
    cat > /etc/logrotate.d/suricata << EOF
/var/log/suricata/*.log {
    daily
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
    create 640 suricata suricata
    sharedscripts
    postrotate
        systemctl reload suricata > /dev/null 2>&1 || true
    endscript
}
EOF
    
    print_status "Log rotation configured"
}

# Install monitoring script
install_monitoring() {
    print_status "Installing monitoring scripts..."
    
    if [ -f "scripts/suricata_monitor.sh" ]; then
        cp scripts/suricata_monitor.sh /usr/local/bin/
        chmod +x /usr/local/bin/suricata_monitor.sh
        
        # Create systemd service for monitoring
        cat > /etc/systemd/system/suricata-monitor.service << EOF
[Unit]
Description=Suricata Monitoring Service
After=suricata.service
Requires=suricata.service

[Service]
Type=simple
ExecStart=/usr/local/bin/suricata_monitor.sh
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
        
        systemctl daemon-reload
        print_status "Monitoring service installed"
    fi
}

# Main installation process
main() {
    print_status "Starting Suricata installation..."
    
    install_suricata
    configure_suricata
    setup_service
    setup_log_rotation
    install_monitoring
    
    print_status "========================================="
    print_status "Suricata installation completed successfully!"
    print_status ""
    print_status "Quick commands:"
    print_status "  Check status: systemctl status suricata"
    print_status "  View logs: tail -f /var/log/suricata/fast.log"
    print_status "  Test config: suricata -T -c /etc/suricata/suricata.yaml"
    print_status "  Update rules: suricata-update"
    print_status ""
    print_status "Configuration files:"
    print_status "  Main config: /etc/suricata/suricata.yaml"
    print_status "  Custom rules: /etc/suricata/rules/local.rules"
    print_status "========================================="
}

# Run main function
main "$@"