#!/bin/bash

# Script to install and configure OpenTelemetry Collector for F5 metrics
# This script installs the OpenTelemetry Collector Contrib using dpkg package
# and configures it to run as a service

set -e  # Exit on error

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root. Please use sudo."
    exit 1
fi

# Check if Coralogix API key is provided
if [ -z "$1" ]; then
  echo "Error: Coralogix API key is required."
  echo "Usage: $0 <coralogix_api_key> [coralogix_domain]"
  exit 1
fi

CORALOGIX_API_KEY=$1
CORALOGIX_DOMAIN=${2:-"coralogix.com"}
OTEL_VERSION="0.115.0"  # Update this to the latest version as needed

echo "Installing and configuring OpenTelemetry Collector Contrib..."

# Create directory for OpenTelemetry Collector
mkdir -p /opt/otelcol-contrib
cd /opt/otelcol-contrib

# Download OpenTelemetry Collector Contrib
echo "Downloading OpenTelemetry Collector Contrib..."
wget -q https://github.com/open-telemetry/opentelemetry-collector-releases/releases/download/v${OTEL_VERSION}/otelcol-contrib_${OTEL_VERSION}_linux_amd64.deb

# Install the package
echo "Installing OpenTelemetry Collector Contrib..."
dpkg -i otelcol-contrib_${OTEL_VERSION}_linux_amd64.deb

# Create configuration directory if it doesn't exist
mkdir -p /etc/otelcol-contrib/

# Create configuration file for OpenTelemetry Collector
echo "Creating configuration file for OpenTelemetry Collector..."
cat > /etc/otelcol-contrib/config.yaml << EOF
receivers:
  snmp:
    collection_interval: 60s
    endpoint: localhost:161
    version: v2c
    community: public
    metrics:
      ltmVirtualServNumber:
        unit: "{servers}"
        gauge:
          value_type: int
        oid: "1.3.6.1.4.1.3375.2.2.10.1.1"
      ltmVirtualServName:
        enabled: true
        oid: "1.3.6.1.4.1.3375.2.2.10.1.2.1.1"
      ltmVirtualServAddr:
        enabled: true
        oid: "1.3.6.1.4.1.3375.2.2.10.1.2.1.3"
      ltmVirtualServPort:
        unit: "{port}"
        gauge:
          value_type: int
        oid: "1.3.6.1.4.1.3375.2.2.10.1.2.1.6"
      ltmVirtualServAvailabilityState:
        unit: "{state}"
        gauge:
          value_type: int
        oid: "1.3.6.1.4.1.3375.2.2.10.1.2.1.22"
      ltmVirtualServEnabledState:
        unit: "{state}"
        gauge:
          value_type: int
        oid: "1.3.6.1.4.1.3375.2.2.10.1.2.1.23"
      ltmVirtualServStatusReason:
        enabled: true
        oid: "1.3.6.1.4.1.3375.2.2.10.1.2.1.25"
      ltmVirtualServVaName:
        enabled: true
        oid: "1.3.6.1.4.1.3375.2.2.10.1.2.1.29"
      ltmVirtualServStatClientMaxConns:
        unit: "{connections}"
        gauge:
          value_type: int
        oid: "1.3.6.1.4.1.3375.2.2.10.2.3.1.10"
      ltmVirtualServStatClientTotConns:
        unit: "{connections}"
        sum:
          value_type: int
          monotonic: true
          aggregation: cumulative
        oid: "1.3.6.1.4.1.3375.2.2.10.2.3.1.11"
      ltmVirtualServStatClientCurConns:
        unit: "{connections}"
        gauge:
          value_type: int
        oid: "1.3.6.1.4.1.3375.2.2.10.2.3.1.12"
      ltmVirtualServPoolPoolName:
        enabled: true
        oid: "1.3.6.1.4.1.3375.2.2.10.6.2.1.2"

processors:
  batch:
    send_batch_size: 1024
    send_batch_max_size: 2048
    timeout: 1s

  resourcedetection:
    detectors: [system]
    system:
      hostname_sources: [os]

  resource:
    attributes:
      - key: service.name
        value: f5-metrics
        action: upsert
      - key: service.namespace
        value: f5
        action: upsert

exporters:
  debug:
    verbosity: detailed
  
  otlp:
    endpoint: "ingress.${CORALOGIX_DOMAIN}:443"
    headers:
      Authorization: "Bearer ${CORALOGIX_API_KEY}"
    tls:
      insecure: false

service:
  pipelines:
    metrics:
      receivers: [snmp]
      processors: [resourcedetection, resource, batch]
      exporters: [otlp, debug]
EOF

# Create systemd service file for OpenTelemetry Collector
echo "Creating systemd service file for OpenTelemetry Collector..."
cat > /etc/systemd/system/otelcol-contrib.service << EOF
[Unit]
Description=OpenTelemetry Collector Contrib
After=network.target

[Service]
ExecStart=/usr/bin/otelcol-contrib --config=/etc/otelcol-contrib/config.yaml
Restart=always
RestartSec=5
User=root
Group=root

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd daemon
echo "Reloading systemd daemon..."
systemctl daemon-reload

# Start OpenTelemetry Collector
echo "Starting OpenTelemetry Collector..."
systemctl start otelcol-contrib

# Enable OpenTelemetry Collector to start on boot
echo "Enabling OpenTelemetry Collector to start on boot..."
systemctl enable otelcol-contrib

# Check OpenTelemetry Collector status
echo "Checking OpenTelemetry Collector status..."
systemctl status otelcol-contrib

echo "OpenTelemetry Collector installation and configuration completed successfully!"
