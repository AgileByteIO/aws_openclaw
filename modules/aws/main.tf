terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

data "aws_vpc" "default" {
  count   = var.vpc_id == null ? 1 : 0
  default = true
}

data "aws_subnets" "default" {
  count = var.subnet_id == null ? 1 : 0
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default[0].id]
  }
}

locals {
  effective_vpc_id    = var.vpc_id != null ? var.vpc_id : data.aws_vpc.default[0].id
  effective_subnet_id = var.subnet_id != null ? var.subnet_id : data.aws_subnets.default[0].ids[0]
}

resource "aws_instance" "openclaw_machine" {
  ami           = var.ami_id
  instance_type = var.instance_type
  
  key_name = var.key_pair_name
  
  subnet_id = local.effective_subnet_id
  
  associate_public_ip_address = true
  
  root_block_device {
    volume_size           = var.root_volume_size
    volume_type           = "gp3"
    delete_on_termination = true
    encrypted             = true
  }
  
  tags = {
    Name        = "OpenClaw-Machine"
    Environment = var.environment
    ManagedBy   = "OpenTofu"
  }
}

resource "aws_ebs_volume" "openclaw_data" {
  availability_zone = aws_instance.openclaw_machine.availability_zone
  size              = var.data_volume_size
  type              = "gp3"
  encrypted         = true
  
  tags = {
    Name        = "OpenClaw-Data-Volume"
    Environment = var.environment
    ManagedBy   = "OpenTofu"
  }
}

resource "aws_volume_attachment" "openclaw_data_attachment" {
  device_name = "/dev/sdf"
  volume_id   = aws_ebs_volume.openclaw_data.id
  instance_id = aws_instance.openclaw_machine.id
}

resource "aws_security_group" "openclaw_sg" {
  name        = "openclaw-security-group"
  description = "Security group for OpenClaw machine"
  vpc_id      = local.effective_vpc_id
  
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_ssh_cidr
    description = "SSH access"
  }
  
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP access"
  }
  
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS access"
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }
  
  tags = {
    Name        = "OpenClaw-SG"
    Environment = var.environment
    ManagedBy   = "OpenTofu"
  }
}
