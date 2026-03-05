output "instance_id" {
  description = "ID of the Hetzner server"
  value       = hcloud_server.openclaw_machine.id
}

output "instance_public_ip" {
  description = "Public IP address of the Hetzner server"
  value       = hcloud_server.openclaw_machine.ipv4_address
}

output "instance_private_ip" {
  description = "Private IP address of the Hetzner server"
  value       = ""
}

output "data_volume_id" {
  description = "ID of the data volume"
  value       = hcloud_volume.openclaw_data.id
}

output "security_group_id" {
  description = "ID of the firewall"
  value       = hcloud_firewall.openclaw_fw.id
}
