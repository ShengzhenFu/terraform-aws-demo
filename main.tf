# Author Shengzhen Fu
# Created: 7/Dec/2023

locals {
  availability_zone1 = "us-west-2a"
  availability_zone2 = "us-west-2b"
  availability_zone3 = "us-west-2c"
  # ec2
  instance_type = "t3.micro"
  environment   = "Dev"
  region        = "us-west-2"
  cidr          = "10.186.0.0/16"
  # rds
  rds_identifier    = "postgres"
  db_instance_type  = "db.m5d.large"
  db_engine         = "postgres"
  db_engine_version = "15.4"
  db_storage_size   = 150
  db_storage_type   = "io1"
  db_iops           = 1000
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

module "rds" {
  source                    = "./modules/rds"
  cluster_identifier        = "${local.rds_identifier}-${local.environment}"
  engine                    = local.db_engine
  engine_version            = local.db_engine_version
  db_cluster_instance_class = local.db_instance_type
  allocated_storage         = local.db_storage_size
  storage_type              = local.db_storage_type
  iops                      = local.db_iops

  database_name               = "postgres"
  port                        = "5432"
  vpc_security_group_ids      = [module.vpc.rds_sg_id]
  private_isolated_subnet_ids = module.vpc.private_isolated_subnet_ids

  deletion_protection         = false
  allow_major_version_upgrade = false

  environment = local.environment
  iac         = "Terraform"
  system      = "Test App"
  app_owner   = "infraTeam"
  github_repo = "test repo"

}