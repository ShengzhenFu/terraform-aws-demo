data "aws_ami" "amzn2" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-kernel-*-hvm-*-x86_64-gp2"]
  }
}

data "aws_ami" "ubuntu22_04" {
  most_recent = true
  owners      = ["099720109477"] # Canonical
  filter {
    name   = "name"
    values = ["ubuntu/images/*ubuntu-jammy-22.04-amd64-server-*"]
  }
}

# ec2 instance profile
resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "ec2_instance_profile"
  role = aws_iam_role.ec2_instance_role.name
}
resource "aws_iam_role" "ec2_instance_role" {
  name = "ec2_instance_role"
  path = "/"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}
resource "aws_iam_policy" "cw_agent_policy" {
  name        = "cw_agent_policy"
  path        = "/"
  description = "policy to allow ec2 instance to push logs to CloudWatch"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}
resource "aws_iam_role_policy_attachment" "cw_agent_policy_attachment" {
  role       = aws_iam_role.ec2_instance_role.name
  policy_arn = aws_iam_policy.cw_agent_policy.arn
}
resource "aws_iam_role_policy_attachment" "ssm_agent_policy_attachment" {
  role       = aws_iam_role.ec2_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedEC2InstanceDefaultPolicy"
}
# security group of the private ec2 instance
resource "aws_security_group" "private_ec2_sg" {
  name        = "private_ec2_sg"
  vpc_id      = var.vpc_id
  description = "security group for private ec2"
  ingress = [{
    description      = "allow http from vpc"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = [var.cidr_vpc]
    security_groups  = []
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    self             = false
    },
    {
      description      = "allow https from ssh"
      from_port        = 22
      to_port          = 22
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = []
      security_groups  = []
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      self             = false
    }
  ]
  egress = [
    {
      description      = "allow all"
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
      security_groups  = []
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      self             = false
    }
  ]
  tags = { Name : "private_ec2_sg" }
}
# create ec2 in private subnet
resource "aws_instance" "private_ec2" {
  ami           = data.aws_ami.ubuntu22_04.id
  instance_type = var.instance_type
  user_data     = templatefile("user-data-ubuntu.sh", {})
  subnet_id     = var.private_subnet_id

  iam_instance_profile = aws_iam_instance_profile.ec2_instance_profile.name
  depends_on = [
    aws_iam_role_policy_attachment.cw_agent_policy_attachment,
    aws_iam_role_policy_attachment.ssm_agent_policy_attachment
  ]

  root_block_device {
    delete_on_termination = true
    volume_type           = "gp3"
    volume_size           = "8"
  }
  security_groups = [aws_security_group.private_ec2_sg.id]
  tags            = { Name : "private-ec2-instance" }
}

# create ec2 in public subnet
resource "aws_instance" "public_ec2" {
  ami           = data.aws_ami.ubuntu22_04.id
  instance_type = var.instance_type
  user_data     = templatefile("user-data-ubuntu.sh", {})
  subnet_id     = var.public_subnet_id

  iam_instance_profile = aws_iam_instance_profile.ec2_instance_profile.name
  depends_on = [
    aws_iam_role_policy_attachment.cw_agent_policy_attachment,
    aws_iam_role_policy_attachment.ssm_agent_policy_attachment
  ]

  root_block_device {
    delete_on_termination = true
    volume_type           = "gp3"
    volume_size           = "8"
  }
  security_groups = [aws_security_group.public_ec2_sg.id]
  tags            = { Name : "public-ec2-instance" }
}
resource "aws_security_group" "public_ec2_sg" {
  name        = "public_ec2_sg"
  vpc_id      = var.vpc_id
  description = "security group for ec2 in public subnet"
  ingress = [
    {
      description      = "allow http from alb"
      from_port        = 80
      to_port          = 80
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = []
      security_groups  = [var.alb_sg_id]
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      self             = false
    },
    {
      description      = "allow https from ssh"
      from_port        = 22
      to_port          = 22
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = []
      security_groups  = []
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      self             = false
    }
  ]
  egress = [
    {
      description      = "allow all"
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
      security_groups  = []
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      self             = false
    }
  ]
  tags = { Name : "public_ec2_sg" }
}

# alb target group
resource "aws_lb_target_group" "public-ec2-tg" {
  name                          = "public-ec2-tg"
  port                          = 80
  target_type                   = "instance"
  protocol                      = "HTTP"
  vpc_id                        = var.vpc_id
  load_balancing_algorithm_type = "round_robin"

  health_check {
    enabled             = true
    path                = "/index.html"
    matcher             = "200"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    interval            = 30
    timeout             = 5
  }
}
resource "aws_alb_target_group_attachment" "public-ec2-tg-attachment" {
  count            = length(aws_instance.public_ec2)
  target_group_arn = aws_lb_target_group.public-ec2-tg.arn
  target_id        = element(aws_instance.public_ec2.*.id, count.index)
  port             = 80
}

# create alb listener
resource "aws_lb_listener" "alb_listener" {
  //load_balancer_arn = aws_lb.alb.arn
  load_balancer_arn = var.alb_arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.public-ec2-tg.arn
  }
}