locals {
  subnet_count = length(var.availability_zones)
}

# vpc
resource "aws_vpc" "test-vpc" {
  cidr_block                           = var.cidr
  enable_dns_support                   = true
  enable_dns_hostnames                 = true
  instance_tenancy                     = "default"
  enable_network_address_usage_metrics = false

  tags = {
    Name = "${var.vpc_name}-vpc"
  }
}

# internet gateway
resource "aws_internet_gateway" "main_igw" {
  vpc_id = aws_vpc.test-vpc.id
  tags = {
    Name = "${var.vpc_name}-igw"
  }
}
# EIP
resource "aws_eip" "nat_eip" {
  depends_on = [aws_internet_gateway.main_igw]
  count      = local.subnet_count
  tags       = { Name : "${var.vpc_name}-${count.index}-eip" }
}
# nat gateway
resource "aws_nat_gateway" "nat_gw" {
  count         = local.subnet_count
  allocation_id = aws_eip.nat_eip[count.index].id
  subnet_id     = aws_subnet.public_subnet[count.index].id
  depends_on    = [aws_internet_gateway.main_igw]
  tags          = { Name : "${var.vpc_name}-${count.index}-natgw" }
}

# routing
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.test-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main_igw.id
  }
  tags = {
    Name = "${var.vpc_name}-public-rt"
  }
}
resource "aws_route_table" "private_rt" {
  count  = local.subnet_count
  vpc_id = aws_vpc.test-vpc.id
  tags   = { Name : "${var.vpc_name}-private-rt-${count.index}" }
}
resource "aws_route_table" "private_isolated_rt" {
  vpc_id = aws_vpc.test-vpc.id
  tags   = { Name : "${var.vpc_name}-private-isolated-rt" }
}
resource "aws_route" "private_subnet_route" {
  count                  = local.subnet_count
  route_table_id         = aws_route_table.private_rt[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat_gw[count.index].id
}

# subnets
locals {
  azs_count                 = length(var.availability_zones)
  ip_offset_private_subnet  = local.azs_count
  ip_offset_isolated_subnet = local.azs_count * 2
}

# public subnet
resource "aws_subnet" "public_subnet" {
  count                   = local.azs_count
  vpc_id                  = aws_vpc.test-vpc.id
  cidr_block              = cidrsubnet(var.cidr, var.cidr_offset, count.index)
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.vpc_name}-public-subnet-${count.index}"
  }
}
resource "aws_route_table_association" "public_subnet_association" {
  count          = local.azs_count
  subnet_id      = aws_subnet.public_subnet[count.index].id
  route_table_id = aws_route_table.public_rt.id
}

# private subnet
resource "aws_subnet" "private_subnet" {
  count                   = local.azs_count
  vpc_id                  = aws_vpc.test-vpc.id
  map_public_ip_on_launch = false

  cidr_block        = cidrsubnet(var.cidr, var.cidr_offset, local.ip_offset_private_subnet + count.index)
  availability_zone = element(var.availability_zones, count.index)
  tags = {
    Name = "${var.vpc_name}-private-subnet-${count.index}"
  }
}
resource "aws_route_table_association" "private_subnet_association" {
  count          = local.azs_count
  subnet_id      = aws_subnet.private_subnet[count.index].id
  route_table_id = aws_route_table.private_rt[count.index].id
}

# private isolated subnet
resource "aws_subnet" "private_isolated_subnet" {
  count                   = local.azs_count
  vpc_id                  = aws_vpc.test-vpc.id
  map_public_ip_on_launch = false

  cidr_block        = cidrsubnet(var.cidr, var.cidr_offset, local.ip_offset_isolated_subnet + count.index)
  availability_zone = element(var.availability_zones, count.index)
  tags = {
    Name = "${var.vpc_name}-private-isolated-subnet-${count.index}"
  }
}
resource "aws_route_table_association" "private_isolated_subnet_association" {
  count          = local.azs_count
  subnet_id      = aws_subnet.private_isolated_subnet[count.index].id
  route_table_id = aws_route_table.private_isolated_rt.id
}

# alb security group
resource "aws_security_group" "alb_sg" {
  name        = "alb_sg"
  vpc_id      = aws_vpc.test-vpc.id
  description = "security group of alb"
  ingress = [
    {
      description      = "allow http from internet"
      from_port        = 80
      to_port          = 80
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
      security_groups  = []
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      self             = false
    }
  ]
  egress = [
    {
      description      = "allow http to public ec2"
      from_port        = 80
      to_port          = 80
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
      security_groups  = []
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      self             = false
    },
    {
      description      = "allow https to public ec2"
      from_port        = 443
      to_port          = 443
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
      security_groups  = []
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      self             = false
    }
  ]
  tags = { Name : "alb_sg" }
}
# create alb
resource "aws_lb" "alb" {
  name               = "alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [for subnet in aws_subnet.public_subnet : subnet.id]
}