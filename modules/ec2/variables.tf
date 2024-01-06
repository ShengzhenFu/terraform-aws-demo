variable "instance_type" {
  type        = string
  description = "ec2 instance type"
  default     = "t2.micro"
}

variable "vpc_id" {
  type        = string
  description = "the vpc id where ec2 instance located"
}
variable "cidr_vpc" {
  type        = string
  description = "vpc cidr"
}
variable "public_subnet_id" {
  type        = string
  description = "public subnet id where ec2 located"
}

variable "private_subnet_id" {
  type        = string
  description = "private subnet id where ec2 located"
}

variable "alb_arn" {
  type        = string
  description = "application load balancer arn"
}

variable "alb_sg_id" {
  type        = string
  description = "security group id of alb"
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