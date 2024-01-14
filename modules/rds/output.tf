output "rds_cluster_endpoint" {
  value       = aws_rds_cluster.rds_cluster.endpoint
  description = "connection endpoint of RDS cluster"
}

output "db_engine" {
  value       = aws_rds_cluster.rds_cluster.engine
  description = "engine of RDS"
}

output "db_engine_version" {
  value       = aws_rds_cluster.rds_cluster.engine_version
  description = "engine version of RDS"
}

output "db_name" {
  value       = aws_rds_cluster.rds_cluster.database_name
  description = "name of DB"
}

output "instance_class" {
  value       = aws_rds_cluster.rds_cluster.db_cluster_instance_class
  description = "db instance class"
}

output "db_cluster_arn" {
  value       = aws_rds_cluster.rds_cluster.arn
  description = "the ARN of the DB cluster"
}

output "rds_cluster_az" {
  value       = aws_rds_cluster.rds_cluster.availability_zones
  description = "availability zones of the RDS cluster"
}