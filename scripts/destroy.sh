#!/bin/bash

# DevOps Interview Assignment - Infrastructure Destruction Script
# This script destroys the complete infrastructure

set -e

# Configuration
STACK_NAME="devops-interview-stack"
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

# Check if stack exists
if ! aws cloudformation describe-stacks --stack-name $STACK_NAME --region $REGION &> /dev/null; then
    print_warning "Stack $STACK_NAME does not exist."
    exit 0
fi

# Confirm deletion
echo -e "${YELLOW}WARNING: This will destroy all resources in the stack $STACK_NAME${NC}"
read -p "Are you sure you want to continue? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_status "Deletion cancelled."
    exit 0
fi

# Delete the stack
print_status "Deleting stack $STACK_NAME..."
aws cloudformation delete-stack --stack-name $STACK_NAME --region $REGION

# Wait for stack deletion to complete
print_status "Waiting for stack deletion to complete..."
aws cloudformation wait stack-delete-complete --stack-name $STACK_NAME --region $REGION

print_status "Stack deletion completed successfully!"
print_status "All resources have been cleaned up."
