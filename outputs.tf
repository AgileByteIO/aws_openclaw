output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.openclaw_machine.id
}

output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.openclaw_machine.public_ip
}

output "instance_private_ip" {
  description = "Private IP address of the EC2 instance"
  value       = aws_instance.openclaw_machine.private_ip
}

output "data_volume_id" {
  description = "ID of the data EBS volume"
  value       = aws_ebs_volume.openclaw_data.id
}

output "security_group_id" {
  description = "ID of the security group"
  value       = aws_security_group.openclaw_sg.id
}

output "ssh_connection_string" {
  description = "SSH connection command"
  value       = "ssh -i ~/.ssh/${var.key_pair_name}.pem ubuntu@${aws_instance.openclaw_machine.public_ip}"
}
