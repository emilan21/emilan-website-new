# Migration Guide: Namecheap to Porkbun + Monorepo Restructure

## Summary of Changes

This migration accomplishes:
1. **Domain Migration**: Move from Namecheap to Porkbun (cheaper, better interface)
2. **SSL Certificate**: Switch from imported Namecheap certs to AWS ACM (free, auto-renewing)
3. **DNS**: Move from Route53 to Porkbun DNS (saves ~$0.50/month)
4. **Repository Structure**: Consolidate from 3 repos to 1 monorepo
5. **Infrastructure**: Modernized Terraform with better practices

## What Was Changed

### 1. SSL Certificate (acm.tf)
**Before**: Imported Namecheap certificate files
```hcl
resource "aws_acm_certificate" "eric_milan_dev_prod" {
  private_key       = file("namecheap_ssl/private.key")
  certificate_body  = file("namecheap_ssl/ericmilan_dev.crt")
  certificate_chain = file("namecheap_ssl/ericmilan_dev.ca-bundle")
}
```

**After**: AWS ACM creates and manages certificates automatically
```hcl
resource "aws_acm_certificate" "website" {
  domain_name               = var.domain_name
  subject_alternative_names = ["www.${var.domain_name}"]
  validation_method         = "DNS"
  # Auto-renews, no manual management needed
}
```

### 2. DNS (Removed route53.tf)
**Before**: Route53 hosted zone with MX/TXT records for email
**After**: DNS managed entirely at Porkbun

**Benefits**:
- Saves ~$0.50/month (Route53 zone cost)
- One less AWS service to manage
- DNS and domain in one place (Porkbun)

### 3. Repository Structure
**Before**: 3 separate repositories
```
emilan-website/           # Frontend only
emilan-website-backend/   # Lambda code only  
emilan-aws/              # Terraform only
```

**After**: 1 monorepo
```
ericmilan.dev/
├── frontend/           # HTML/CSS/JS
├── backend/            # Lambda Python code
├── infrastructure/     # Terraform
└── test/              # Cypress tests
```

**Benefits**:
- Single source of truth
- Atomic changes across frontend/backend/infra
- Terraform can reference local Lambda files: `source_file = "${path.module}/../backend/get_visit_count.py"`
- One CI/CD pipeline for everything

### 4. Lambda File Paths (lambda.tf)
**Before**: Relative paths outside repo
```hcl
data "archive_file" "get_visit_count_lambda" {
  source_file = "../emilan-website-backend/get_visit_count.py"
}
```

**After**: Local paths within monorepo
```hcl
data "archive_file" "get_visit_count" {
  source_file = "${path.module}/../backend/get_visit_count.py"
}
```

### 5. CORS Configuration (api_gateway.tf)
**Before**: No CORS support - visitor counter would fail cross-origin
**After**: Full CORS support with OPTIONS methods and proper headers

### 6. WWW Redirect (s3.tf + cloudfront.tf)
**Before**: No www redirect
**After**: 
- Separate S3 bucket for www that redirects to root
- Separate CloudFront distribution for www
- Both use same SSL certificate

### 7. GitHub Actions Workflow
**Before**: Simple S3 sync only
**After**: Comprehensive CI/CD:
- HTML validation
- Python linting
- Terraform validation
- Infrastructure deployment
- Frontend deployment
- Smoke tests

## Migration Steps

### Step 1: Prepare New Repository
```bash
# Clone the new monorepo structure
git clone <your-new-repo-url> ericmilan.dev
cd ericmilan.dev

# Or if using this generated structure:
cp -r /home/emilan/personal/dev/emilan-website-new/* .
```

### Step 2: Configure Terraform
```bash
cd infrastructure/
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your AWS account ID and other values
```

### Step 3: Deploy Infrastructure
```bash
terraform init
terraform plan
terraform apply
```

**Note**: The first apply will create resources but the certificate will be pending validation. Save the DNS validation records from the output.

### Step 4: Transfer Domain to Porkbun (if not done)
1. Unlock domain at Namecheap
2. Get EPP code
3. Initiate transfer at Porkbun
4. Wait for transfer to complete

### Step 5: Configure DNS at Porkbun
1. Log into Porkbun
2. Go to Domain > Details for ericmilan.dev
3. Click "Edit" next to DNS Records
4. Create the records from Terraform output:
   - ACM validation CNAME records (required for SSL)
   - Root domain ALIAS/CNAME to CloudFront
   - WWW CNAME to root domain

### Step 6: Complete Certificate Validation
After DNS records propagate (5-30 minutes):
```bash
terraform apply
```

This will complete the certificate validation and enable HTTPS.

### Step 7: Update API URLs in Frontend
Edit `frontend/js/visitors.js` and `frontend/js/increment_visitors.js`:
```javascript
const API_BASE_URL = 'https://YOUR_API_ID.execute-api.us-east-1.amazonaws.com/prod';
```

Get the API ID from Terraform output or AWS Console.

### Step 8: Deploy Frontend
```bash
aws s3 sync frontend/ s3://eric-milan-dev-prod/
aws cloudfront create-invalidation --distribution-id $(terraform output -raw cloudfront_distribution_id) --paths "/*"
```

### Step 9: Test
1. Visit https://ericmilan.dev
2. Check that visitor counter works
3. Test www.ericmilan.dev redirects to root
4. Verify SSL certificate is valid

### Step 10: Set Up GitHub Actions
1. Go to GitHub repository Settings > Secrets and variables > Actions
2. Add secret: `AWS_ROLE_ARN` (your OIDC role ARN)
3. Add variable: `S3_BUCKET_NAME` = `eric-milan-dev-prod`
4. Add variable: `CLOUDFRONT_ID` (from Terraform output)

## Rollback Plan

If something goes wrong:

1. **DNS Issues**: Point Porkbun DNS back to old Namecheap nameservers temporarily
2. **Certificate Issues**: Can use CloudFront default certificate (*.cloudfront.net) temporarily
3. **Infrastructure Issues**: Run `terraform destroy` to remove AWS resources
4. **Complete Rollback**: Restore from backup or use old repository

## Post-Migration Checklist

- [ ] Domain transferred to Porkbun
- [ ] DNS records created at Porkbun
- [ ] SSL certificate validated and active
- [ ] Website accessible via HTTPS
- [ ] WWW redirect working
- [ ] Visitor counter functioning
- [ ] GitHub Actions deploying successfully
- [ ] Email forwarding configured (optional)
- [ ] Old Namecheap resources cleaned up
- [ ] Old repositories archived/deprecated

## Support

If you encounter issues:
1. Check Terraform outputs for DNS record values
2. Verify ACM certificate status in AWS Console
3. Check CloudFront distribution status
4. Review Lambda CloudWatch logs for API errors
5. Test API Gateway directly in AWS Console
