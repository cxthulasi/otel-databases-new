#!/bin/bash

# Script to install and configure OpenTelemetry Collector for Cassandra metrics

set -e  # Exit on error

# Check if Coralogix API key is provided
if [ -z "$1" ]; then
  echo "Error: Coralogix API key is required."
  echo "Usage: $0 <coralogix_api_key> [coralogix_domain]"
  exit 1
fi

CORALOGIX_API_KEY=$1
CORALOGIX_DOMAIN=${2:-"coralogix.com"}

echo "Installing and configuring OpenTelemetry Collector..."

# Create directory for OpenTelemetry Collector
sudo mkdir -p /opt/otelcol-contrib
cd /opt/otelcol-contrib

# Download OpenTelemetry Collector Contrib
echo "Downloading OpenTelemetry Collector Contrib..."
OTEL_VERSION="0.83.0"
wget -q https://github.com/open-telemetry/opentelemetry-collector-releases/releases/download/v${OTEL_VERSION}/otelcol-contrib_${OTEL_VERSION}_linux_amd64.tar.gz

# Extract the archive
echo "Extracting OpenTelemetry Collector Contrib..."
sudo tar -xzf otelcol-contrib_${OTEL_VERSION}_linux_amd64.tar.gz

# Download OpenTelemetry Java JMX Metrics Gatherer
echo "Downloading OpenTelemetry Java JMX Metrics Gatherer..."
wget -q https://github.com/open-telemetry/opentelemetry-java-contrib/releases/download/v1.46.0/opentelemetry-jmx-metrics.jar -O opentelemetry-java-contrib-jmx-metrics.jar

# Create configuration file for OpenTelemetry Collector
echo "Creating configuration file for OpenTelemetry Collector..."
cat << EOF | sudo tee /opt/otelcol-contrib/config.yaml
receivers:
  jmx:
    jar_path: /opt/otelcol-contrib/opentelemetry-java-contrib-jmx-metrics.jar
    endpoint: localhost:7199
    target_system: cassandra,jvm
    collection_interval: 60s
    username: cassandra
    password: cassandra

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
        value: cassandra
        action: upsert
      - key: endpoint
        value: localhost:7199
        action: insert

exporters:
  otlp:
    endpoint: "ingress.coralogix.in:443"
    headers:
      Authorization: "Bearer cxtp_AIvMKUfXU9eMTy17b3gTkHh2WvLRJv"
    tls:
      insecure: false

service:
  pipelines:
    metrics:
      receivers: [jmx]
      processors: [resourcedetection, resource, batch]
      exporters: [otlp]
EOF

# Create systemd service file for OpenTelemetry Collector
echo "Creating systemd service file for OpenTelemetry Collector..."
cat << EOF | sudo tee /etc/systemd/system/otelcol-contrib.service
[Unit]
Description=OpenTelemetry Collector Contrib
After=network.target

[Service]
ExecStart=/opt/otelcol-contrib/otelcol-contrib --config=/opt/otelcol-contrib/config.yaml
Restart=always
RestartSec=5
User=root
Group=root

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd daemon
echo "Reloading systemd daemon..."
sudo systemctl daemon-reload

# Start OpenTelemetry Collector
echo "Starting OpenTelemetry Collector..."
sudo systemctl start otelcol-contrib

# Enable OpenTelemetry Collector to start on boot
echo "Enabling OpenTelemetry Collector to start on boot..."
sudo systemctl enable otelcol-contrib

# Check OpenTelemetry Collector status
echo "Checking OpenTelemetry Collector status..."
sudo systemctl status otelcol-contrib

echo "OpenTelemetry Collector installation and configuration completed successfully!"
