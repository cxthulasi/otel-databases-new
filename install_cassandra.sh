#!/bin/bash

# Script to install and configure Cassandra with JMX remote access

set -e  # Exit on error

echo "Installing and configuring Cassandra..."

# Add the Apache Cassandra repository
echo "Adding Cassandra repository..."
echo "deb https://debian.cassandra.apache.org 40x main" | sudo tee -a /etc/apt/sources.list.d/cassandra.sources.list

# Add the Apache Cassandra repository keys
echo "Adding Cassandra repository keys..."
wget -q -O - https://downloads.apache.org/cassandra/KEYS | sudo apt-key add -

# Update package lists
echo "Updating package lists..."
sudo apt update

# Install Cassandra
echo "Installing Cassandra..."
sudo apt install -y cassandra

# Wait for Cassandra to start
echo "Waiting for Cassandra to start..."
sleep 10

# Check Cassandra status
echo "Checking Cassandra status..."
sudo systemctl status cassandra

# Configure JMX for remote access
echo "Configuring JMX for remote access..."

# Backup the original cassandra-env.sh file
sudo cp /etc/cassandra/cassandra-env.sh /etc/cassandra/cassandra-env.sh.backup

# Modify the cassandra-env.sh file to enable remote JMX access
sudo sed -i 's/LOCAL_JMX=yes/LOCAL_JMX=no/g' /etc/cassandra/cassandra-env.sh

# Create JMX password file
echo "Creating JMX password file..."
echo 'cassandra cassandra' | sudo tee /etc/cassandra/jmxremote.password > /dev/null
sudo chown cassandra:cassandra /etc/cassandra/jmxremote.password
sudo chmod 400 /etc/cassandra/jmxremote.password

# Create JMX access file
echo "Creating JMX access file..."
echo 'cassandra readwrite' | sudo tee /etc/cassandra/jmxremote.access > /dev/null
sudo chown cassandra:cassandra /etc/cassandra/jmxremote.access
sudo chmod 400 /etc/cassandra/jmxremote.access

# Restart Cassandra to apply JMX configuration
echo "Restarting Cassandra to apply JMX configuration..."
sudo systemctl restart cassandra

# Wait for Cassandra to restart
echo "Waiting for Cassandra to restart..."
sleep 10

# Verify Cassandra is running
echo "Verifying Cassandra is running..."
sudo systemctl status cassandra

# Test JMX connection
echo "Testing JMX connection with nodetool..."
nodetool -u cassandra -pw cassandra status

echo "Cassandra installation and configuration completed successfully!"
