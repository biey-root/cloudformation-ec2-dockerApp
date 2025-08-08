#!/bin/bash

# DevOps Interview Assignment - Infrastructure Deployment Script
# This script deploys the complete infrastructure using CloudFormation

set -e

# Configuration
STACK_NAME="devops-interview-stack"
TEMPLATE_FILE="cloudformation/main.yaml"
PARAMETERS_FILE="cloudformation/parameters.json"
REGION="ap-southeast-1"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    print_error "AWS CLI is not installed. Please install it first."
    exit 1
fi

# Check if AWS credentials are configured
if ! aws sts get-caller-identity &> /dev/null; then
    print_error "AWS credentials are not configured. Please run 'aws configure' first."
    exit 1
fi

# Check if required files exist
if [ ! -f "$TEMPLATE_FILE" ]; then
    print_error "Template file $TEMPLATE_FILE not found."
    exit 1
fi

if [ ! -f "$PARAMETERS_FILE" ]; then
    print_error "Parameters file $PARAMETERS_FILE not found."
    exit 1
fi

# Validate CloudFormation template
print_status "Validating CloudFormation template..."
if aws cloudformation validate-template --template-body file://$TEMPLATE_FILE --region $REGION; then
    print_status "Template validation successful."
else
    print_error "Template validation failed."
    exit 1
fi

# Check if stack already exists
if aws cloudformation describe-stacks --stack-name $STACK_NAME --region $REGION &> /dev/null; then
    print_warning "Stack $STACK_NAME already exists. Updating..."
    OPERATION="update-stack"
else
    print_status "Creating new stack $STACK_NAME..."
    OPERATION="create-stack"
fi

# Deploy the stack
print_status "Deploying infrastructure..."
aws cloudformation $OPERATION \
    --template-body file://$TEMPLATE_FILE \
    --capabilities CAPABILITY_NAMED_IAM \
    --stack-name $STACK_NAME \
    --parameters file://$PARAMETERS_FILE \
    --region $REGION

# Wait for stack to complete
print_status "Waiting for stack operation to complete..."
aws cloudformation wait stack-$([ "$OPERATION" = "create-stack" ] && echo "create" || echo "update")-complete \
    --stack-name $STACK_NAME \
    --region $REGION

# Get stack outputs
print_status "Retrieving stack outputs..."
aws cloudformation describe-stacks \
    --stack-name $STACK_NAME \
    --region $REGION \
    --query 'Stacks[0].Outputs' \
    --output table

print_status "Deployment completed successfully!"
print_status "You can now access your infrastructure using the outputs above."
