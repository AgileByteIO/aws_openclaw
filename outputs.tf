output "instance_id" {
  description = "ID of the cloud instance"
  value       = var.cloud_provider == "aws" ? module.aws_infrastructure[0].instance_id : module.hetzner_infrastructure[0].instance_id
}

output "instance_public_ip" {
  description = "Public IP address of the instance"
  value       = var.cloud_provider == "aws" ? module.aws_infrastructure[0].instance_public_ip : module.hetzner_infrastructure[0].instance_public_ip
}

output "instance_private_ip" {
  description = "Private IP address of the instance"
  value       = var.cloud_provider == "aws" ? module.aws_infrastructure[0].instance_private_ip : module.hetzner_infrastructure[0].instance_private_ip
}

output "data_volume_id" {
  description = "ID of the data volume"
  value       = var.cloud_provider == "aws" ? module.aws_infrastructure[0].data_volume_id : module.hetzner_infrastructure[0].data_volume_id
}

output "security_group_id" {
  description = "ID of the security group/firewall"
  value       = var.cloud_provider == "aws" ? module.aws_infrastructure[0].security_group_id : module.hetzner_infrastructure[0].security_group_id
}

output "ssh_connection_string" {
  description = "SSH connection command"
  value       = var.cloud_provider == "aws" ? "ssh -i ~/.ssh/${var.key_pair_name}.pem ubuntu@${module.aws_infrastructure[0].instance_public_ip}" : "ssh -i ~/.ssh/${var.key_pair_name}.pem root@${module.hetzner_infrastructure[0].instance_public_ip}"
}
