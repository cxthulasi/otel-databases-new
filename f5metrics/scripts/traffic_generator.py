#!/usr/bin/env python3
"""
F5 Traffic Generator

This script simulates traffic to the F5 BIG-IP SNMP simulator by sending SNMP queries
at regular intervals. This helps to generate metrics that can be collected by the
OpenTelemetry SNMP receiver.
"""

import argparse
import logging
import random
import sys
import time
from pysnmp.hlapi import *

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger('traffic-generator')

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

class TrafficGenerator:
    """Traffic Generator for F5 BIG-IP SNMP Simulator"""
    
    def __init__(self, host='localhost', port=161, community='public'):
        """Initialize the traffic generator"""
        self.host = host
        self.port = port
        self.community = community
    
    def send_snmp_get(self, oid):
        """Send SNMP GET request for a specific OID"""
        try:
            iterator = getCmd(
                SnmpEngine(),
                CommunityData(self.community),
                UdpTransportTarget((self.host, self.port)),
                ContextData(),
                ObjectType(ObjectIdentity(oid))
            )
            
            errorIndication, errorStatus, errorIndex, varBinds = next(iterator)
            
            if errorIndication:
                logger.error(f"SNMP GET error: {errorIndication}")
                return None
            elif errorStatus:
                logger.error(f"SNMP GET error: {errorStatus.prettyPrint()} at {errorIndex and varBinds[int(errorIndex) - 1][0] or '?'}")
                return None
            else:
                for varBind in varBinds:
                    logger.debug(f"SNMP GET result: {varBind[0].prettyPrint()} = {varBind[1].prettyPrint()}")
                return varBinds
        except Exception as e:
            logger.error(f"Error sending SNMP GET: {e}")
            return None
    
    def send_snmp_walk(self, oid):
        """Send SNMP WALK request for a specific OID"""
        try:
            results = []
            for (errorIndication, errorStatus, errorIndex, varBinds) in nextCmd(
                SnmpEngine(),
                CommunityData(self.community),
                UdpTransportTarget((self.host, self.port)),
                ContextData(),
                ObjectType(ObjectIdentity(oid)),
                lexicographicMode=False
            ):
                if errorIndication:
                    logger.error(f"SNMP WALK error: {errorIndication}")
                    break
                elif errorStatus:
                    logger.error(f"SNMP WALK error: {errorStatus.prettyPrint()} at {errorIndex and varBinds[int(errorIndex) - 1][0] or '?'}")
                    break
                else:
                    for varBind in varBinds:
                        logger.debug(f"SNMP WALK result: {varBind[0].prettyPrint()} = {varBind[1].prettyPrint()}")
                        results.append(varBind)
            return results
        except Exception as e:
            logger.error(f"Error sending SNMP WALK: {e}")
            return None
    
    def generate_traffic(self, interval=10, duration=0):
        """Generate traffic by sending SNMP queries at regular intervals"""
        logger.info(f"Starting traffic generation to {self.host}:{self.port}")
        logger.info(f"Sending SNMP queries every {interval} seconds")
        
        start_time = time.time()
        query_count = 0
        
        try:
            while True:
                # Check if duration has been reached
                if duration > 0 and (time.time() - start_time) >= duration:
                    logger.info(f"Duration of {duration} seconds reached. Stopping traffic generation.")
                    break
                
                # Get number of virtual servers
                vs_num_result = self.send_snmp_get(F5_OIDS['ltmVirtualServNumber'])
                if vs_num_result:
                    vs_num = vs_num_result[0][1]
                    logger.info(f"Number of virtual servers: {vs_num}")
                
                # Randomly select OIDs to query
                oids_to_query = random.sample(list(F5_OIDS.items()), min(5, len(F5_OIDS)))
                
                for name, oid in oids_to_query:
                    if name == 'ltmVirtualServNumber':
                        self.send_snmp_get(oid)
                    else:
                        self.send_snmp_walk(oid)
                    
                    query_count += 1
                    
                    # Add some randomness to the traffic pattern
                    time.sleep(random.uniform(0.1, 0.5))
                
                logger.info(f"Sent {query_count} SNMP queries so far")
                
                # Wait until next interval
                time.sleep(interval)
                
        except KeyboardInterrupt:
            logger.info("Traffic generation stopped by user")
        except Exception as e:
            logger.error(f"Error in traffic generation: {e}")
            raise

def parse_args():
    """Parse command line arguments"""
    parser = argparse.ArgumentParser(description='F5 Traffic Generator')
    parser.add_argument('--host', default='localhost', help='SNMP agent host (default: localhost)')
    parser.add_argument('--port', type=int, default=161, help='SNMP agent port (default: 161)')
    parser.add_argument('--community', default='public', help='SNMP community string (default: public)')
    parser.add_argument('--interval', type=int, default=10, help='Traffic generation interval in seconds (default: 10)')
    parser.add_argument('--duration', type=int, default=0, help='Duration in seconds to run the traffic generator (default: 0, run indefinitely)')
    parser.add_argument('--debug', action='store_true', help='Enable debug logging')
    return parser.parse_args()

if __name__ == '__main__':
    args = parse_args()
    
    # Set log level
    if args.debug:
        logger.setLevel(logging.DEBUG)
    
    # Create and run traffic generator
    generator = TrafficGenerator(args.host, args.port, args.community)
    generator.generate_traffic(args.interval, args.duration)
