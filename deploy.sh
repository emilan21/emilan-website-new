#!/bin/bash

# Multi-Environment Deployment Script for ericmilan.dev
# Usage: ./deploy.sh [test|prod] [plan|apply] [aws-profile]

set -e

ENVIRONMENT=$1
ACTION=$2
PROFILE_ARG=$3

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Validate arguments
if [ -z "$ENVIRONMENT" ] || [ -z "$ACTION" ]; then
    echo -e "${RED}Error: Missing arguments${NC}"
    echo "Usage: ./deploy.sh [test|prod] [plan|apply] [aws-profile]"
    echo ""
    echo "Examples:"
    echo "  ./deploy.sh test plan Administrator-509748725663    # Preview test changes"
    echo "  ./deploy.sh test apply Administrator-509748725663 # Deploy to test"
    echo "  ./deploy.sh prod plan Administrator-509748725663    # Preview prod changes"
    echo "  ./deploy.sh prod apply Administrator-509748725663  # Deploy to production"
    echo ""
    echo "Or set AWS_PROFILE environment variable before running:"
    echo "  export AWS_PROFILE=Administrator-509748725663"
    echo "  ./deploy.sh test apply"
    exit 1
fi

if [ "$ENVIRONMENT" != "test" ] && [ "$ENVIRONMENT" != "prod" ]; then
    echo -e "${RED}Error: Environment must be 'test' or 'prod'${NC}"
    exit 1
fi

if [ "$ACTION" != "plan" ] && [ "$ACTION" != "apply" ]; then
    echo -e "${RED}Error: Action must be 'plan' or 'apply'${NC}"
    exit 1
fi

# Check for AWS Profile in order of priority:
# 1. Command line argument (3rd arg)
# 2. AWS_PROFILE environment variable
# 3. Default credentials
if [ -n "$PROFILE_ARG" ]; then
    export AWS_PROFILE=$PROFILE_ARG
    echo -e "${GREEN}Using AWS Profile (from argument): $AWS_PROFILE${NC}"
elif [ -n "$AWS_PROFILE" ]; then
    echo -e "${GREEN}Using AWS Profile (from environment): $AWS_PROFILE${NC}"
else
    echo -e "${YELLOW}No AWS profile specified. Using default credentials.${NC}"
    echo "Tip: Set AWS_PROFILE environment variable or pass as 3rd argument"
fi

echo -e "${YELLOW}=== Deploying to $ENVIRONMENT environment ===${NC}"

# SSO login with the selected profile
echo -e "${GREEN}Step 1: Logging into AWS SSO...${NC}"
aws sso login

# Change to infrastructure directory
cd infrastructure/

# Initialize Terraform if needed
echo -e "${GREEN}Step 2: Initializing Terraform...${NC}"
terraform init

# Select workspace
echo -e "${GREEN}Step 3: Selecting $ENVIRONMENT workspace...${NC}"
if terraform workspace list | grep -q "$ENVIRONMENT"; then
    terraform workspace select $ENVIRONMENT
else
    echo -e "${YELLOW}Workspace $ENVIRONMENT doesn't exist. Creating...${NC}"
    terraform workspace new $ENVIRONMENT
fi

# Run Terraform
echo -e "${GREEN}Step 4: Running terraform $ACTION...${NC}"
if [ "$ACTION" == "plan" ]; then
    terraform plan -var-file=$ENVIRONMENT.tfvars
else
    # Extra confirmation for production
    if [ "$ENVIRONMENT" == "prod" ]; then
        echo -e "${RED}WARNING: You are about to apply changes to PRODUCTION!${NC}"
        read -p "Are you sure you want to continue? (yes/no): " confirm
        if [ "$confirm" != "yes" ]; then
            echo -e "${YELLOW}Deployment cancelled.${NC}"
            exit 0
        fi
    fi
    
    terraform apply -var-file=$ENVIRONMENT.tfvars
    
    # Save outputs
    echo -e "${GREEN}Step 5: Saving outputs...${NC}"
    terraform output -json > ../terraform-outputs-$ENVIRONMENT.json
    echo -e "${GREEN}Outputs saved to terraform-outputs-$ENVIRONMENT.json${NC}"
    
    # Show important outputs
    echo -e "${YELLOW}=== Important Information ===${NC}"
    echo "CloudFront Domain: $(terraform output -raw cloudfront_domain_name)"
    echo "S3 Bucket: $(terraform output -raw s3_bucket_name)"
    echo "API Gateway URL: $(terraform output -raw api_gateway_url)"
    
    if [ "$ENVIRONMENT" == "prod" ]; then
        echo "WWW CloudFront: $(terraform output -raw www_cloudfront_domain_name)"
    fi
fi

echo -e "${GREEN}=== Deployment complete! ===${NC}"
