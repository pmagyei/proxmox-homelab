terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.55.1"
    }
  }
}

provider "proxmox" {
  insecure = true
}
data "proxmox_virtual_environment_nodes" "available_nodes" {}

output "proxmox_nodes" {
  value = data.proxmox_virtual_environment_nodes.available_nodes.names
}