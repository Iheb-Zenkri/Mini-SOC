#!/bin/bash

# Elastic Stack Installation Script for Ubuntu/Debian

set -e

echo "=== Elastic Stack Installation ==="

# Update system
sudo apt-get update

# Install prerequisites
sudo apt-get install -y wget apt-transport-https gnupg2

# Add Elastic GPG key
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo gpg --dearmor -o /usr/share/keyrings/elasticsearch-keyring.gpg

# Add Elastic repository
echo "deb [signed-by=/usr/share/keyrings/elasticsearch-keyring.gpg] https://artifacts.elastic.co/packages/8.x/apt stable main" | sudo tee /etc/apt/sources.list.d/elastic-8.x.list

# Update package list
sudo apt-get update

# Install Elasticsearch
echo "Installing Elasticsearch..."
sudo apt-get install -y elasticsearch

# Configure Elasticsearch
sudo systemctl daemon-reload
sudo systemctl enable elasticsearch
sudo systemctl start elasticsearch

# Wait for Elasticsearch to start
sleep 30

# Install Kibana
echo "Installing Kibana..."
sudo apt-get install -y kibana

sudo systemctl enable kibana
sudo systemctl start kibana

# Install Logstash
echo "Installing Logstash..."
sudo apt-get install -y logstash

sudo systemctl enable logstash
sudo systemctl start logstash

# Install Filebeat (for log shipping)
echo "Installing Filebeat..."
sudo apt-get install -y filebeat

sudo systemctl enable filebeat

echo "=== Installation Complete ==="
echo "Elasticsearch: http://localhost:9200"
echo "Kibana: http://localhost:5601"
echo ""
echo "IMPORTANT: Save the elastic user password shown above!"