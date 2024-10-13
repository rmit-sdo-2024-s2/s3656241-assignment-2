terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

terraform {
  backend "s3" {
    bucket         = "terraform-bucket-s3656241"  
    key            = "terraform/state/terraform.tfstate"           
    region         = "us-east-1"                            
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
}

# Fetch the default VPC in the region
data "aws_vpc" "default" {
  default = true
}

# Fetch all subnets in the default VPC
data "aws_subnets" "selected_subnets" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Get Ubuntu AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["099720109477"] # Canonical
}

# Add a key pair resource
resource "aws_key_pair" "admin" {
  key_name   = "admin-key"
  public_key = file("/home/sam/.ssh/git_sdo_key.pub")
}

# Security group for EC2 instances
resource "aws_security_group" "vm_inbound" {
  name = "vm_inbound"
  # SSH
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # HTTP in
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # HTTPS out
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create 2 EC2 instances for the app
resource "aws_instance" "app" {
  ami             = data.aws_ami.ubuntu.id
  instance_type   = "t2.micro"
  count           = 2
  key_name        = aws_key_pair.admin.key_name
  security_groups = [aws_security_group.vm_inbound.name]

  tags = {
    Name = "foo server"
  }
}

# Create an Application Load Balancer using dynamically retrieved subnets
resource "aws_lb" "application-lb" {
    name               = "test-alb"
    internal           = false
    ip_address_type    = "ipv4"
    load_balancer_type = "application"
    security_groups    = [aws_security_group.vm_inbound.id]
    subnets            = data.aws_subnets.selected_subnets.ids  # Dynamically use subnets from the default VPC
    tags = {
        Name = "test-alb"
    }
}

# Create a target group for the load balancer
resource "aws_lb_target_group" "target-group" {
    health_check {
        interval            = 10
        path                = "/"
        protocol            = "HTTP"
        timeout             = 5
        healthy_threshold   = 5
        unhealthy_threshold = 2
    }
    name        = "test-tg"
    port        = 80
    protocol    = "HTTP"
    target_type = "instance"
    vpc_id      = data.aws_vpc.default.id
}

# Attach EC2 instances to the target group via a listener
resource "aws_lb_listener" "listener" {
    load_balancer_arn = aws_lb.application-lb.arn
    port              = 80
    protocol          = "HTTP"

    default_action {
        type             = "forward"
        target_group_arn = aws_lb_target_group.target-group.arn
    }
}

# Attach EC2 instances to the target group
resource "aws_lb_target_group_attachment" "ec2_attach" {
    count = length(aws_instance.app)
    target_group_arn = aws_lb_target_group.target-group.arn
    target_id        = aws_instance.app[count.index].id
}

# Output the ELB DNS name
output "elb-dns-name" {
  value = aws_lb.application-lb.dns_name
}
