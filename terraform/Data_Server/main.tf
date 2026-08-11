
# 3. Deployment Block
resource "proxmox_virtual_environment_vm" "ubuntu_lab_nodes" {
  count = var.vm_count
  # Names them ubuntu-node-1, ubuntu-node-2, etc.
  name      = "data-server"
  node_name = "pve"

  #  Terraform to clone the Golden Image built
  clone {
    vm_id = 114
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

  # 4. Cloud-Init  
  initialization {
    # Creates  dedicated admin user and injects my SSH public key
    user_account {
      username = "data-admin"
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
