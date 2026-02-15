# Request an SSL certificate from AWS Certificate Manager
# This is FREE and automatically renews
resource "aws_acm_certificate" "website" {
  domain_name               = var.domain_name
  subject_alternative_names = ["www.${var.domain_name}"]
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name        = "${var.domain_name}-certificate"
    Environment = "prod"
  }
}

# This resource waits for the certificate to be validated
# Note: You'll need to manually create DNS validation records at Porkbun
#       using the outputs from this module, or use the data source to 
#       create validation records automatically if you prefer to use Route53
resource "aws_acm_certificate_validation" "website" {
  certificate_arn = aws_acm_certificate.website.arn

  # Validation records must be created in DNS before this can complete
  # See outputs for the required DNS records
}
