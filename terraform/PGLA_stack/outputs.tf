output "pgla_host" {
  description = "DHCP-assigned IP addresses for the PGLA host"
  value = {
    for vm in proxmox_virtual_environment_vm.pgla_host : vm.name => {
      ipv4 = try(vm.ipv4_addresses[1][0], "Waiting on DHCP...")
      ipv6 = try(vm.ipv6_addresses[1][0], "Waiting on DHCP...")
    }
  }
}