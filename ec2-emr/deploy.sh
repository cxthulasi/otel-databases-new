#!/bin/bash

# Script to deploy the EMR CloudFormation stack

set -e  # Exit on error

# Default values
STACK_NAME="EMR-Stack"
REGION="us-east-1"
INSTANCE_TYPE="m5.xlarge"
CORALOGIX_DOMAIN="coralogix.com"

# Display help
function show_help {
  echo "Usage: $0 [options]"
  echo "Options:"
  echo "  -h, --help                 Show this help message"
  echo "  -n, --stack-name NAME      Set the CloudFormation stack name (default: EMR-Stack)"
  echo "  -k, --key-name NAME        EC2 KeyPair name for SSH access (required)"
  echo "  -r, --region REGION        AWS region (default: us-east-1)"
  echo "  -t, --instance-type TYPE   EC2 instance type (default: m5.xlarge)"
  echo "  -a, --api-key KEY          Coralogix API key (required)"
  echo "  -d, --domain DOMAIN        Coralogix domain (default: coralogix.com)"
  echo ""
  echo "Example:"
  echo "  $0 --key-name MyKeyPair --api-key YOUR_CORALOGIX_API_KEY"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  key="$1"
  case $key in
    -h|--help)
      show_help
      exit 0
      ;;
    -n|--stack-name)
      STACK_NAME="$2"
      shift 2
      ;;
    -k|--key-name)
      KEY_NAME="$2"
      shift 2
      ;;
    -r|--region)
      REGION="$2"
      shift 2
      ;;
    -t|--instance-type)
      INSTANCE_TYPE="$2"
      shift 2
      ;;
    -a|--api-key)
      CORALOGIX_API_KEY="$2"
      shift 2
      ;;
    -d|--domain)
      CORALOGIX_DOMAIN="$2"
      shift 2
      ;;
    *)
      echo "Unknown option: $1"
      show_help
      exit 1
      ;;
  esac
done

# Check required parameters
if [ -z "$KEY_NAME" ]; then
  echo "Error: EC2 KeyPair name is required."
  show_help
  exit 1
fi

if [ -z "$CORALOGIX_API_KEY" ]; then
  echo "Error: Coralogix API key is required."
  show_help
  exit 1
fi

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
  echo "Error: AWS CLI is not installed. Please install it first."
  exit 1
fi

# Deploy CloudFormation stack
echo "Deploying CloudFormation stack '$STACK_NAME' in region '$REGION'..."
aws cloudformation deploy \
  --template-file emr-setup.yaml \
  --stack-name "$STACK_NAME" \
  --parameter-overrides \
    KeyName="$KEY_NAME" \
    InstanceType="$INSTANCE_TYPE" \
    CoralogixApiKey="$CORALOGIX_API_KEY" \
    CoralogixDomain="$CORALOGIX_DOMAIN" \
  --capabilities CAPABILITY_IAM \
  --region "$REGION"

# Get stack outputs
echo "Retrieving stack outputs..."
aws cloudformation describe-stacks \
  --stack-name "$STACK_NAME" \
  --query "Stacks[0].Outputs" \
  --output table \
  --region "$REGION"

echo "EMR stack deployment completed successfully!"
echo "Note: It may take a few minutes for the EC2 instance to complete the setup process."
echo "You can SSH into the instance using your key pair and check the setup progress with:"
echo "  tail -f /var/log/cloud-init-output.log"
