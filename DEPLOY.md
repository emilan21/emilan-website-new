# Multi-Environment Deployment Guide

## Overview

This setup supports **test** and **production** environments across your AWS Organizations using Terraform workspaces.

## Architecture

```
AWS Organizations
├── Test Account (123456789012)
│   ├── test.ericmilan.dev
│   └── S3: eric-milan-dev-test
│
└── Prod Account (518835924951)
    ├── ericmilan.dev
    ├── www.ericmilan.dev (redirect)
    └── S3: eric-milan-dev-prod
```

## Prerequisites

1. **AWS SSO configured** for each account
2. **AWS Organizations** with test and prod accounts set up
3. **DNS subdomain** for test: `test.ericmilan.dev`

## Initial Setup

### 1. Configure AWS SSO Profiles

Configure SSO profiles in `~/.aws/config` for each account:

```ini
[profile test]
sso_start_url = https://d-90678c36f8.awsapps.com/start
sso_region = us-east-1
sso_account_id = YOUR_TEST_ACCOUNT_ID
sso_role_name = AdministratorAccess
region = us-east-1

[profile prod]
sso_start_url = https://d-90678c36f8.awsapps.com/start
sso_region = us-east-1
sso_account_id = 518835924951
sso_role_name = AdministratorAccess
region = us-east-1
```

Replace `YOUR_TEST_ACCOUNT_ID` with your actual test account ID.

### 2. Create Environment Variable Files

```bash
cd infrastructure/

# Copy examples
cp test.tfvars.example test.tfvars
cp prod.tfvars.example prod.tfvars

# Edit with your actual values
nano test.tfvars  # Update with your TEST account ID
nano prod.tfvars  # Prod account ID already set: 518835924951
```

### 3. Verify Terraform Providers

The `providers.tf` is configured to use AWS credentials from environment variables or your default AWS profile. It will use whatever profile you're currently authenticated with.

## Deploy Test Environment

### Step 1: Login with SSO for Test Account
```bash
aws sso login --profile test
```

### Step 2: Deploy Using the Script
```bash
./deploy.sh test apply test
```

Or manually:
```bash
cd infrastructure/
terraform workspace select test  # Create with: terraform workspace new test
terraform init
terraform plan -var-file=test.tfvars
terraform apply -var-file=test.tfvars
```

### Step 3: Deploy Test Infrastructure
```bash
terraform init
terraform plan -var-file=test.tfvars
terraform apply -var-file=test.tfvars
```

**Note**: For test environment, you'll see outputs for:
- CloudFront domain (no SSL initially)
- ACM validation records (if using SSL)
- API Gateway URL

### Step 4: Create Test DNS Record (Optional)

If you want SSL on test:
1. Add CNAME record at Porkbun: `test` → CloudFront domain
2. Create ACM validation records from Terraform output
3. Wait 5-30 minutes
4. Run `terraform apply -var-file=test.tfvars` again

### Step 5: Test the API
```bash
# Get the API URL from terraform output
terraform output api_gateway_url

# Test it
curl -X POST $(terraform output -raw api_gateway_url)/counts/get \
  -H "Content-Type: application/json" \
  -d '{"id": 0}'
```

### Step 6: Deploy Frontend to Test
```bash
# From project root
aws s3 sync frontend/ s3://eric-milan-dev-test/ --profile test
aws cloudfront create-invalidation \
  --distribution-id $(terraform output -raw cloudfront_distribution_id) \
  --profile test \
  --paths "/*"
```

### Step 7: Test the Website
Visit: `http://test.ericmilan.dev` (or `https://` if SSL is configured)

## Deploy Production Environment

### Step 1: Login with SSO for Prod Account
```bash
aws sso login --profile prod
```

### Step 2: Deploy Using the Script
```bash
./deploy.sh prod apply prod
```

Or manually:
```bash
cd infrastructure/
terraform workspace select prod
terraform init
terraform plan -var-file=prod.tfvars
terraform apply -var-file=prod.tfvars
```

**First apply** creates resources with certificate pending validation.

### Step 4: Create DNS Records at Porkbun

From Terraform output, create:
1. **ACM Validation CNAMEs** (required for SSL) - usually 2 records
2. **Root A/ALIAS** record → CloudFront domain
3. **WWW CNAME** → ericmilan.dev

### Step 5: Complete Certificate Validation

Wait 5-30 minutes for DNS propagation, then:
```bash
terraform apply -var-file=prod.tfvars
```

### Step 6: Update Frontend API URLs

Edit `frontend/js/visitors.js` and `frontend/js/increment_visitors.js`:

