output "lab_ip_addresses" {
  description = "DHCP-assigned IP addresses for the Ubuntu Server lab nodes"
  value = {
    for vm in proxmox_virtual_environment_vm.ubuntu_lab_nodes : vm.name => {
      ipv4 = try(vm.ipv4_addresses[1][0], "Waiting on DHCP...")
      ipv6 = try(vm.ipv6_addresses[1][0], "Waiting on DHCP...")
    }
  }
}