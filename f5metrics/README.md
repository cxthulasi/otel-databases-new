# F5 Metrics Simulator with OpenTelemetry SNMP Receiver

This project provides a complete solution for simulating F5 BIG-IP metrics using SNMP and collecting them with OpenTelemetry Collector for sending to Coralogix.

## Features

- F5 BIG-IP SNMP simulator that generates realistic metrics
- OpenTelemetry Collector with SNMP receiver configuration
- Integration with Coralogix for metrics storage and visualization
- Traffic generator to simulate SNMP queries
- Comprehensive testing tools

## Prerequisites

- Ubuntu Linux (for OpenTelemetry Collector installation)
- Python 3.6 or higher
- SNMP tools (will be installed by the setup script)
- Coralogix API key

## Directory Structure

```
f5metrics/
├── configs/                # Configuration files
├── scripts/                # Scripts for installation and testing
│   ├── f5_simulator.py     # F5 BIG-IP SNMP simulator
│   ├── install_dependencies.sh # Script to install dependencies
│   ├── install_otel_collector.sh # Script to install OpenTelemetry Collector
│   ├── test_setup.sh       # Script to test the setup
│   └── traffic_generator.py # Script to generate SNMP traffic
├── tools/                  # Additional tools
├── setup.sh                # Main setup script
└── README.md               # This file
```

## Installation

1. Clone this repository:

```bash
git clone <repository-url>
cd <repository-directory>/f5metrics
```

2. Make the scripts executable:

```bash
chmod +x setup.sh scripts/*.sh scripts/*.py
```

3. Run the setup script with your Coralogix API key:

```bash
./setup.sh --coralogix-api-key <your-coralogix-api-key> --coralogix-domain <your-coralogix-domain>
```

Available options:
- `--snmp-port <port>`: SNMP port for the simulator (default: 1161)
- `--coralogix-api-key <key>`: Your Coralogix API key (required)
- `--coralogix-domain <domain>`: Your Coralogix domain (default: coralogix.com)
- `--skip-deps`: Skip dependencies installation
- `--skip-otel`: Skip OpenTelemetry Collector installation
- `--skip-simulator`: Skip F5 simulator startup
- `--skip-tests`: Skip tests

## F5 Metrics Simulated

The simulator provides the following F5 BIG-IP metrics:

- `ltmVirtualServNumber` (1.3.6.1.4.1.3375.2.2.10.1.1)
- `ltmVirtualServName` (1.3.6.1.4.1.3375.2.2.10.1.2.1.1)
- `ltmVirtualServAddr` (1.3.6.1.4.1.3375.2.2.10.1.2.1.3)
- `ltmVirtualServPort` (1.3.6.1.4.1.3375.2.2.10.1.2.1.6)
- `ltmVirtualServAvailabilityState` (1.3.6.1.4.1.3375.2.2.10.1.2.1.22)
- `ltmVirtualServEnabledState` (1.3.6.1.4.1.3375.2.2.10.1.2.1.23)
- `ltmVirtualServStatusReason` (1.3.6.1.4.1.3375.2.2.10.1.2.1.25)
- `ltmVirtualServVaName` (1.3.6.1.4.1.3375.2.2.10.1.2.1.29)
- `ltmVirtualServStatClientMaxConns` (1.3.6.1.4.1.3375.2.2.10.2.3.1.10)
- `ltmVirtualServStatClientTotConns` (1.3.6.1.4.1.3375.2.2.10.2.3.1.11)
- `ltmVirtualServStatClientCurConns` (1.3.6.1.4.1.3375.2.2.10.2.3.1.12)
- `ltmVirtualServPoolPoolName` (1.3.6.1.4.1.3375.2.2.10.6.2.1.2)

## Usage

### Starting the F5 Simulator

The F5 simulator is started automatically by the setup script. If you need to start it manually:

```bash
cd f5metrics
source venv/bin/activate
python scripts/f5_simulator.py --port 1161
```

### Generating Traffic

To generate SNMP traffic to the simulator:

```bash
cd f5metrics
source venv/bin/activate
python scripts/traffic_generator.py --port 1161 --interval 5
```

### Testing the Setup

To test the setup:

```bash
cd f5metrics
./scripts/test_setup.sh --snmp-port 1161
```

### Checking OpenTelemetry Collector Status

```bash
sudo systemctl status otelcol-contrib
```

### Viewing Collector Logs

```bash
sudo journalctl -u otelcol-contrib -f
```

## Customization

### Adding More F5 Metrics

To add more F5 metrics to the simulator, edit the `F5_OIDS` dictionary in `scripts/f5_simulator.py` and add the corresponding OIDs.

### Modifying OpenTelemetry Collector Configuration

The OpenTelemetry Collector configuration is stored in `/etc/otelcol-contrib/config.yaml`. You can modify this file to change the collector's behavior.

## Troubleshooting

### SNMP Connectivity Issues

If you're having trouble connecting to the SNMP simulator:

1. Check if the simulator is running:
   ```bash
   ps aux | grep f5_simulator
   ```

2. Verify the SNMP port is open:
   ```bash
   sudo netstat -tulpn | grep <port>
   ```

3. Test SNMP connectivity:
   ```bash
   snmpwalk -v2c -c public localhost:<port> 1.3.6.1.4.1.3375.2.2.10.1.1
   ```

### OpenTelemetry Collector Issues

1. Check the collector status:
   ```bash
   sudo systemctl status otelcol-contrib
   ```

2. View the collector logs:
   ```bash
   sudo journalctl -u otelcol-contrib -f
   ```

3. Verify the configuration:
   ```bash
   sudo cat /etc/otelcol-contrib/config.yaml
   ```

## Cleanup

To stop the F5 simulator:

```bash
pkill -f f5_simulator.py
```

To stop the OpenTelemetry Collector:

```bash
sudo systemctl stop otelcol-contrib
```

To disable the OpenTelemetry Collector from starting at boot:

```bash
sudo systemctl disable otelcol-contrib
```

To completely remove the OpenTelemetry Collector:

```bash
sudo systemctl stop otelcol-contrib
sudo systemctl disable otelcol-contrib
sudo rm -f /etc/systemd/system/otelcol-contrib.service
sudo rm -rf /etc/otelcol-contrib
sudo dpkg -r otelcol-contrib
```
