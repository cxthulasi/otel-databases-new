#!/bin/bash

# Script to generate load on Cassandra to produce metrics

set -e  # Exit on error

echo "Generating load on Cassandra to produce metrics..."

# Create a keyspace and table
echo "Creating keyspace and table..."
cqlsh -e "CREATE KEYSPACE IF NOT EXISTS test_keyspace WITH replication = {'class': 'SimpleStrategy', 'replication_factor': 1};"
cqlsh -e "CREATE TABLE IF NOT EXISTS test_keyspace.test_table (id UUID PRIMARY KEY, name TEXT, value INT);"

# Insert some data
echo "Inserting data..."
for i in {1..1000}; do
  uuid=$(uuidgen)
  cqlsh -e "INSERT INTO test_keyspace.test_table (id, name, value) VALUES ($uuid, 'test_name_$i', $i);"
  
  # Print progress every 100 inserts
  if [ $((i % 100)) -eq 0 ]; then
    echo "Inserted $i records..."
  fi
done

# Run some queries
echo "Running queries..."
for i in {1..50}; do
  cqlsh -e "SELECT * FROM test_keyspace.test_table LIMIT 10;"
  cqlsh -e "SELECT COUNT(*) FROM test_keyspace.test_table;"
  
  # Print progress every 10 queries
  if [ $((i % 10)) -eq 0 ]; then
    echo "Ran $i queries..."
  fi
done

# Run some nodetool commands to generate JMX metrics
echo "Running nodetool commands..."
for i in {1..20}; do
  nodetool -u cassandra -pw cassandra status > /dev/null
  nodetool -u cassandra -pw cassandra info > /dev/null
  nodetool -u cassandra -pw cassandra tablestats > /dev/null
  nodetool -u cassandra -pw cassandra tpstats > /dev/null
  
  # Print progress every 5 iterations
  if [ $((i % 5)) -eq 0 ]; then
    echo "Ran nodetool commands $i times..."
  fi
  
  sleep 1
done

echo "Load generation completed. Metrics should now be visible in Coralogix."
