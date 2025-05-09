#!/bin/bash

# Script to install prerequisites for Cassandra and OpenTelemetry setup
# This script installs Java, wget, curl, and other necessary tools

set -e  # Exit on error

echo "Installing prerequisites for Cassandra and OpenTelemetry setup..."

# Update package lists
echo "Updating package lists..."
sudo apt update

# Install Java (OpenJDK 11)
echo "Installing Java (OpenJDK 11)..."
sudo apt install -y openjdk-11-jdk

# Verify Java installation
java -version

# Install other necessary tools
echo "Installing other necessary tools..."
sudo apt install -y wget curl gnupg2 apt-transport-https ca-certificates lsb-release

echo "Prerequisites installation completed successfully!"
