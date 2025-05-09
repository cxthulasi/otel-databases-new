# EMR on EC2 with OpenTelemetry Collector

This directory contains scripts and templates to set up an EC2 instance with EMR, run sample workloads, generate custom metrics, and configure the OpenTelemetry Collector to export these metrics to Coralogix.

## Prerequisites

- AWS CLI installed and configured with appropriate credentials
- An EC2 key pair for SSH access
- A Coralogix API key

## Files

- `emr-setup.yaml`: CloudFormation template to create the EC2 instance with EMR and OpenTelemetry Collector
- `deploy.sh`: Script to deploy the CloudFormation stack
- `cleanup.sh`: Script to delete the CloudFormation stack when no longer needed

## Deployment

1. Make the scripts executable:

```bash
chmod +x deploy.sh cleanup.sh
```

2. Deploy the CloudFormation stack:

```bash
./deploy.sh --key-name YOUR_KEY_PAIR_NAME --api-key YOUR_CORALOGIX_API_KEY
```

Additional options:
- `--stack-name NAME`: Set the CloudFormation stack name (default: EMR-Stack)
- `--region REGION`: AWS region (default: us-east-1)
- `--instance-type TYPE`: EC2 instance type (default: m5.xlarge)
- `--domain DOMAIN`: Coralogix domain (default: coralogix.com)

3. After deployment, the script will output the public DNS name and IP address of the EC2 instance. You can SSH into the instance using your key pair:

```bash
ssh -i /path/to/your-key-pair.pem ec2-user@PUBLIC_DNS_NAME
```

4. To check the setup progress, you can view the cloud-init output log:

```bash
tail -f /var/log/cloud-init-output.log
```

## What's Included

The CloudFormation template sets up:

1. An EC2 instance with:
   - Hadoop and Spark installed
   - Sample PySpark job that generates custom metrics
   - OpenTelemetry Collector configured to collect metrics from:
     - JMX metrics from Spark
     - Custom metrics from the sample job
     - Prometheus metrics from Spark endpoints
   - All metrics are exported to Coralogix

## Sample Workload

The sample PySpark job:
- Generates random data
- Performs simple transformations
- Logs custom metrics:
  - `emr.records.processed`: Number of records processed
  - `emr.processing.time`: Time taken to process the data
  - `emr.result.count`: Count of results after transformation

## Cleanup

When you're done with the EMR instance, you can delete the CloudFormation stack:

```bash
./cleanup.sh
```

Additional options:
- `--stack-name NAME`: Set the CloudFormation stack name (default: EMR-Stack)
- `--region REGION`: AWS region (default: us-east-1)

## Troubleshooting

If you encounter issues:

1. Check the cloud-init output log:
```bash
tail -f /var/log/cloud-init-output.log
```

2. Check the OpenTelemetry Collector logs:
```bash
journalctl -u otelcol-contrib
```

3. Verify that the sample job is running:
```bash
ps aux | grep sample_job
```

4. Check the custom metrics file:
```bash
cat /opt/emr-samples/metrics/custom_metrics.json
```
