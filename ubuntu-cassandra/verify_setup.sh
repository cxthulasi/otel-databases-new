#!/bin/bash

# Script to verify the Cassandra and OpenTelemetry setup

set -e  # Exit on error

echo "Verifying Cassandra and OpenTelemetry setup..."

# Check if Cassandra is running
echo "Checking Cassandra status..."
if sudo systemctl is-active --quiet cassandra; then
  echo "✅ Cassandra is running."
else
  echo "❌ Cassandra is not running. Check the logs with: sudo journalctl -u cassandra"
  exit 1
fi

# Check if OpenTelemetry Collector is running
echo "Checking OpenTelemetry Collector status..."
if sudo systemctl is-active --quiet otelcol-contrib; then
  echo "✅ OpenTelemetry Collector is running."
else
  echo "❌ OpenTelemetry Collector is not running. Check the logs with: sudo journalctl -u otelcol-contrib"
  exit 1
fi

# Test JMX connection
echo "Testing JMX connection with nodetool..."
if nodetool -u cassandra -pw cassandra status > /dev/null; then
  echo "✅ JMX connection is working."
else
  echo "❌ JMX connection is not working. Check the Cassandra JMX configuration."
  exit 1
fi

# Check OpenTelemetry Collector logs for errors
echo "Checking OpenTelemetry Collector logs for errors..."
if sudo journalctl -u otelcol-contrib --no-pager -n 50 | grep -i error; then
  echo "⚠️ Found errors in OpenTelemetry Collector logs. Please review the logs."
else
  echo "✅ No errors found in OpenTelemetry Collector logs."
fi

# Generate some load on Cassandra to produce metrics
echo "Generating some load on Cassandra to produce metrics..."
for i in {1..10}; do
  nodetool -u cassandra -pw cassandra status > /dev/null
  nodetool -u cassandra -pw cassandra info > /dev/null
  nodetool -u cassandra -pw cassandra tablestats > /dev/null
  sleep 1
done

echo "Waiting for metrics to be collected (30 seconds)..."
sleep 30

# Check if metrics are being exported
echo "Checking if metrics are being exported..."
if sudo journalctl -u otelcol-contrib --no-pager -n 100 | grep -i "Exporting metrics"; then
  echo "✅ Metrics are being exported to Coralogix."
else
  echo "⚠️ Could not confirm if metrics are being exported. Check the OpenTelemetry Collector logs."
fi

echo "Verification completed. If all checks passed, your setup is working correctly."
echo "You should now be able to see Cassandra metrics in your Coralogix dashboard."
echo ""
echo "If you're still having issues, check the following:"
echo "1. Cassandra logs: sudo journalctl -u cassandra"
echo "2. OpenTelemetry Collector logs: sudo journalctl -u otelcol-contrib"
echo "3. Coralogix API key and domain are correct"
echo "4. Network connectivity to Coralogix"
