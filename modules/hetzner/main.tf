terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.46"
    }
  }
}

data "hcloud_ssh_key" "existing" {
  count = var.hcloud_ssh_key_name != "" ? 1 : 0
  name  = var.hcloud_ssh_key_name
}

resource "hcloud_ssh_key" "openclaw" {
  count      = var.hcloud_ssh_key_name != "" ? 0 : 1
  name       = "openclaw-key-${var.environment}"
  public_key = file(var.hcloud_ssh_public_key)
}

resource "hcloud_server" "openclaw_machine" {
  name        = "openclaw-machine"
  image       = var.hcloud_image
  server_type = var.hcloud_server_type
  location    = var.hcloud_location

  ssh_keys = var.hcloud_ssh_key_name != "" ? [data.hcloud_ssh_key.existing[0].id] : [hcloud_ssh_key.openclaw[0].id]

  public_net {
    ipv4_enabled = true
  }

  labels = {
    Environment = var.environment
    ManagedBy   = "OpenTofu"
  }
}

resource "hcloud_volume" "openclaw_data" {
  name     = "openclaw-data-volume"
  size     = var.data_volume_size
  location = var.hcloud_location
  format   = "ext4"

  labels = {
    Environment = var.environment
    ManagedBy   = "OpenTofu"
  }
}

resource "hcloud_volume_attachment" "openclaw_data_attachment" {
  volume_id = hcloud_volume.openclaw_data.id
  server_id = hcloud_server.openclaw_machine.id
}

resource "hcloud_firewall" "openclaw_fw" {
  name = "openclaw-firewall"

  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "22"
    source_ips = var.allowed_ssh_cidr
  }

  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "80"
    source_ips = ["0.0.0.0/0"]
  }

  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "443"
    source_ips = ["0.0.0.0/0"]
  }

  apply_to {
    server = hcloud_server.openclaw_machine.id
  }
}
