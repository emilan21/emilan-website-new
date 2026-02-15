terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.4"
    }
  }
}

# Local values for environment detection
locals {
  environment   = terraform.workspace
  is_production = terraform.workspace == "prod"
}

# Configure the AWS Provider
# Uses SSO profiles directly - no cross-account assume role needed
# Configure profiles in ~/.aws/config for each account
provider "aws" {
  region = var.region
  # Profile is set via AWS_PROFILE environment variable or defaults to empty
  # This allows you to use: export AWS_PROFILE=your-profile-name
}

# Configure the archive Provider
provider "archive" {}

# Backend configuration for state management (optional but recommended)
# Uncomment and configure if you want to store state in S3
# terraform {
#   backend "s3" {
#     bucket         = "ericmilan-terraform-state"
#     key            = "infrastructure/terraform.tfstate"
#     region         = "us-east-1"
#     encrypt        = true
#     dynamodb_table = "terraform-locks"
#   }
# }
