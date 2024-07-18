# Specify the required providers
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">=2.0"
    }
  }
}
provider "azurerm" {
  features {}
}

locals {
}

# Create Azure Resource Group
resource "azurerm_resource_group" "fortigate_resource_group" {
  name     = "QD-RG-${var.customerNamePrefix}-FW-${var.customerInstanceNo}"
  location = var.location
  tags     = var.tags
}
# Marketplace agreement.
resource "azurerm_marketplace_agreement" "fortigate_agreement" {
  count     = var.accept ? 1 : 0
  publisher = var.publisher
  offer     = var.fortiGate_offer
  plan      = var.license_type == "byol" ? var.fortiGate_sku["byol"] : var.fortiGate_sku["payg"]
}
# Create Virtual Network
resource "azurerm_virtual_network" "fortigate_network" {
  name                = "QD-VNET-${var.customerNamePrefix}-FW-${var.customerInstanceNo}"
  address_space       = [var.vnetAddressPrefix]
  location            = var.location
  resource_group_name = azurerm_resource_group.fortigate_resource_group.name

  tags = var.tags
}
# Create External Subnet
resource "azurerm_subnet" "external_subnet" {
  name                 = "QD-SNET-${var.customerNamePrefix}-External-${var.customerInstanceNo}"
  resource_group_name  = azurerm_resource_group.fortigate_resource_group.name
  virtual_network_name = azurerm_virtual_network.fortigate_network.name
  address_prefixes     = [var.external_subnet]
}
# Create Internal Subnet
resource "azurerm_subnet" "internal_subnet" {
  name                 = "QD-SNET-${var.customerNamePrefix}-Internal-${var.customerInstanceNo}"
  resource_group_name  = azurerm_resource_group.fortigate_resource_group.name
  virtual_network_name = azurerm_virtual_network.fortigate_network.name
  address_prefixes     = [var.internal_subnet]
}
# Create Public IP Address
resource "azurerm_public_ip" "fortigate" {
  name                = "QD-PiP-${var.customerNamePrefix}-FW-${var.customerInstanceNo}"
  location            = var.location
  resource_group_name = azurerm_resource_group.fortigate_resource_group.name
  allocation_method   = var.publicIP1AddressType
  sku                 = var.publicIP1SKU
  domain_name_label   = lower("${var.customerNamePrefix}-FW-${var.customerInstanceNo}")
  tags                = var.tags
}
# Create Network Security Group
resource "azurerm_network_security_group" "external_network_nsg" {
  name                = "QD-NSG-${var.customerNamePrefix}-External-${var.customerInstanceNo}"
  location            = var.location
  resource_group_name = azurerm_resource_group.fortigate_resource_group.name

  security_rule {
    name                       = "TCP"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = var.tags
}
resource "azurerm_network_security_group" "internal_network_nsg" {
  name                = "QD-NSG-${var.customerNamePrefix}-Internal-${var.customerInstanceNo}"
  location            = var.location
  resource_group_name = azurerm_resource_group.fortigate_resource_group.name

  security_rule {
    name                       = "All"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = var.tags
}
resource "azurerm_network_security_rule" "outgoing_external" {
  name                        = "egress"
  priority                    = 100
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.fortigate_resource_group.name
  network_security_group_name = azurerm_network_security_group.external_network_nsg.name
}
resource "azurerm_network_security_rule" "outgoing_internal" {
  name                        = "egress-private"
  priority                    = 100
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.fortigate_resource_group.name
  network_security_group_name = azurerm_network_security_group.internal_network_nsg.name
}
# Create Network Interface port1 - External
resource "azurerm_network_interface" "fortiGate_port1_external" {
  name                = "QD-NIC-${var.customerNamePrefix}-External-${var.customerInstanceNo}"
  location            = var.location
  resource_group_name = azurerm_resource_group.fortigate_resource_group.name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.external_subnet.id
    private_ip_address_allocation = "Dynamic"
    primary                       = true
    public_ip_address_id          = azurerm_public_ip.fortigate.id
  }

  tags = var.tags
}
# Create Network Interface port2 - Internal
resource "azurerm_network_interface" "fortiGate_port2_internal" {
  name                  = "QD-NIC-${var.customerNamePrefix}-Internal-${var.customerInstanceNo}"
  location              = var.location
  resource_group_name   = azurerm_resource_group.fortigate_resource_group.name
  ip_forwarding_enabled = true

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.internal_subnet.id
    private_ip_address_allocation = "Dynamic"
  }

  tags = var.tags
}
# Connect the security group to the network interfaces
resource "azurerm_network_interface_security_group_association" "fortiGate_port1_external" {
  depends_on                = [azurerm_network_interface.fortiGate_port1_external]
  network_interface_id      = azurerm_network_interface.fortiGate_port1_external.id
  network_security_group_id = azurerm_network_security_group.external_network_nsg.id
}
resource "azurerm_network_interface_security_group_association" "fortiGate_port2_internal" {
  depends_on                = [azurerm_network_interface.fortiGate_port2_internal]
  network_interface_id      = azurerm_network_interface.fortiGate_port2_internal.id
  network_security_group_id = azurerm_network_security_group.internal_network_nsg.id
}
# Create Storage Account for boot Diagnostics
resource "random_id" "randomId" {
  keepers = {
    resource_group = azurerm_resource_group.fortigate_resource_group.name
  }

  byte_length = 8
}