```javascript
const API_BASE_URL = 'https://YOUR_PROD_API_ID.execute-api.us-east-1.amazonaws.com/prod';
```

Get the API ID from: `terraform output -raw api_gateway_id`

### Step 7: Deploy Frontend to Prod
```bash
aws s3 sync frontend/ s3://eric-milan-dev-prod/ --profile prod
aws cloudfront create-invalidation \
  --distribution-id $(terraform output -raw cloudfront_distribution_id) \
  --profile prod \
  --paths "/*"
```

### Step 8: Verify Production
- Visit: https://ericmilan.dev
- Check: https://www.ericmilan.dev (should redirect)
- Verify SSL certificate (padlock in browser)
- Test visitor counter

## Switching Between Environments

Since you're using SSO directly with separate profiles for each account:

```bash
# Deploy to test
aws sso login --profile test
./deploy.sh test apply test

# Deploy to prod (need to login again with different profile)
aws sso login --profile prod
./deploy.sh prod apply prod
```

## Environment Differences

| Feature | Test | Production |
|---------|------|------------|
| Domain | test.ericmilan.dev | ericmilan.dev |
| WWW Redirect | No | Yes |
| SSL | Optional | Required |
| Bucket | eric-milan-dev-test | eric-milan-dev-prod |
| Account | Test AWS Account | Prod AWS Account |
| Cost | ~$1/month | ~$1-2/month |

## CI/CD with GitHub Actions

The `.github/workflows/deploy.yml` supports multi-environment deployment:

### Setup GitHub Secrets

For each environment, add these secrets in GitHub:

**Environment: test**
- `AWS_ROLE_ARN_TEST`: IAM role ARN for test account

**Environment: production**
- `AWS_ROLE_ARN_PROD`: IAM role ARN for prod account

### GitHub Variables

Add repository variables:
- `S3_BUCKET_TEST`: eric-milan-dev-test
- `S3_BUCKET_PROD`: eric-milan-dev-prod
- `CLOUDFRONT_ID_TEST`: Test distribution ID
- `CLOUDFRONT_ID_PROD`: Prod distribution ID

### Deployment Flow

1. Push to `main` branch → Deploys to **test** automatically
2. Manual approval → Deploys to **production**
3. (Or set up branch protection for prod deployment)

## Cost Summary

**Test Environment**: ~$1/month
- S3: $0.50
- CloudFront: $0.50

**Production Environment**: ~$1-2/month
- S3: $0.50
- CloudFront: $0.50-$1
- Route53: $0 (DNS at Porkbun)

**Total**: ~$2-3/month for both environments

## Troubleshooting

### Wrong Account/Permission Errors
```bash
# Verify you're using the right profile
aws sts get-caller-identity --profile test
aws sts get-caller-identity --profile prod

# Check workspace
cd infrastructure/
terraform workspace list
terraform workspace show
```

### Certificate Validation Fails
- Ensure you're creating CNAME records in the **correct** Porkbun account
- Test environment uses `test.ericmilan.dev` subdomain
- Remove trailing dots from CNAME names

### Cross-Account Access Issues
If you use IAM roles to switch accounts:
```hcl
provider "aws" {
  region = var.region
  assume_role {
    role_arn = "arn:aws:iam::${var.account_id}:role/TerraformExecutionRole"
  }
}
```

### Workspace Doesn't Exist
```bash
# Create the workspace
cd infrastructure/
terraform workspace new test
terraform workspace new prod
```

## Best Practices

1. **Always test in test first** - Deploy features to test environment before prod
2. **Use separate tfvars files** - Never commit actual values to git
3. **Tag resources** - All resources are tagged with environment name
4. **SSO login before deploying** - Don't forget `aws sso login --profile <env>`
5. **Review terraform plan** - Always check what will change before applying
6. **Keep environments isolated** - Don't share S3 buckets or databases between envs

## Quick Reference

### Using the Deploy Script (Recommended)
```bash
# Deploy to test
aws sso login --profile test
./deploy.sh test apply test

# Deploy to prod
aws sso login --profile prod
./deploy.sh prod apply prod
```

### Manual Deployment
```bash
# Deploy to test
aws sso login --profile test
cd infrastructure/
terraform workspace select test
terraform plan -var-file=test.tfvars
terraform apply -var-file=test.tfvars

# Deploy to prod
aws sso login --profile prod
terraform workspace select prod
terraform plan -var-file=prod.tfvars
terraform apply -var-file=prod.tfvars
```

### Using Environment Variable
```bash
# Set profile once for the session
export AWS_PROFILE=test
./deploy.sh test apply

# Switch to prod
export AWS_PROFILE=prod
./deploy.sh prod apply
```
