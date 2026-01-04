terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Backend S3 para armazenar estado do Terraform
  backend "s3" {
    bucket = "12soat-terraform-state-lambda"
    key    = "lambda-auth/terraform.tfstate"
    region = "us-east-1"
  }
}

provider "aws" {
  region = var.aws_region
}
