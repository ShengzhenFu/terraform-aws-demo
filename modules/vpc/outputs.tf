output "vpc_cidr" {
  value = var.cidr
}

output "vpc_id" {
  value = aws_vpc.test-vpc.id
}

output "azs" {
  value = var.availability_zones
}

output "public_subnet_ids" {
  value = aws_subnet.public_subnet[*].id
}

output "private_subnet_ids" {
  value = aws_subnet.private_subnet[*].id
}

output "private_isolated_subnet_ids" {
  value = aws_subnet.private_isolated_subnet
}

output "alb_arn" {
  value = aws_lb.alb.arn
}

output "alb_sg_id" {
  value = aws_security_group.alb_sg.id
}

output "rds_sg_id" {
  value = aws_security_group.rds_security_group.id
}