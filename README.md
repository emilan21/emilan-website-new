# ericmilan.dev

Personal resume website with serverless visitor counter, hosted on AWS.

## Architecture

This is a static website with a serverless backend, deployed to AWS:

- **Frontend**: Static HTML/CSS/JavaScript hosted on S3
- **CDN**: CloudFront for global distribution and SSL
- **Backend**: Python Lambda functions for visitor counting
- **Database**: DynamoDB for storing visit counts
- **API**: API Gateway with CORS support
- **DNS**: Porkbun (domain registrar)
- **SSL**: AWS Certificate Manager (free, auto-renewing)

## Project Structure

```
ericmilan.dev/
├── frontend/           # Static website files
│   ├── index.html
│   ├── 404.html
│   ├── css/
│   ├── js/
│   └── files/
├── backend/            # Lambda function code
│   ├── get_visit_count.py
│   ├── increment_visit_count.py
│   └── delete_visit_count.py
├── infrastructure/     # Terraform configuration
│   ├── providers.tf
│   ├── variables.tf
│   ├── s3.tf
│   ├── cloudfront.tf
│   ├── lambda.tf
│   ├── api_gateway.tf
│   ├── dynamodb.tf
│   ├── acm.tf
│   └── outputs.tf
└── .github/workflows/  # CI/CD automation
```

## Prerequisites

- AWS CLI configured with appropriate credentials
- Terraform >= 1.0
- Porkbun account (for domain management)
- Domain registered at Porkbun: `ericmilan.dev`

## Setup Instructions

### 1. Domain Transfer to Porkbun (if needed)

Transfer your domain from Namecheap to Porkbun:
1. Unlock domain at Namecheap
2. Get EPP code from Namecheap
3. Initiate transfer at Porkbun
4. Wait 5-7 days for transfer to complete

### 2. Infrastructure Deployment

```bash
cd infrastructure/

# Copy example variables
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your AWS account ID

# Initialize Terraform
terraform init

# Plan deployment
terraform plan

# Apply deployment (this creates AWS resources but CloudFront won't work yet)
terraform apply
```

**Important**: After the first `terraform apply`, the certificate will be pending validation. You'll see output with DNS records to create at Porkbun.

### 3. DNS Configuration at Porkbun

Log into Porkbun and create these DNS records (shown in Terraform output):

**Required for ACM Certificate Validation:**
- CNAME records to prove domain ownership to AWS

**Required for Website:**
- ALIAS or CNAME record for root domain pointing to CloudFront
- CNAME record for www subdomain

### 4. Complete Infrastructure Setup

After DNS records propagate (5-30 minutes):

```bash
# Re-run terraform apply to complete certificate validation
terraform apply
```

### 5. Deploy Frontend

```bash
# Sync frontend files to S3
aws s3 sync frontend/ s3://eric-milan-dev-prod/

# Invalidate CloudFront cache
aws cloudfront create-invalidation --distribution-id <distribution-id> --paths "/*"
```

(Replace `<distribution-id>` with the ID from Terraform output)

### 6. Update API Endpoint

After API Gateway is deployed, update `frontend/js/visitors.js` and `frontend/js/increment_visitors.js` with the API Gateway URL from Terraform output.

## CI/CD (GitHub Actions)

The `.github/workflows/prod.yml` automatically:
1. Validates HTML
2. Runs tests with Cypress
3. Deploys to S3 on push to main
4. Invalidates CloudFront cache

Required GitHub Secrets:
- `AWS_ROLE_ARN`: IAM role for GitHub Actions OIDC

## Email Setup (Optional)

Porkbun offers free email forwarding:
1. Go to Domain > Email Forwarding in Porkbun
2. Set up forwarding for `emilan@ericmilan.dev`

Or use a free service like ImprovMX for more advanced email handling.

## Costs

Approximate monthly costs:
- S3: ~$0.50 (for low traffic)
- CloudFront: ~$0.50-$1.00
- Route53: $0 (not used - DNS at Porkbun)
- ACM Certificate: $0 (free)
- Lambda: $0 (within free tier)
- DynamoDB: $0 (on-demand, low usage)

**Total: ~$1-2/month**

## Maintenance

The setup is largely maintenance-free:
- SSL certificates auto-renew via ACM
- No servers to patch
- GitHub Actions handle deployments

## Terraform Destroy

**Warning**: This will delete all AWS resources!

```bash
cd infrastructure/
terraform destroy
```

Make sure to also:
1. Delete S3 bucket contents manually (if `force_destroy` doesn't work)
2. Remove DNS records from Porkbun

## License

MIT License - See LICENSE file
