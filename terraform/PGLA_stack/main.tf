
# 1. Define variables for lab environment
variable "vm_count" {
  description = "Number of VMs to spin up for the lab"
  type        = number
  default     = 1
}

# 2. Tells Terraform where to find the public SSH key on my Mac
variable "ssh_public_key" {
  type    = string
  default = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIH4P3ikoeLz6ROeFGuuH8t1bUdFpTrpPDHrucNvKGHTm dantejit@MBPDante"
}

# 3. Deployment Block
resource "proxmox_virtual_environment_vm" "pgla_host" {
  count = var.vm_count
  # Names them ubuntu-node-1, ubuntu-node-2, etc.
  name      = "pgla-stack"
  node_name = "pve"

  #  Terraform to clone the Golden Image built
  clone {
    vm_id = 114
    full  = true
  }


  # Hardware settings for the clones 
  cpu {
    cores = 2
    type  = "host"
  }
  memory {
    dedicated = 4096
  }

  # Network Configuration 
  network_device {
    bridge  = "vmbr2"
    vlan_id = 35
  }

  # 4. Cloud-Init  
  initialization {
    # Creates  dedicated admin user and injects my SSH public key
    user_account {
      username = "pgla-admin"
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
