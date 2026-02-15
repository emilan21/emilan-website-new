# DNS Records to Create at Porkbun
# Copy these values and create the records in your Porkbun DNS management panel

output "dns_records_for_porkbun" {
  description = "DNS records to create at Porkbun"
  value = {
    # Root domain A record - points to CloudFront
    root_a_record = {
      type  = "ALIAS or CNAME"
      name  = "@"
      value = aws_cloudfront_distribution.website.domain_name
      note  = "Use ALIAS if Porkbun supports it, otherwise use CNAME (but CNAME at root may not work - see www redirect below)"
    }

    # WWW CNAME record - points to root domain
    www_cname = {
      type  = "CNAME"
      name  = "www"
      value = var.domain_name
    }

    # ACM Certificate Validation Records (Required!)
    # These prove you own the domain to AWS
    acm_validation = [
      for dvo in aws_acm_certificate.website.domain_validation_options : {
        type  = "CNAME"
        name  = dvo.resource_record_name
        value = dvo.resource_record_value
        note  = "Do not include the trailing dot in the name when creating at Porkbun"
      }
    ]
  }
}

# CloudFront Distribution Information
output "cloudfront_domain_name" {
  description = "CloudFront distribution domain name (for DNS A/ALIAS record)"
  value       = aws_cloudfront_distribution.website.domain_name
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID (for cache invalidation)"
  value       = aws_cloudfront_distribution.website.id
}

output "www_cloudfront_domain_name" {
  description = "WWW redirect CloudFront distribution domain name (only in prod)"
  value       = var.enable_www_redirect ? aws_cloudfront_distribution.www_redirect[0].domain_name : "N/A (not enabled)"
}

# API Gateway Information
output "api_gateway_url" {
  description = "API Gateway invoke URL for visitor counter"
  value       = aws_api_gateway_stage.prod.invoke_url
}

output "api_gateway_id" {
  description = "API Gateway REST API ID"
  value       = aws_api_gateway_rest_api.visitor_counter.id
}

# S3 Bucket Information
output "s3_bucket_name" {
  description = "S3 bucket name for website hosting"
  value       = aws_s3_bucket.website.bucket
}

output "s3_website_endpoint" {
  description = "S3 static website endpoint"
  value       = aws_s3_bucket_website_configuration.website.website_endpoint
}

# Certificate Information
output "certificate_arn" {
  description = "ACM certificate ARN"
  value       = aws_acm_certificate.website.arn
}

output "certificate_status" {
  description = "ACM certificate validation status"
  value       = aws_acm_certificate_validation.website.id
}

# Instructions
output "setup_instructions" {
  description = "Next steps after terraform apply"
  value       = <<-EOT
    
    === SETUP INSTRUCTIONS ===
    
    1. Create DNS records at Porkbun using the values in dns_records_for_porkbun output
    
    2. Wait for ACM certificate validation (can take 5-30 minutes)
       Run: terraform apply again after DNS records are created
    
    3. Update your frontend JavaScript (js/visitors.js) with the API Gateway URL:
       ${aws_api_gateway_stage.prod.invoke_url}/counts/get
       ${aws_api_gateway_stage.prod.invoke_url}/counts/increment
    
    4. Deploy frontend to S3:
       aws s3 sync frontend/ s3://${aws_s3_bucket.website.bucket}
    
    5. Invalidate CloudFront cache after deployment:
       aws cloudfront create-invalidation --distribution-id ${aws_cloudfront_distribution.website.id} --paths "/*"
    
    EOT
}
