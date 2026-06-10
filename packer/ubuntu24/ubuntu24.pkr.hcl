packer {
  required_plugins {
    proxmox = {
      version = ">= 1.2.3"
      source  = "github.com/hashicorp/proxmox"
    }
  }
}

# 1. Variables (Pass these via environment variables or a .pkrvars.hcl file)
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

source "proxmox-iso" "ubuntu24" {
  proxmox_url              = var.proxmox_api_url
  username                 = var.proxmox_username
  token                    = var.proxmox_token
  insecure_skip_tls_verify = true
  node                     = "pve"
  task_timeout             = "10m"
  boot_wait                = "3s"
  vm_name                  = "template-ubuntu24-cloudinit"
  template_description     = "Ubuntu 24.04 Template - Built by Packer"
  os                       = "l26" # (Linux 2.6+)
  cores                    = 2
  memory                   = 2048
  cpu_type                 = "host"
  qemu_agent               = true
  scsi_controller          = "virtio-scsi-pci"
  
  disks {
    disk_size    = "20G"
    format       = "raw"
    type         = "scsi"
    storage_pool = "Synology-nfs"
  }
  network_adapters {
    model    = "virtio"
    bridge   = "vmbr2"
    vlan_tag = "35"
  }
   # Boot Media (Downloads ISO automatically)
  boot_iso {
    type             = "scsi"
   # iso_file         = "Synology-nfs:iso/ubuntu-24.04-live-server-amd64.iso"
    iso_url          = "https://releases.ubuntu.com/24.04.4/ubuntu-24.04.4-live-server-amd64.iso"
    iso_checksum     = "file:https://releases.ubuntu.com/24.04/SHA256SUMS"   
    #iso_checksum     = "e907d92eeec9df64163a7e454cbc8d7755e8ddc7ed42f99dbc80c40f1a138433"  
    iso_storage_pool = "Synology-nfs"
    iso_download_pve = true
    unmount          = true
  }
  
  # Takes over the GRUB menu to point to user-data file
  boot_command = [
    "<spacebar><wait><spacebar><wait>",
    "c<wait>",
    "linux /casper/vmlinuz autoinstall ip=dhcp ds=nocloud-net\\;s=https://raw.githubusercontent.com/pmagyei/proxmox-homelab/refs/heads/master/packer/ubuntu24/http/ ---<enter><wait>",
    "initrd /casper/initrd<enter><wait>",
    "boot<enter>"
   ]
  
  # Logs in as the user defined in user-data
  ssh_username = "packer"
  ssh_password = "ubuntu"
  ssh_timeout  = "20m"
}

build {
  sources = ["source.proxmox-iso.ubuntu24"]

  provisioner "shell" {
    # passes  password so the script runs as root
    execute_command = "echo 'ubuntu' | sudo -S sh -c '{{ .Vars }} {{ .Path }}'"
    
    inline = [
      # 1. Waits for Cloud-Init
      "echo 'Waiting for Cloud-Init to finish...'",
      "while [ ! -f /var/lib/cloud/instance/boot-finished ]; do sleep 1; done",

      # 2. Netplan config for Dual-Stack Networking
      "echo 'Applying Dual-Stack Netplan for the final template...'",
      "cat <<EOF > /tmp/99-dual-stack.yaml",
      "network:",
      "  version: 2",
      "  ethernets:",
      "    main-interface:",
      "      match:",
      "        name: e*",
      "      dhcp4: true",
      "      dhcp-identifier: mac",
      "      dhcp6: true",
      "      accept-ra: true",
      "EOF",
      "mv /tmp/99-dual-stack.yaml /etc/netplan/99-dual-stack.yaml",

      # 3. Cleans up the system for cloning(terraform)
      "echo 'Cleaning up image...'",
      "apt-get clean",
      "rm -f /etc/ssh/ssh_host_*",
      "truncate -s 0 /etc/machine-id",
      "rm -f /var/lib/dbus/machine-id",
      "ln -s /etc/machine-id /var/lib/dbus/machine-id",
      "cloud-init clean --logs --seed"
    ]
  }
}