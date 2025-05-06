#!/bin/bash

# Main script to set up Cassandra with OpenTelemetry for Coralogix

set -e  # Exit on error

# Check if Coralogix API key is provided
if [ -z "$1" ]; then
  echo "Error: Coralogix API key is required."
  echo "Usage: $0 <coralogix_api_key> [coralogix_domain]"
  exit 1
fi

CORALOGIX_API_KEY=$1
CORALOGIX_DOMAIN=${2:-"coralogix.com"}

echo "Starting setup of Cassandra with OpenTelemetry for Coralogix..."

# Make all scripts executable
chmod +x install_prerequisites.sh
chmod +x install_cassandra.sh
chmod +x install_otel_collector.sh

# Step 1: Install prerequisites
echo "Step 1: Installing prerequisites..."
./install_prerequisites.sh

# Step 2: Install and configure Cassandra
echo "Step 2: Installing and configuring Cassandra..."
./install_cassandra.sh

# Step 3: Install and configure OpenTelemetry Collector
echo "Step 3: Installing and configuring OpenTelemetry Collector..."
./install_otel_collector.sh "$CORALOGIX_API_KEY" "$CORALOGIX_DOMAIN"

echo "Setup completed successfully!"
echo "Cassandra is now running with JMX enabled."
echo "OpenTelemetry Collector is collecting Cassandra metrics and sending them to Coralogix."
echo ""
echo "You can check the status of the services with the following commands:"
echo "  sudo systemctl status cassandra"
echo "  sudo systemctl status otelcol-contrib"
echo ""
echo "To view the logs of the services, use the following commands:"
echo "  sudo journalctl -u cassandra"
echo "  sudo journalctl -u otelcol-contrib"
