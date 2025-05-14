#!/bin/bash

# Main setup script for F5 metrics simulator with OpenTelemetry SNMP receiver

set -e  # Exit on error

# Default values
SNMP_PORT=1161  # Using non-privileged port by default
CORALOGIX_API_KEY=""
CORALOGIX_DOMAIN="coralogix.com"
INSTALL_DEPS=true
INSTALL_OTEL=true
START_SIMULATOR=true
RUN_TESTS=true

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        --snmp-port)
        SNMP_PORT="$2"
        shift
        shift
        ;;
        --coralogix-api-key)
        CORALOGIX_API_KEY="$2"
        shift
        shift
        ;;
        --coralogix-domain)
        CORALOGIX_DOMAIN="$2"
        shift
        shift
        ;;
        --skip-deps)
        INSTALL_DEPS=false
        shift
        ;;
        --skip-otel)
        INSTALL_OTEL=false
        shift
        ;;
        --skip-simulator)
        START_SIMULATOR=false
        shift
        ;;
        --skip-tests)
        RUN_TESTS=false
        shift
        ;;
        *)
        echo "Unknown option: $1"
        exit 1
        ;;
    esac
done

# Make scripts executable
chmod +x scripts/*.sh
chmod +x scripts/*.py

# Current directory
CURRENT_DIR=$(pwd)

echo "Setting up F5 metrics simulator with OpenTelemetry SNMP receiver..."
echo "SNMP Port: $SNMP_PORT"
echo "Coralogix Domain: $CORALOGIX_DOMAIN"

# Install dependencies
if [ "$INSTALL_DEPS" = true ]; then
    echo "Installing dependencies..."
    ./scripts/install_dependencies.sh
else
    echo "Skipping dependencies installation..."
fi

# Install OpenTelemetry Collector
if [ "$INSTALL_OTEL" = true ]; then
    if [ -z "$CORALOGIX_API_KEY" ]; then
        echo "Error: Coralogix API key is required for OpenTelemetry Collector installation."
        echo "Please provide it with --coralogix-api-key option."
        exit 1
    fi
    
    echo "Installing OpenTelemetry Collector..."
    sudo ./scripts/install_otel_collector.sh "$CORALOGIX_API_KEY" "$CORALOGIX_DOMAIN"
else
    echo "Skipping OpenTelemetry Collector installation..."
fi

# Start F5 simulator
if [ "$START_SIMULATOR" = true ]; then
    echo "Starting F5 simulator..."
    
    # Activate virtual environment
    source venv/bin/activate
    
    # Start simulator in background
    nohup python3 scripts/f5_simulator.py --port "$SNMP_PORT" > f5_simulator.log 2>&1 &
    SIMULATOR_PID=$!
    
    echo "F5 simulator started with PID: $SIMULATOR_PID"
    echo "Simulator log file: $CURRENT_DIR/f5_simulator.log"
    
    # Wait for simulator to start
    echo "Waiting for simulator to start..."
    sleep 5
else
    echo "Skipping F5 simulator startup..."
fi

# Run tests
if [ "$RUN_TESTS" = true ]; then
    echo "Running tests..."
    ./scripts/test_setup.sh --snmp-port "$SNMP_PORT"
else
    echo "Skipping tests..."
fi

echo "Setup completed successfully!"
echo ""
echo "To check the F5 simulator status:"
echo "  ps aux | grep f5_simulator"
echo ""
echo "To check the OpenTelemetry Collector status:"
echo "  sudo systemctl status otelcol-contrib"
echo ""
echo "To test SNMP connectivity:"
echo "  snmpwalk -v2c -c public localhost:$SNMP_PORT 1.3.6.1.4.1.3375.2.2.10.1.1"
echo ""
echo "To stop the F5 simulator:"
echo "  pkill -f f5_simulator.py"
echo ""
echo "To stop the OpenTelemetry Collector:"
echo "  sudo systemctl stop otelcol-contrib"
