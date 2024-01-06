# Author Shengzhen Fu
# Created: 7/Dec/2023

locals {
  availability_zone1 = "us-west-2a"
  availability_zone2 = "us-west-2b"
  availability_zone3 = "us-west-2c"
  instance_type      = "t3.micro"
  environment        = "Dev"
  region             = "us-west-2"
  cidr               = "10.186.0.0/16"
}

module "vpc" {
  source             = "./modules/vpc"
  vpc_name           = "test-infra-vpc"
  cidr               = local.cidr
  cidr_offset        = 8
  availability_zones = [local.availability_zone1, local.availability_zone2, local.availability_zone3]
  environment        = local.environment
  iac                = "Terraform"
  system             = "Test App"
  app_owner          = "infraTeam"
  github_repo        = "test repo"
}

module "ec2" {
  source            = "./modules/ec2"
  instance_type     = local.instance_type
  vpc_id            = module.vpc.vpc_id
  cidr_vpc          = local.cidr
  public_subnet_id  = element(module.vpc.public_subnet_ids, 0)
  alb_arn           = module.vpc.alb_arn
  alb_sg_id         = module.vpc.alb_sg_id
  private_subnet_id = element(module.vpc.private_subnet_ids, 0)
  environment       = local.environment
  iac               = "Terraform"
  system            = "Test App"
  app_owner         = "infraTeam"
  github_repo       = "test repo"
}