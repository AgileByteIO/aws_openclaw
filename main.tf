terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.46"
    }
  }
  required_version = ">= 1.6.0"
}

provider "aws" {
  region = var.cloud_provider == "aws" ? var.aws_region : null
}

provider "hcloud" {
  token = var.cloud_provider == "hetzner" ? var.hcloud_token : null
}

module "aws_infrastructure" {
  source = "./modules/aws"

  count = var.cloud_provider == "aws" ? 1 : 0

  aws_region       = var.aws_region
  ami_id           = var.ami_id
  instance_type    = var.instance_type
  key_pair_name    = var.key_pair_name
  vpc_id           = var.vpc_id
  subnet_id        = var.subnet_id
  root_volume_size = var.root_volume_size
  data_volume_size = var.data_volume_size
  allowed_ssh_cidr = var.allowed_ssh_cidr
  environment      = var.environment
}

module "hetzner_infrastructure" {
  source = "./modules/hetzner"

  count = var.cloud_provider == "hetzner" ? 1 : 0

  hcloud_token          = var.hcloud_token
  hcloud_image          = var.hcloud_image
  hcloud_server_type    = var.hcloud_server_type
  hcloud_location       = var.hcloud_location
  hcloud_ssh_key_name   = var.hcloud_ssh_key_name
  hcloud_ssh_public_key = var.hcloud_ssh_public_key
  root_volume_size      = var.root_volume_size
  data_volume_size      = var.data_volume_size
  allowed_ssh_cidr      = var.allowed_ssh_cidr
  environment           = var.environment
}

locals {
  instance_id         = var.cloud_provider == "aws" ? module.aws_infrastructure[0].instance_id : module.hetzner_infrastructure[0].instance_id
  instance_public_ip  = var.cloud_provider == "aws" ? module.aws_infrastructure[0].instance_public_ip : module.hetzner_infrastructure[0].instance_public_ip
  instance_private_ip = var.cloud_provider == "aws" ? module.aws_infrastructure[0].instance_private_ip : module.hetzner_infrastructure[0].instance_private_ip
  data_volume_id      = var.cloud_provider == "aws" ? module.aws_infrastructure[0].data_volume_id : module.hetzner_infrastructure[0].data_volume_id
  security_group_id   = var.cloud_provider == "aws" ? module.aws_infrastructure[0].security_group_id : module.hetzner_infrastructure[0].security_group_id
  instance_user       = var.cloud_provider == "aws" ? "ubuntu" : "root"
}

resource "null_resource" "openclaw_provision" {
  depends_on = [module.aws_infrastructure, module.hetzner_infrastructure]

  triggers = {
    instance_id = local.instance_id
    public_ip   = local.instance_public_ip
  }

  provisioner "local-exec" {
    command = "${path.module}/shell/provision-openclaw.sh ${local.instance_public_ip} ${var.ssh_private_key_path} ${local.instance_user}"
    environment = {
      DATA_DEVICE = var.data_device
    }
  }
}
