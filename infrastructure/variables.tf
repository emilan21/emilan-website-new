variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "account_id" {
  description = "AWS Account ID"
  type        = string
}

variable "domain_name" {
  description = "Primary domain name for the website"
  type        = string
  default     = "ericmilan.dev"
}

variable "s3_bucket_name" {
  description = "Name of the S3 bucket for website hosting"
  type        = string
  default     = "eric-milan-dev-prod"
}

variable "stage_name" {
  description = "API Gateway stage name"
  type        = string
  default     = "prod"
}

variable "lambda_role_arn" {
  description = "ARN of the IAM role for Lambda execution"
  type        = string
}
