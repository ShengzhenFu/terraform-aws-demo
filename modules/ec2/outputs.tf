output "public_ec2_id" {
  value = aws_instance.public_ec2.id
}

output "private_ec2_id" {
  value = aws_instance.private_ec2.id
}

output "ami" {
  value = data.aws_ami.amzn2.id
}

output "security_group_of_private_ec2" {
  value = aws_security_group.private_ec2_sg
}