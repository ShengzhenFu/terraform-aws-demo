locals {
  cluster_identifier        = var.use_identifier_prefix ? null : var.cluster_identifier
  cluster_identifier_prefix = var.use_identifier_prefix ? "${var.cluster_identifier}-" : null
}

data "aws_partition" "current" {}

# Generate random password
resource "random_password" "password" {
  length           = 16
  special          = true
  override_special = "_%@"
}

# Generate a random postfix for the secret name to avoid duplicate when re-provisioning
resource "random_string" "postfix" {
  length  = 3
  special = false
}

# Create a secret in AWS Secrets Manager
resource "aws_secretsmanager_secret" "secretDB" {
  name = "{var.db_secret_name}-${random_string.postfix.result}"
}

resource "aws_secretsmanager_secret_version" "secretversion" {
  secret_id     = aws_secretsmanager_secret.secretDB.id
  secret_string = <<EOF
    {
        "username": "postgres",
        "password": "${random_password.password.result}"
    }
  EOF
}

data "aws_secretsmanager_secret" "secretDB" {
  arn = aws_secretsmanager_secret.secretDB.arn
}

data "aws_secretsmanager_secret_version" "secretversion" {
  secret_id = aws_secretsmanager_secret.secretDB.arn
}

locals {
  db_creds = jsondecode(data.aws_secretsmanager_secret_version.secretversion.secret_string)
}

# RDS parameter group
resource "aws_rds_cluster_parameter_group" "aws_rds_cluster_parameter_group" {
  name        = "rds-cluster-parameter-group-${var.environment}"
  description = "parameter group of postgres RDS"
  family      = "postgres15"
  lifecycle {
    create_before_destroy = true
  }
  tags = { Name : "rds-cluster-parameter-group-${var.environment}" }
}

# subnet group
resource "aws_db_subnet_group" "rds_subnet_group" {
  name        = "rds-subnet-group-${var.environment}"
  description = "db subnet group of RDS"
  subnet_ids  = var.private_isolated_subnet_ids
  tags        = { Name : "rds-subnet-group-${var.environment}" }
}

# multiaz RDS Postgres
resource "aws_rds_cluster" "rds_cluster" {
  cluster_identifier = var.cluster_identifier

  engine                    = var.engine
  engine_version            = var.engine_version
  db_cluster_instance_class = var.db_cluster_instance_class
  allocated_storage         = var.allocated_storage
  storage_type              = var.storage_type
  storage_encrypted         = var.storage_encrypted
  kms_key_id                = var.kms_key_id

  database_name   = var.database_name
  master_username = local.db_creds.username
  master_password = local.db_creds.password
  port            = var.port

  iam_database_authentication_enabled = var.iam_database_authentication_enabled

  vpc_security_group_ids          = var.vpc_security_group_ids
  db_subnet_group_name            = aws_db_subnet_group.rds_subnet_group.name
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.aws_rds_cluster_parameter_group.id

  network_type = var.network_type
  iops         = var.iops

  allow_major_version_upgrade  = var.allow_major_version_upgrade
  apply_immediately            = var.apply_immediately
  preferred_maintenance_window = var.preferred_maintenance_window

  backup_retention_period = var.backup_retention_period
  preferred_backup_window = var.preferred_backup_window

  enabled_cloudwatch_logs_exports = var.enabled_cloudwatch_logs_exports

  deletion_protection = var.deletion_protection

  tags = var.tags

  skip_final_snapshot = true

  depends_on = [aws_cloudwatch_log_group.this]
}

# cloudwatch log group
resource "aws_cloudwatch_log_group" "this" {
  for_each          = toset([for log in var.enabled_cloudwatch_logs_exports : log if var.create_cloudwatch_log_group])
  name              = "/aws/rds/cluster/${var.cluster_identifier}/${each.value}"
  retention_in_days = var.cloudwatch_log_group_retention_in_days
  kms_key_id        = var.cloudwatch_log_group_kms_key_id

  tags = var.tags
}


# enhanced monitoring
data "aws_iam_policy_document" "enhanced_monitoring" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["monitoring.rds.amazonaws.com"]
    }
  }
}

# AWS Backup plan
resource "aws_backup_plan" "multiaz" {
  name = "${var.cluster_identifier}_backup_plan"

  rule {
    rule_name         = "${var.cluster_identifier}_tf_multiaz_backup_rule"
    target_vault_name = "Default"
    schedule          = "cron(0 12 * * ? *)"
  }
}

resource "aws_iam_role" "backup_role" {
  name               = "${var.cluster_identifier}_backup_role"
  assume_role_policy = <<POLICY
{
"Version": "2012-10-17",
"Statement": [
    {
    "Action": "sts:AssumeRole",
    "Principal": {
        "Service": "backup.amazonaws.com"
    },
    "Effect": "Allow",
    "Sid": ""
    }
]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "backup_policy" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
  role       = aws_iam_role.backup_role.name
}

resource "aws_backup_selection" "backup_selection" {
  iam_role_arn = aws_iam_role.backup_role.arn
  name         = "${var.cluster_identifier}_backup_selection"
  plan_id      = aws_backup_plan.multiaz.id

  resources = [
    aws_rds_cluster.rds_cluster.arn
  ]
}