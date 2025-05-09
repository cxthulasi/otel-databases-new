#!/bin/bash

# Script to delete the EMR CloudFormation stack

set -e  # Exit on error

# Default values
STACK_NAME="EMR-Stack"
REGION="us-east-1"

# Display help
function show_help {
  echo "Usage: $0 [options]"
  echo "Options:"
  echo "  -h, --help                 Show this help message"
  echo "  -n, --stack-name NAME      Set the CloudFormation stack name (default: EMR-Stack)"
  echo "  -r, --region REGION        AWS region (default: us-east-1)"
  echo ""
  echo "Example:"
  echo "  $0 --stack-name MyEMRStack --region us-west-2"
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
    -r|--region)
      REGION="$2"
      shift 2
      ;;
    *)
      echo "Unknown option: $1"
      show_help
      exit 1
      ;;
  esac
done

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
  echo "Error: AWS CLI is not installed. Please install it first."
  exit 1
fi

# Confirm deletion
read -p "Are you sure you want to delete the CloudFormation stack '$STACK_NAME' in region '$REGION'? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo "Deletion cancelled."
  exit 0
fi

# Delete CloudFormation stack
echo "Deleting CloudFormation stack '$STACK_NAME' in region '$REGION'..."
aws cloudformation delete-stack \
  --stack-name "$STACK_NAME" \
  --region "$REGION"

echo "Waiting for stack deletion to complete..."
aws cloudformation wait stack-delete-complete \
  --stack-name "$STACK_NAME" \
  --region "$REGION"

echo "EMR stack deletion completed successfully!"
