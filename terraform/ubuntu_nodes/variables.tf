# 1. Define variables for lab environment
variable "vm_count" {
  description = "Number of VMs to spin up for the lab"
  type        = number
  default     = 2
}

# 2. Tells Terraform where to find the public SSH key on my Mac
variable "ssh_public_key" {
  type    = string
  default = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIH4P3ikoeLz6ROeFGuuH8t1bUdFpTrpPDHrucNvKGHTm dantejit@MBPDante"
}
