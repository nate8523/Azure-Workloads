variable "location" {
  description = "Azure region where resources will be deployed"
  default     = "UK South"
}

variable "customerNamePrefix" {
  description = "Prefix to be used in resource names"
  default     = "Customer"
}

variable "customerInstanceNo" {
  description = "Increment number for resource names"
  default     = "01"
}
variable "tags" {
  description = "Tags for the Azure resources"
  default = {
    Environment = "Production"
    Deployment  = "FortiGate Single VM"
  }
}

variable "accept" {
  description = "To accept marketplace agreement. Default is false"
  default     = "true"
}

variable "license_type" {
  description = "Provide the license type for FortiGate-VM Instances, either byol or payg"
  default     = "payg"
}

// BYOL License format to create FortiGate-VM
// Provide the license type for FortiGate-VM Instances, either token or file.
variable "license_format" {
  default = "token"
}

variable "publisher" {
  type    = string
  default = "fortinet"
}

variable "fortiGate_offer" {
  type    = string
  default = "fortinet_fortigate-vm_v5"
}

// BYOL sku: fortinet_fg-vm
// PAYG sku: fortinet_fg-vm_payg_2022
variable "fortiGate_sku" {
  type = map(any)
  default = {
    byol = "fortinet_fg-vm"
    payg = "fortinet_fg-vm_payg_2023"
  }
}

variable "vnetAddressPrefix" {
  description = "Virtual Network Address prefix"
  type        = string
  default     = "10.1.0.0/16"
}

variable "external_subnet" {
  description = "External Subnet Prefix"
  type        = string
  default     = "10.1.0.0/24"
}

variable "internal_subnet" {
  description = "Internal Subnet Prefix"
  type        = string
  default     = "10.1.1.0/24"
}

variable "publicIP1AddressType" {
  description = "Type of public IP address"
  type        = string
  default     = "Static"
}

variable "publicIP1SKU" {
  description = "Type of public IP address"
  type        = string
  default     = "Standard"
}

variable "size" {
  type    = string
  default = "Standard_F2s"
}

variable "fortiGate_version" {
  type    = string
  default = "7.4.4"
}

variable "adminusername" {
  type    = string
  default = "azureadmin"
}

variable "adminpassword" {
  type    = string
  default = "Fortinet123#"
}

variable "bootstrap-fortiGate_vm" {
  // Change to your own path
  type    = string
  default = "fortigate.conf"
}

// license file for the fortiGate
variable "license" {
  // Change to your own byol license file, license.lic
  type    = string
  default = "license.txt"
}