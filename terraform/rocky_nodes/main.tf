
# 1. Define variables for lab environment
variable "vm_count" {
  description = "Number of VMs to spin up for the lab"
  type        = number
  default     = 2
}

# 2. Tells Terraform where to find the public SSH key onmy Mac
variable "ssh_public_key" {
  type    = string
  default = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIH4P3ikoeLz6ROeFGuuH8t1bUdFpTrpPDHrucNvKGHTm dantejit@MBPDante"
}

# 3. Deployment Block
resource "proxmox_virtual_environment_vm" "rocky_lab_nodes" {
  count = var.vm_count
  # Names them rocky-node-1, rocky-node-2, etc.
  name      = "rocky-node-${count.index + 1}"
  node_name = "pve"

  #  Terraform clones the Golden Image built by packer
  clone {
    vm_id = 116
    full  = false
  }

  # Hardware settings for the clones 
  cpu {
    cores = 2
    type  = "host"
  }
  memory {
    dedicated = 2048
  }

  # Network Configuration 
  network_device {
    bridge  = "vmbr2"
    vlan_id = 35
  }

  # 4. Cloud-Init Injection 
  initialization {
    # Creates  dedicated admin user and injects my SSH public key
    user_account {
      username = "rhcsa-admin"
      keys     = [var.ssh_public_key]
    }

    # DHCP config
    ip_config {
      ipv4 {
        address = "dhcp"
      }
      ipv6 {
        address = "dhcp"

      }
    }
  }
}
