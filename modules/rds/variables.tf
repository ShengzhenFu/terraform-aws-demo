variable "cluster_identifier" {
  description = "The name of the RDS instance"
  type        = string
}

variable "use_identifier_prefix" {
  type        = bool
  description = "Determines whether to use `identifier` as is or create a unique identifier beginning with `identifier` as the specific prefix"
  default     = false
}

variable "db_secret_name" {
  type        = string
  description = "the name of the aws secret for the DB password"
  default     = "posgresCreds"
}

variable "private_isolated_subnet_ids" {
  description = "subnet ids of the isolated subnet"
  type        = list(string)
}

variable "engine" {
  type        = string
  description = "engine of RDS"
  default     = "null"
}

variable "engine_version" {
  description = "the version of engine"
  type        = string
  default     = null
}

variable "db_cluster_instance_class" {
  description = "the db instance type of RDS"
  type        = string
  default     = "db.m5d.xlarge"
}

variable "database_name" {
  description = "the name of the DB"
  type        = string
  default     = null
}

variable "master_username" {
  description = "username of DB"
  type        = string
  default     = null
}

variable "master_password" {
  description = "password of the DB, note this might be show up in state file"
  type        = string
  default     = null
}

variable "port" {
  description = "port of the DB"
  type        = string
  default     = "5432"
}

variable "vpc_security_group_ids" {
  description = "list of security groups to control access to RDS"
  type        = list(string)
  default     = null
}

variable "db_subnet_group_name" {
  description = "name of db subnet group"
  type        = string
  default     = null
}

variable "db_cluster_parameter_group_name" {
  description = "name of the db parameter group"
  type        = string
  default     = null
}

variable "availability_zone" {
  description = "the availability zone of the RDS"
  type        = string
  default     = null
}

variable "multi_az" {
  description = "flag of RDS instance is multi-AZ"
  type        = bool
  default     = true
}

variable "iops" {
  description = "the proviioned IOPS. it is required when storage type equal to io1"
  type        = number
  default     = 1000
}

variable "allow_major_version_upgrade" {
  description = "if major version upgrade allowed"
  type        = bool
  default     = false
}

variable "auto_minor_version_upgrade" {
  description = "if minor version upgrade allowed"
  type        = bool
  default     = true
}

variable "preferred_maintenance_window" {
  description = "the window to perform maintenance. Syntax: ddd:hh24:mi-ddd:hh24:mi. eg Mon:00:00-Mon:-3:00"
  type        = string
  default     = null
}

variable "backup_retention_period" {
  description = "retention days of the backup"
  type        = number
  default     = null
}

variable "preferred_backup_window" {
  description = "time range for the auto backup to run, eg 09:00-11:00, not allow overlap with maintenance window"
  type        = string
  default     = null
}

variable "tags" {
  description = "a mapping of tags to the resources"
  type        = map(string)
  default     = {}
}

variable "allocated_storage" {
  description = "storage allocated to the DB in GB"
  type        = string
  default     = null
}

variable "storage_type" {
  description = "storage type, io1, gp2, gp3 ..."
  type        = string
  default     = "io1"
}

variable "storage_encrypted" {
  description = "flag of DB encrypted or not"
  type        = bool
  default     = true
}

variable "kms_key_id" {
  description = "the ARN of kms key"
  type        = string
  default     = null
}

variable "iam_database_authentication_enabled" {
  description = "flag of IAM authenticate enabled to access RDS or not"
  type        = bool
  default     = false
}

variable "network_type" {
  description = "the type of network"
  type        = string
  default     = null
}

variable "apply_immediately" {
  description = "flag of updates to the DB applied immediately or wait until next maintenance window"
  type        = bool
  default     = false
}

variable "enabled_cloudwatch_logs_exports" {
  description = "list of cloudwatch logs for DB"
  type        = list(string)
  default     = []
}

variable "deletion_protection" {
  description = "the flag of allow db deletion once created"
  type        = bool
  default     = false
}


# cloudwatch logs group

variable "create_cloudwatch_log_group" {
  description = "flag of create cloudwatch log group or not"
  type        = bool
  default     = false
}

variable "cloudwatch_log_group_retention_in_days" {
  description = "days to retain cloudwatch logs for DB"
  type        = number
  default     = 7
}
variable "cloudwatch_log_group_kms_key_id" {
  description = "ARN of kms key to encrypt logs"
  type        = string
  default     = null
}


# tags

variable "environment" {
  type        = string
  description = "environment dev/stage/prod"
  default     = "dev"
}

variable "system" {
  description = "system name"
  type        = string
}

variable "iac" {
  description = "IaC type, eg: Terraform/CloudFormation/CDK"
  type        = string
  default     = "Terraform"
}

variable "app_owner" {
  description = "owner of the system"
  type        = string
}

variable "github_repo" {
  description = "the repo where the IaC code stored"
  type        = string
}