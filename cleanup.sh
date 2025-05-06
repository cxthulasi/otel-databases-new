#!/bin/bash

# Script to clean up the Cassandra and OpenTelemetry setup

set -e  # Exit on error

echo "Cleaning up Cassandra and OpenTelemetry setup..."

# Stop and disable OpenTelemetry Collector
echo "Stopping and disabling OpenTelemetry Collector..."
sudo systemctl stop otelcol-contrib || true
sudo systemctl disable otelcol-contrib || true
sudo rm -f /etc/systemd/system/otelcol-contrib.service

# Stop and disable Cassandra
echo "Stopping and disabling Cassandra..."
sudo systemctl stop cassandra || true
sudo systemctl disable cassandra || true

# Remove OpenTelemetry Collector files
echo "Removing OpenTelemetry Collector files..."
sudo rm -rf /opt/otelcol-contrib

# Remove Cassandra
echo "Removing Cassandra..."
sudo apt purge -y cassandra
sudo apt autoremove -y

# Remove Cassandra repository
echo "Removing Cassandra repository..."
sudo rm -f /etc/apt/sources.list.d/cassandra.sources.list
sudo apt update

# Remove JMX files
echo "Removing JMX files..."
sudo rm -f /etc/cassandra/jmxremote.password
sudo rm -f /etc/cassandra/jmxremote.access

echo "Cleanup completed successfully!"
