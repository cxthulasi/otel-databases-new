#!/bin/bash

# Script to test the F5 metrics simulator and OpenTelemetry Collector setup

set -e  # Exit on error

# Default values
SNMP_HOST="localhost"
SNMP_PORT=161
SNMP_COMMUNITY="public"
OTEL_PORT=4317

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        --snmp-host)
        SNMP_HOST="$2"
        shift
        shift
        ;;
        --snmp-port)
        SNMP_PORT="$2"
        shift
        shift
        ;;
        --snmp-community)
        SNMP_COMMUNITY="$2"
        shift
        shift
        ;;
        --otel-port)
        OTEL_PORT="$2"
        shift
        shift
        ;;
        *)
        echo "Unknown option: $1"
        exit 1
        ;;
    esac
done

echo "Testing F5 metrics simulator and OpenTelemetry Collector setup..."
echo "SNMP Host: $SNMP_HOST"
echo "SNMP Port: $SNMP_PORT"
echo "SNMP Community: $SNMP_COMMUNITY"
echo "OpenTelemetry Port: $OTEL_PORT"

# Check if snmpwalk is installed
if ! command -v snmpwalk &> /dev/null; then
    echo "snmpwalk is not installed. Please install SNMP tools and try again."
    exit 1
fi

# Test SNMP connectivity
echo "Testing SNMP connectivity..."
if snmpwalk -v2c -c "$SNMP_COMMUNITY" "$SNMP_HOST:$SNMP_PORT" 1.3.6.1.4.1.3375.2.2.10.1.1 > /dev/null; then
    echo "✅ SNMP connectivity test passed."
else
    echo "❌ SNMP connectivity test failed. Please check if the F5 simulator is running."
    exit 1
fi

# Test specific OIDs
echo "Testing specific OIDs..."

# Test ltmVirtualServNumber
echo "Testing ltmVirtualServNumber..."
if snmpget -v2c -c "$SNMP_COMMUNITY" "$SNMP_HOST:$SNMP_PORT" 1.3.6.1.4.1.3375.2.2.10.1.1.0 > /dev/null; then
    echo "✅ ltmVirtualServNumber test passed."
else
    echo "❌ ltmVirtualServNumber test failed."
fi

# Test ltmVirtualServName
echo "Testing ltmVirtualServName..."
if snmpwalk -v2c -c "$SNMP_COMMUNITY" "$SNMP_HOST:$SNMP_PORT" 1.3.6.1.4.1.3375.2.2.10.1.2.1.1 > /dev/null; then
    echo "✅ ltmVirtualServName test passed."
else
    echo "❌ ltmVirtualServName test failed."
fi

# Test ltmVirtualServAddr
echo "Testing ltmVirtualServAddr..."
if snmpwalk -v2c -c "$SNMP_COMMUNITY" "$SNMP_HOST:$SNMP_PORT" 1.3.6.1.4.1.3375.2.2.10.1.2.1.3 > /dev/null; then
    echo "✅ ltmVirtualServAddr test passed."
else
    echo "❌ ltmVirtualServAddr test failed."
fi

# Test ltmVirtualServPort
echo "Testing ltmVirtualServPort..."
if snmpwalk -v2c -c "$SNMP_COMMUNITY" "$SNMP_HOST:$SNMP_PORT" 1.3.6.1.4.1.3375.2.2.10.1.2.1.6 > /dev/null; then
    echo "✅ ltmVirtualServPort test passed."
else
    echo "❌ ltmVirtualServPort test failed."
fi

# Test ltmVirtualServAvailabilityState
echo "Testing ltmVirtualServAvailabilityState..."
if snmpwalk -v2c -c "$SNMP_COMMUNITY" "$SNMP_HOST:$SNMP_PORT" 1.3.6.1.4.1.3375.2.2.10.1.2.1.22 > /dev/null; then
    echo "✅ ltmVirtualServAvailabilityState test passed."
else
    echo "❌ ltmVirtualServAvailabilityState test failed."
fi

# Test ltmVirtualServEnabledState
echo "Testing ltmVirtualServEnabledState..."
if snmpwalk -v2c -c "$SNMP_COMMUNITY" "$SNMP_HOST:$SNMP_PORT" 1.3.6.1.4.1.3375.2.2.10.1.2.1.23 > /dev/null; then
    echo "✅ ltmVirtualServEnabledState test passed."
else
    echo "❌ ltmVirtualServEnabledState test failed."
fi

# Test ltmVirtualServStatusReason
echo "Testing ltmVirtualServStatusReason..."
if snmpwalk -v2c -c "$SNMP_COMMUNITY" "$SNMP_HOST:$SNMP_PORT" 1.3.6.1.4.1.3375.2.2.10.1.2.1.25 > /dev/null; then
    echo "✅ ltmVirtualServStatusReason test passed."
else
    echo "❌ ltmVirtualServStatusReason test failed."
fi

# Test ltmVirtualServStatClientMaxConns
echo "Testing ltmVirtualServStatClientMaxConns..."
if snmpwalk -v2c -c "$SNMP_COMMUNITY" "$SNMP_HOST:$SNMP_PORT" 1.3.6.1.4.1.3375.2.2.10.2.3.1.10 > /dev/null; then
    echo "✅ ltmVirtualServStatClientMaxConns test passed."
else
    echo "❌ ltmVirtualServStatClientMaxConns test failed."
fi

# Test ltmVirtualServStatClientTotConns
echo "Testing ltmVirtualServStatClientTotConns..."
if snmpwalk -v2c -c "$SNMP_COMMUNITY" "$SNMP_HOST:$SNMP_PORT" 1.3.6.1.4.1.3375.2.2.10.2.3.1.11 > /dev/null; then
    echo "✅ ltmVirtualServStatClientTotConns test passed."
else
    echo "❌ ltmVirtualServStatClientTotConns test failed."
fi

# Test ltmVirtualServStatClientCurConns
echo "Testing ltmVirtualServStatClientCurConns..."
if snmpwalk -v2c -c "$SNMP_COMMUNITY" "$SNMP_HOST:$SNMP_PORT" 1.3.6.1.4.1.3375.2.2.10.2.3.1.12 > /dev/null; then
    echo "✅ ltmVirtualServStatClientCurConns test passed."
else
    echo "❌ ltmVirtualServStatClientCurConns test failed."
fi

# Test ltmVirtualServPoolPoolName
echo "Testing ltmVirtualServPoolPoolName..."
if snmpwalk -v2c -c "$SNMP_COMMUNITY" "$SNMP_HOST:$SNMP_PORT" 1.3.6.1.4.1.3375.2.2.10.6.2.1.2 > /dev/null; then
    echo "✅ ltmVirtualServPoolPoolName test passed."
else
    echo "❌ ltmVirtualServPoolPoolName test failed."
fi

# Check if OpenTelemetry Collector is running
echo "Checking if OpenTelemetry Collector is running..."
if systemctl is-active --quiet otelcol-contrib; then
    echo "✅ OpenTelemetry Collector is running."
else
    echo "❌ OpenTelemetry Collector is not running."
fi

echo "Testing completed!"
