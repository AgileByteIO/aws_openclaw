variable "hcloud_token" {
  description = "Hetzner Cloud API token"
  type        = string
  sensitive   = true
}

variable "hcloud_image" {
  description = "Hetzner Cloud image (e.g., ubuntu-22.04)"
  type        = string
}

variable "hcloud_server_type" {
  description = "Hetzner Cloud server type (e.g., cx11, cpx31)"
  type        = string
}

variable "hcloud_location" {
  description = "Hetzner Cloud location (e.g., fsn1, nbg1, hel1)"
  type        = string
}

variable "hcloud_ssh_key_name" {
  description = "Existing SSH key name in Hetzner (optional, overrides hcloud_ssh_public_key)"
  type        = string
  default     = ""
}

variable "hcloud_ssh_public_key" {
  description = "SSH public key content (used if hcloud_ssh_key_name is not set)"
  type        = string
  default     = ""
}

variable "root_volume_size" {
  description = "Size of the root volume in GB"
  type        = number
}

variable "data_volume_size" {
  description = "Size of the data volume in GB"
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
