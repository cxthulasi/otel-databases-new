#!/bin/bash

# Script to install dependencies for F5 metrics simulator
# This script creates a Python virtual environment and installs required packages

set -e  # Exit on error

# Check if Python 3 is installed
if ! command -v python3 &> /dev/null; then
    echo "Python 3 is not installed. Please install Python 3 and try again."
    exit 1
fi

# Create virtual environment if it doesn't exist
if [ ! -d "venv" ]; then
    echo "Creating Python virtual environment..."
    python3 -m venv venv
fi

# Activate virtual environment
echo "Activating virtual environment..."
source venv/bin/activate

# Install required packages
echo "Installing required packages..."
pip install --upgrade pip
pip install pysnmp snmpsim

# Install SNMP tools for testing
echo "Installing SNMP tools..."
if [ "$(uname)" == "Darwin" ]; then
    # macOS
    brew install net-snmp
elif [ "$(uname)" == "Linux" ]; then
    # Linux
    if command -v apt-get &> /dev/null; then
        # Debian/Ubuntu
        sudo apt-get update
        sudo apt-get install -y snmp snmp-mibs-downloader
    elif command -v yum &> /dev/null; then
        # RHEL/CentOS
        sudo yum install -y net-snmp net-snmp-utils
    else
        echo "Unsupported Linux distribution. Please install SNMP tools manually."
    fi
else
    echo "Unsupported operating system. Please install SNMP tools manually."
fi

echo "Dependencies installation completed successfully!"
echo "To activate the virtual environment, run: source venv/bin/activate"
