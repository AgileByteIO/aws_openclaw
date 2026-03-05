variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
}

variable "ami_id" {
  description = "AMI ID for the EC2 instance"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}

variable "key_pair_name" {
  description = "Name of the SSH key pair"
  type        = string
}

variable "vpc_id" {
  description = "Optional VPC ID to deploy into"
  type        = string
  default     = null
}

variable "subnet_id" {
  description = "Optional subnet ID to deploy into"
  type        = string
  default     = null
}

variable "root_volume_size" {
  description = "Size of the root EBS volume in GB"
  type        = number
}

variable "data_volume_size" {
  description = "Size of the data EBS volume in GB"
  type        = number
}

variable "allowed_ssh_cidr" {
  description = "CIDR blocks allowed to SSH"
  type        = list(string)
}

variable "environment" {
  description = "Environment name"
  type        = string
}
