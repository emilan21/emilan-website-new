variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "account_id" {
  description = "AWS Account ID - different for test and prod"
  type        = string
}

variable "domain_name" {
  description = "Primary domain name - use test subdomain for test environment"
  type        = string
}

variable "s3_bucket_name" {
  description = "Name of the S3 bucket for website hosting - should be unique per environment"
  type        = string
}

variable "stage_name" {
  description = "API Gateway stage name - usually matches environment"
  type        = string
  default     = "prod"
}

variable "lambda_role_arn" {
  description = "ARN of the IAM role for Lambda execution"
  type        = string
}

variable "environment" {
  description = "Environment name (test, prod) - automatically set from workspace"
  type        = string
  default     = "prod"
}

variable "enable_www_redirect" {
  description = "Whether to create WWW redirect (usually only in prod)"
  type        = bool
  default     = true
}

variable "assume_role_arn" {
  description = "ARN of the role to assume (optional - defaults to AdministratorAccess in target account)"
  type        = string
  default     = ""
}
