#!/usr/bin/env python3
"""
F5 BIG-IP SNMP Simulator

This script simulates an F5 BIG-IP device by implementing an SNMP agent that responds
to SNMP queries with simulated F5 metrics. It focuses on virtual server metrics.

Required packages:
- pysnmp
"""

import argparse
import logging
import os
import random
import sys
import time
from datetime import datetime
from pysnmp.entity import engine, config
from pysnmp.entity.rfc3413 import cmdrsp, context
from pysnmp.carrier.asyncore.dgram import udp
from pysnmp.proto.api import v2c
from pysnmp.smi import builder, view, compiler, rfc1902

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger('f5-simulator')

# F5 BIG-IP OIDs
F5_OIDS = {
    # Virtual Server Statistics
    'ltmVirtualServNumber': '1.3.6.1.4.1.3375.2.2.10.1.1.0',
    'ltmVirtualServName': '1.3.6.1.4.1.3375.2.2.10.1.2.1.1',
    'ltmVirtualServAddr': '1.3.6.1.4.1.3375.2.2.10.1.2.1.3',
    'ltmVirtualServPort': '1.3.6.1.4.1.3375.2.2.10.1.2.1.6',
    'ltmVirtualServAvailabilityState': '1.3.6.1.4.1.3375.2.2.10.1.2.1.22',
    'ltmVirtualServEnabledState': '1.3.6.1.4.1.3375.2.2.10.1.2.1.23',
    'ltmVirtualServStatusReason': '1.3.6.1.4.1.3375.2.2.10.1.2.1.25',
    'ltmVirtualServVaName': '1.3.6.1.4.1.3375.2.2.10.1.2.1.29',
    'ltmVirtualServStatClientMaxConns': '1.3.6.1.4.1.3375.2.2.10.2.3.1.10',
    'ltmVirtualServStatClientTotConns': '1.3.6.1.4.1.3375.2.2.10.2.3.1.11',
    'ltmVirtualServStatClientCurConns': '1.3.6.1.4.1.3375.2.2.10.2.3.1.12',
    'ltmVirtualServPoolPoolName': '1.3.6.1.4.1.3375.2.2.10.6.2.1.2',
}

# Virtual server configurations
VIRTUAL_SERVERS = [
    {
        'name': 'vs_http',
        'addr': '10.10.10.10',
        'port': 80,
        'availability': 1,  # 0=unknown, 1=green (available), 2=yellow (not available), 3=red (not available), 4=blue (availability is unknown), 5=gray (unlicensed)
        'enabled': 1,  # 0=none, 1=enabled, 2=disabled, 3=disabledbyparent
        'status': 'The virtual server is available',
        'va_name': 'vs_http_va',
        'pool_name': 'pool_http',
        'max_conns': 1000,
        'tot_conns': 0,
        'cur_conns': 0,
    },
    {
        'name': 'vs_https',
        'addr': '10.10.10.11',
        'port': 443,
        'availability': 1,
        'enabled': 1,
        'status': 'The virtual server is available',
        'va_name': 'vs_https_va',
        'pool_name': 'pool_https',
        'max_conns': 1000,
        'tot_conns': 0,
        'cur_conns': 0,
    },
    {
        'name': 'vs_app',
        'addr': '10.10.10.12',
        'port': 8080,
        'availability': 1,
        'enabled': 1,
        'status': 'The virtual server is available',
        'va_name': 'vs_app_va',
        'pool_name': 'pool_app',
        'max_conns': 1000,
        'tot_conns': 0,
        'cur_conns': 0,
    }
]

