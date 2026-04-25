packer {
  required_plugins {
    proxmox = {
      version = ">= 1.2.3"
      source  = "github.com/hashicorp/proxmox"
    }
  }
}

# 1. Variables (Passes these via environment variables or a .pkrvars.hcl file)
variable "proxmox_api_url" {
  type = string
}

variable "proxmox_username" {
  type = string
}

variable "proxmox_token" {
  type      = string
  sensitive = true
}

source "proxmox-iso" "rocky9" {
  # 2. Proxmox Connection
  proxmox_url              = var.proxmox_api_url
  username                 = var.proxmox_username
  token                    = var.proxmox_token
  insecure_skip_tls_verify = true
  node                     = "pve" # MUST match actual Proxmox node name exactly

  #Extend the API task timeout
  task_timeout             = "5m"
  
  # 3. Virtual Machine Hardware Settings
  vm_name              = "template-rocky9-cloudinit"
  template_description = "Rocky Linux 9 Template - Built by Packer"
  os                   = "l26" #(Linux 2.6+)
  cores                = 2
  memory               = 2048
  cpu_type             = "host"
  qemu_agent           = true
  

  # 4. Disk Configuration
  scsi_controller = "virtio-scsi-pci"
  disks {
    disk_size    = "20G"
    format       = "raw" # 'raw' is optimized for Proxmox LVM-Thin / ZFS than qcow2
    type         = "scsi"
    storage_pool = "Synology-nfs" # Change if storage pool has a different name
  }

  # 5. Network Configuration
  network_adapters {
    model    = "virtio"
    bridge   = "vmbr2"
    vlan_tag = "35"
  }

  # 6. Boot Media (Downloads ISO automatically)
  boot_iso {
    type             = "scsi"
    #iso_file         = "Synology-nfs:iso/Rocky-9.7-x86_64-minimal.iso"
    iso_url          = "https://mirror.cov.ukservers.com/rocky/9/isos/x86_64/Rocky-9-latest-x86_64-minimal.iso"
    iso_checksum     = "23a1ac1175d8ccada7195863914ef1237f584ff25f73bd53da410d5fffd882b0"
    iso_storage_pool = "Synology-nfs"
    unmount          = true
    iso_download_pve = true
  }

  # 7. Native Cloud-Init Support 
  # Automatically attaches a Cloud-Init CD-ROM drive to the resulting template
  cloud_init              = true
  cloud_init_storage_pool = "Synology-nfs"

  # 8. 
  boot_wait      = "10s"
  boot_command = [
    "<tab><wait>",
    " inst.ks=hd:LABEL=OEMDRV:/ks.cfg",
    " inst.ks=https://gist.githubusercontent.com/pmagyei/7c38eb912d7cce56e1bd6ea203e05bfe/raw/ks.cfg ip=dhcp",
    "<enter>"
  ]

  # 9. SSH Communicator
  # Packer requires this to log in AFTER the OS installs to run final scripts.
  # The password MUST match the 'rootpw' set in ks.cfg file.
  ssh_username = "root"
  ssh_password = "packer"
  ssh_timeout  = "20m"
}

build {
  sources = ["source.proxmox-iso.rocky9"]

  # The shell provisioner logs in via SSH to finalize the image
  provisioner "shell" {
    inline = [
      "echo 'Image build complete. Preparing for template conversion.'",
      "sudo dnf update -y",
      # Clean up SSH keys and Machine ID so Terraform clones don't conflict
      "sudo rm -f /etc/ssh/ssh_host_*",
      "sudo truncate -s 0 /etc/machine-id"
    ]
  }
}