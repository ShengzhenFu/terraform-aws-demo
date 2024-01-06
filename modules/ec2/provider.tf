terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.31.0"
    }
  }
}

provider "aws" {
  default_tags {
    tags = {
      System      = var.system
      Environment = var.environment
      IaC         = var.iac
      Owner       = var.app_owner
      Github      = var.github_repo
    }
  }
}