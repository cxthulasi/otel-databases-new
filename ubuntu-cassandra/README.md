# Cassandra Metrics Collection with OpenTelemetry for Coralogix

This repository contains scripts to set up Apache Cassandra on an Ubuntu machine and configure OpenTelemetry to collect Cassandra metrics via JMX and send them to Coralogix.

## Prerequisites

- Ubuntu 22.04 or later
- Minimum 2GB RAM (Cassandra will not run with less than 2GB)
- Root or sudo access
- Coralogix API key

## Components

1. **Apache Cassandra**: A distributed NoSQL database
2. **JMX (Java Management Extensions)**: Used to monitor and manage Java applications
3. **OpenTelemetry Collector**: Collects metrics from Cassandra via JMX
4. **Coralogix**: Observability platform where metrics will be sent

## Scripts

This repository includes the following scripts:

1. `install_prerequisites.sh`: Installs Java and other necessary tools
2. `install_cassandra.sh`: Installs and configures Cassandra with JMX remote access
3. `install_otel_collector.sh`: Installs and configures OpenTelemetry Collector
4. `setup_cassandra_otel_coralogix.sh`: Main script that orchestrates the entire setup

## Usage

1. Clone this repository:
   ```
   git clone <repository-url>
   cd <repository-directory>
   ```

2. Make the scripts executable:
   ```
   chmod +x *.sh
   ```

3. Run the main setup script with your Coralogix API key:
   ```
   ./setup_cassandra_otel_coralogix.sh <your-coralogix-api-key> [coralogix-domain]
   ```
   
   The `coralogix-domain` parameter is optional and defaults to `coralogix.com`. Use the appropriate domain for your Coralogix account:
   - US: `coralogix.us`
   - Singapore: `coralogix.com.sg`
   - India: `coralogix.in`
   - Europe: `coralogix.com`
   - Custom: Your custom Coralogix domain

## Metrics Collected

The OpenTelemetry JMX receiver collects the following metrics from Cassandra:

- **Cassandra Metrics**:
  - Client request metrics (count, latency)
  - Storage metrics
  - Compaction metrics
  - And more

- **JVM Metrics**:
  - Memory usage
  - Garbage collection
  - Thread count
  - And more

## Verification

After running the setup script, you can verify that everything is working correctly:

1. Check that Cassandra is running:
   ```
   sudo systemctl status cassandra
   ```

2. Check that OpenTelemetry Collector is running:
   ```
   sudo systemctl status otelcol-contrib
   ```

3. Check the OpenTelemetry Collector logs:
   ```
   sudo journalctl -u otelcol-contrib
   ```

4. Log in to your Coralogix account and check that metrics are being received.

## Troubleshooting

If you encounter any issues:

1. Check the Cassandra logs:
   ```
   sudo journalctl -u cassandra
   ```

2. Check the OpenTelemetry Collector logs:
   ```
   sudo journalctl -u otelcol-contrib
   ```

3. Verify JMX is accessible:
   ```
   nodetool -u cassandra -pw cassandra status
   ```

## Security Considerations

- The default JMX username and password are both set to `cassandra`. In a production environment, you should change these to more secure values.
- The JMX port (7199) is only accessible from localhost by default. If you need remote access, configure your firewall accordingly.

## License

This project is licensed under the MIT License - see the LICENSE file for details.