class F5Simulator:
    """F5 BIG-IP SNMP Simulator"""

    def __init__(self, host='localhost', port=161, community='public'):
        """Initialize the F5 simulator"""
        self.host = host
        self.port = port
        self.community = community
        self.snmp_engine = None
        self.virtual_servers = VIRTUAL_SERVERS
        self.start_time = datetime.now()

        # Initialize connection counters
        self.initialize_counters()

    def initialize_counters(self):
        """Initialize connection counters for virtual servers"""
        for vs in self.virtual_servers:
            vs['tot_conns'] = random.randint(10000, 50000)
            vs['cur_conns'] = random.randint(10, 100)

    def update_metrics(self):
        """Update metrics with simulated values"""
        for vs in self.virtual_servers:
            # Simulate new connections
            new_conns = random.randint(5, 20)
            vs['tot_conns'] += new_conns

            # Simulate current connections (some new, some closed)
            closed_conns = random.randint(0, vs['cur_conns'])
            vs['cur_conns'] = vs['cur_conns'] - closed_conns + new_conns

            # Ensure current connections don't exceed max
            vs['cur_conns'] = min(vs['cur_conns'], vs['max_conns'])

            # Randomly change availability state (mostly available)
            if random.random() < 0.05:  # 5% chance to change state
                vs['availability'] = random.choice([1, 2, 3])
                if vs['availability'] == 1:
                    vs['status'] = 'The virtual server is available'
                elif vs['availability'] == 2:
                    vs['status'] = 'The virtual server is not available'
                else:
                    vs['status'] = 'The virtual server is not available (down)'

    def setup_snmp_agent(self):
        """Set up the SNMP agent"""
        logger.info(f"Starting F5 SNMP simulator on {self.host}:{self.port}")

        # Create SNMP engine
        self.snmp_engine = engine.SnmpEngine()

        # Transport setup
        config.addTransport(
            self.snmp_engine,
            udp.domainName,
            udp.UdpTransport().openServerMode((self.host, self.port))
        )

        # SNMPv2c setup
        config.addV1System(self.snmp_engine, 'read-only', self.community)

        # Allow full read access for this community
        config.addVacmUser(self.snmp_engine, 2, 'read-only', 'noAuthNoPriv',
                          readSubTree=(1, 3, 6, 1, 4, 1), writeSubTree=())

        # Create MIB builder
        mib_builder = builder.MibBuilder()

        # Load MIB modules
        compiler.addMibCompiler(mib_builder, sources=[])
        mib_view_controller = view.MibViewController(mib_builder)

        # Register SNMP context
        snmp_context = context.SnmpContext(self.snmp_engine)
        snmp_context.registerContextName(
            v2c.OctetString(''),  # Default context
            mib_view_controller
        )

        # Register GET command responder
        cmdrsp.GetCommandResponder(self.snmp_engine, snmp_context)

        # Register GETNEXT command responder
        cmdrsp.NextCommandResponder(self.snmp_engine, snmp_context)

        # Register GETBULK command responder
        cmdrsp.BulkCommandResponder(self.snmp_engine, snmp_context)

        # Register MIB data
        self.register_mib_data(snmp_context)

        return self.snmp_engine

    def register_mib_data(self, snmp_context):
        """Register MIB data for the F5 OIDs"""
        mib_instrum = snmp_context.getMibInstrum(v2c.OctetString(''))

        # Register ltmVirtualServNumber
        oid = F5_OIDS['ltmVirtualServNumber']
        mib_instrum.writeVars(
            ((oid, rfc1902.Integer(len(self.virtual_servers))),)
        )

        # Register virtual server data
        for i, vs in enumerate(self.virtual_servers, 1):
            # Use index for OID suffix
            idx = f".{i}"

            # Register ltmVirtualServName
            oid = F5_OIDS['ltmVirtualServName'] + idx
            mib_instrum.writeVars(
                ((oid, rfc1902.OctetString(vs['name'])),)
            )

            # Register ltmVirtualServAddr
            oid = F5_OIDS['ltmVirtualServAddr'] + idx
            mib_instrum.writeVars(
                ((oid, rfc1902.OctetString(vs['addr'])),)
            )

            # Register ltmVirtualServPort
            oid = F5_OIDS['ltmVirtualServPort'] + idx
            mib_instrum.writeVars(
                ((oid, rfc1902.Integer(vs['port'])),)
            )

            # Register ltmVirtualServAvailabilityState
            oid = F5_OIDS['ltmVirtualServAvailabilityState'] + idx
            mib_instrum.writeVars(
                ((oid, rfc1902.Integer(vs['availability'])),)
            )

            # Register ltmVirtualServEnabledState
            oid = F5_OIDS['ltmVirtualServEnabledState'] + idx
            mib_instrum.writeVars(
                ((oid, rfc1902.Integer(vs['enabled'])),)
            )

            # Register ltmVirtualServStatusReason
            oid = F5_OIDS['ltmVirtualServStatusReason'] + idx
            mib_instrum.writeVars(
                ((oid, rfc1902.OctetString(vs['status'])),)
            )

            # Register ltmVirtualServVaName
            oid = F5_OIDS['ltmVirtualServVaName'] + idx
            mib_instrum.writeVars(
                ((oid, rfc1902.OctetString(vs['va_name'])),)
            )

            # Register ltmVirtualServStatClientMaxConns
            oid = F5_OIDS['ltmVirtualServStatClientMaxConns'] + idx
            mib_instrum.writeVars(
                ((oid, rfc1902.Counter64(vs['max_conns'])),)
            )

            # Register ltmVirtualServStatClientTotConns
            oid = F5_OIDS['ltmVirtualServStatClientTotConns'] + idx
            mib_instrum.writeVars(
                ((oid, rfc1902.Counter64(vs['tot_conns'])),)
            )

            # Register ltmVirtualServStatClientCurConns
            oid = F5_OIDS['ltmVirtualServStatClientCurConns'] + idx
            mib_instrum.writeVars(
                ((oid, rfc1902.Counter64(vs['cur_conns'])),)
            )

            # Register ltmVirtualServPoolPoolName
            oid = F5_OIDS['ltmVirtualServPoolPoolName'] + idx
            mib_instrum.writeVars(
                ((oid, rfc1902.OctetString(vs['pool_name'])),)
            )

    def run(self, update_interval=60):
        """Run the simulator"""
        try:
            # Set up SNMP agent
            self.setup_snmp_agent()

            logger.info(f"F5 simulator running with {len(self.virtual_servers)} virtual servers")
            logger.info(f"Updating metrics every {update_interval} seconds")

            # Main loop
            while True:
                # Update metrics
                self.update_metrics()

                # Re-register MIB data with updated values
                snmp_context = context.SnmpContext(self.snmp_engine)
                self.register_mib_data(snmp_context)

                # Log current state
                uptime = datetime.now() - self.start_time
                logger.info(f"Simulator uptime: {uptime}")
                for vs in self.virtual_servers:
                    logger.info(f"VS: {vs['name']}, Current Connections: {vs['cur_conns']}, "
                               f"Total Connections: {vs['tot_conns']}, "
                               f"State: {'Available' if vs['availability'] == 1 else 'Not Available'}")

                # Sleep until next update
                time.sleep(update_interval)

        except KeyboardInterrupt:
            logger.info("Shutting down F5 simulator...")
        except Exception as e:
            logger.error(f"Error in F5 simulator: {e}")
            raise

def parse_args():
    """Parse command line arguments"""
    parser = argparse.ArgumentParser(description='F5 BIG-IP SNMP Simulator')
    parser.add_argument('--host', default='0.0.0.0', help='SNMP agent host (default: 0.0.0.0)')
    parser.add_argument('--port', type=int, default=161, help='SNMP agent port (default: 161)')
    parser.add_argument('--community', default='public', help='SNMP community string (default: public)')
    parser.add_argument('--interval', type=int, default=60, help='Metrics update interval in seconds (default: 60)')
    return parser.parse_args()

if __name__ == '__main__':
    args = parse_args()

    # Check if running as root when using privileged port
    if args.port < 1024 and os.geteuid() != 0:
        logger.error("Port numbers below 1024 require root privileges.")
        logger.error("Please run with sudo or choose a port number >= 1024.")
        sys.exit(1)

    # Create and run simulator
    simulator = F5Simulator(args.host, args.port, args.community)
    simulator.run(args.interval)
