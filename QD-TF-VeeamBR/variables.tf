variable "ResourcePrefix" {
  type    = string
  default = "VeeamV12"
}
variable "location" {
  type    = string
  default = "UK South"
}
variable "DeploymentTags" {
  default = {
    project     = "VeeamBR-V12"
    environment = "Dev"
  }
}
variable "VNETAddressSpace" {
  type    = string
  default = "10.10.0.0/16"
}
variable "SNETAddressSpace" {
  type    = string
  default = "10.10.1.0/24"
}
variable "VMName" {
  type    = string
  default = "VeeamBR-VM-01"
}
variable "admin_username" {
  type    = string
  default = "adminuser"
}
variable "Publisher" {
  type    = string
  default = "veeam"
}
variable "Offer" {
  type    = string
  default = "veeam-backup-replication"
}
variable "Plan" {
  type    = string
  default = "veeam-backup-replication-v12"
}
variable "NoOfDataDisks" {
  type    = number
  default = 2
}
variable "VM-Size" {
  type    = string
  default = "Standard_D2s_v3"
  validation {
    condition     = contains(["Standard_B1ms", "Standard_D2s_v3", "Standard_A2", "Standard_A3", "Standard_A4"], var.VM-Size)
    error_message = "VM size must be one of: Standard_B1ms, Standard_A2, Standard_A3, Standard_A4."
  }
}