resource "azurerm_storage_account" "fortiGate_storageaccount" {
  name                     = "diag${random_id.randomId.hex}"
  resource_group_name      = azurerm_resource_group.fortigate_resource_group.name
  location                 = var.location
  account_replication_type = "LRS"
  account_tier             = "Standard"
  min_tls_version          = "TLS1_2"

  tags = var.tags
}

# Create Firewall VM
resource "azurerm_virtual_machine" "fortiGate_vm" {
  zones                        = [1]
  name                         = "QD-VM-${var.customerNamePrefix}-FW-${var.customerInstanceNo}"
  location                     = var.location
  resource_group_name          = azurerm_resource_group.fortigate_resource_group.name
  network_interface_ids        = [azurerm_network_interface.fortiGate_port1_external.id, azurerm_network_interface.fortiGate_port2_internal.id]
  primary_network_interface_id = azurerm_network_interface.fortiGate_port1_external.id
  vm_size                      = var.size

  delete_os_disk_on_termination    = true
  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = var.publisher
    offer     = var.fortiGate_offer
    sku       = var.license_type == "byol" ? var.fortiGate_sku["byol"] : var.fortiGate_sku["payg"]
    version   = var.fortiGate_version
  }

  plan {
    name      = var.license_type == "byol" ? var.fortiGate_sku["byol"] : var.fortiGate_sku["payg"]
    publisher = var.publisher
    product   = var.fortiGate_offer
  }

  storage_os_disk {
    name              = "QD-VM-${var.customerNamePrefix}-FW-${var.customerInstanceNo}-OSDisk"
    caching           = "ReadWrite"
    managed_disk_type = "Standard_LRS"
    create_option     = "FromImage"
  }

  # Log data disks
  storage_data_disk {
    name              = "QD-VM-${var.customerNamePrefix}-FW-${var.customerInstanceNo}-DataDisk"
    managed_disk_type = "Standard_LRS"
    create_option     = "Empty"
    lun               = 0
    disk_size_gb      = "30"
  }

  os_profile {
    computer_name  = "QD-VM-${var.customerNamePrefix}-FW-${var.customerInstanceNo}"
    admin_username = var.adminusername
    admin_password = var.adminpassword
    custom_data = templatefile("${var.bootstrap-fortiGate_vm}", {
      type         = var.license_type
      license_file = var.license
      format       = "${var.license_format}"
    })
  }


  os_profile_linux_config {
    disable_password_authentication = false
  }

  boot_diagnostics {
    enabled     = true
    storage_uri = azurerm_storage_account.fortiGate_storageaccount.primary_blob_endpoint
  }

  tags = var.tags
}

output "ResourceGroup" {
  value = azurerm_resource_group.fortigate_resource_group.name
}

output "Fortigate_PublicIP" {
  value = format("https://%s", azurerm_public_ip.fortigate.ip_address)
}

output "Username" {
  value = var.adminusername
}

output "Password" {
  value = var.adminpassword
}