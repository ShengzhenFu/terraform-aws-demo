variable "vpc_name" {
  type        = string
  description = "vpc name"
  default     = "test-vpc"
}

variable "availability_zones" {
  type        = list(string)
  description = "a list of availability zones in the target region"
  default     = ["us-west-2a", "us-west-2b", "us-west-2c"]
}

variable "cidr" {
  type        = string
  description = "vpc cidr"
  default     = "10.200.0.0/16"
}

variable "cidr_offset" {
  type        = number
  description = "offset that we pass to the cidrsubnet function to build subnets"
  default     = 8
}

variable "environment" {
  type        = string
  description = "environment type Test/Staging/Production"
  default     = "Test"
}

variable "iac" {
  type        = string
  description = "IaC type Terraform/CloudFormation/CDK"
  default     = "Terraform"
}

variable "system" {
  type        = string
  description = "System name A B C"
}

variable "app_owner" {
  type        = string
  description = "owner of the system"
}

variable "github_repo" {
  type        = string
  description = "repo of this IaC code"
}