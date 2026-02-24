variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "ami_id" {
  description = "AMI ID for the EC2 instance (Ubuntu 22.04 LTS example)"
  type        = string
  default     = "ami-0c7217cdde317cfec" # Ubuntu 22.04 LTS in us-east-1
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.medium"
}

variable "key_pair_name" {
  description = "Name of the SSH key pair to use for the instance"
  type        = string
  # You must set this value or create the key pair in AWS first
}

variable "ssh_private_key_path" {
  description = "Local path to the SSH private key for provisioning"
  type        = string
}

variable "root_volume_size" {
  description = "Size of the root EBS volume in GB"
  type        = number
  default     = 30
}

variable "data_volume_size" {
  description = "Size of the additional data EBS volume in GB"
  type        = number
  default     = 100
}

variable "allowed_ssh_cidr" {
  description = "CIDR blocks allowed to SSH into the instance"
  type        = list(string)
  default     = ["0.0.0.0/0"] # CHANGE THIS to your IP for better security!
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "vpc_id" {
  description = "Optional VPC ID to deploy into (requires subnet_id)"
  type        = string
  default     = null
  validation {
    condition     = (var.vpc_id == null && var.subnet_id == null) || (var.vpc_id != null && var.subnet_id != null)
    error_message = "If you set vpc_id you must also set subnet_id, and vice versa."
  }
}

variable "subnet_id" {
  description = "Optional subnet ID to deploy into (requires vpc_id)"
  type        = string
  default     = null
}
