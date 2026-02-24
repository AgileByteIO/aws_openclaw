terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.6.0"
}

provider "aws" {
  region = var.aws_region
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

# EC2 Instance
resource "aws_instance" "openclaw_machine" {
  ami           = var.ami_id
  instance_type = var.instance_type
  
  key_name = var.key_pair_name

  subnet_id = local.effective_subnet_id

  associate_public_ip_address = true
  
  vpc_security_group_ids = [aws_security_group.openclaw_sg.id]
  
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

# Additional EBS Volume for data storage
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

# Attach EBS volume to instance
resource "aws_volume_attachment" "openclaw_data_attachment" {
  device_name = "/dev/sdf"
  volume_id   = aws_ebs_volume.openclaw_data.id
  instance_id = aws_instance.openclaw_machine.id
}

# Local provisioning after instance creation
resource "null_resource" "openclaw_provision" {
  depends_on = [aws_volume_attachment.openclaw_data_attachment]

  triggers = {
    instance_id = aws_instance.openclaw_machine.id
    public_ip   = aws_instance.openclaw_machine.public_ip
  }

  provisioner "local-exec" {
    command = "${path.module}/shell/provision-openclaw.sh ${coalesce(aws_instance.openclaw_machine.public_ip, aws_instance.openclaw_machine.private_ip)} ${var.ssh_private_key_path}"
  }
}

# Security Group
resource "aws_security_group" "openclaw_sg" {
  name        = "openclaw-security-group"
  description = "Security group for OpenClaw machine"
  vpc_id      = local.effective_vpc_id
  
  # SSH access
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_ssh_cidr
    description = "SSH access"
  }
  
  # HTTP access (if needed)
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP access"
  }
  
  # HTTPS access (if needed)
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS access"
  }
  
  # Allow all outbound traffic
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
