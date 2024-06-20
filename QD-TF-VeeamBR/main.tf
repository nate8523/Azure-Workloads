# Azure Provider source and version
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.67.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "2.3.0"
    }
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}
}

# Create random string to be used with unique resources
resource "random_string" "VeeamBR-V12-Unique" {
  length  = 5
  special = false
  upper   = false
}

# Create random string to be used as the VM Administrator password
resource "random_password" "VeeamBR-V12-password" {
  length      = 20
  min_lower   = 1
  min_upper   = 1
  min_numeric = 1
  min_special = 1
  special     = true
}

# Create a resource group
resource "azurerm_resource_group" "VeeamBR-V12-RG" {
  name     = "${var.ResourcePrefix}-RG-01"
  location = var.location
  tags     = var.DeploymentTags
}

# Create a storage account for the VM boot diagnostics
resource "azurerm_storage_account" "VeeamBR-V12-BootStorage" {
  name                     = "veeambrv12bootstr${random_string.VeeamBR-V12-Unique.result}"
  resource_group_name      = azurerm_resource_group.VeeamBR-V12-RG.name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = var.DeploymentTags
}

# Create a virtual network
resource "azurerm_virtual_network" "VeeamBR-V12-VNET" {
  name                = "${var.ResourcePrefix}-VNET-01"
  location            = var.location
  resource_group_name = azurerm_resource_group.VeeamBR-V12-RG.name
  address_space       = [var.VNETAddressSpace]

  tags = var.DeploymentTags
}

# Create virtual subnets
resource "azurerm_subnet" "VeeamBR-V12-SNET-1" {
  name                 = "${var.ResourcePrefix}-SNET-Data-01"
  resource_group_name  = azurerm_resource_group.VeeamBR-V12-RG.name
  virtual_network_name = azurerm_virtual_network.VeeamBR-V12-VNET.name
  address_prefixes     = [var.SNETAddressSpace]
}

# Create Network Security Group
resource "azurerm_network_security_group" "VeeamBR-V12-NSG" {
  name                = "${var.ResourcePrefix}-NSG-01"
  location            = var.location
  resource_group_name = azurerm_resource_group.VeeamBR-V12-RG.name

  tags = var.DeploymentTags
}

# Create NSG Rules
resource "azurerm_network_security_rule" "VeeamBR-V12-NSG-Rule1" {
  name                        = "CloudConnect-TCP"
  priority                    = 1010
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "6180"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.VeeamBR-V12-RG.name
  network_security_group_name = azurerm_network_security_group.VeeamBR-V12-NSG.name
}
resource "azurerm_network_security_rule" "VeeamBR-V12-NSG-Rule2" {
  name                        = "CloudConnect-UDP"
  priority                    = 1011
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "6180"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.VeeamBR-V12-RG.name
  network_security_group_name = azurerm_network_security_group.VeeamBR-V12-NSG.name
}
resource "azurerm_network_security_rule" "VeeamBR-V12-NSG-Rule3" {
  name                        = "AllowInbound-RDP"
  priority                    = 1012
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "3389"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.VeeamBR-V12-RG.name
  network_security_group_name = azurerm_network_security_group.VeeamBR-V12-NSG.name
}

# Associate NSG
resource "azurerm_subnet_network_security_group_association" "VeeamBR-V12-SNET-Access" {
  subnet_id                 = azurerm_subnet.VeeamBR-V12-SNET-1.id
  network_security_group_id = azurerm_network_security_group.VeeamBR-V12-NSG.id
}

# Create Public IP
resource "azurerm_public_ip" "VeeamBR-V12-PiP" {
  name                = "${var.ResourcePrefix}-Pip-01"
  resource_group_name = azurerm_resource_group.VeeamBR-V12-RG.name
  location            = var.location
  allocation_method   = "Static"

  tags = var.DeploymentTags
}

# Create Network Interface Adapter
resource "azurerm_network_interface" "VeeamBR-V12-NIC-01" {
  name                = "${var.ResourcePrefix}-NIC-01"
  location            = var.location
  resource_group_name = azurerm_resource_group.VeeamBR-V12-RG.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.VeeamBR-V12-SNET-1.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.VeeamBR-V12-PiP.id
  }

  tags = var.DeploymentTags
}

resource "azurerm_marketplace_agreement" "VeeamBR-V12-Agreement" {
  publisher = var.Publisher
  offer     = var.Offer
  plan      = var.Plan
}

resource "azurerm_windows_virtual_machine" "VeeamBR-V12-VM" {
  name                = var.VMName
  resource_group_name = azurerm_resource_group.VeeamBR-V12-RG.name
  location            = var.location
  size                = var.VM-Size
  admin_username      = var.admin_username
  admin_password      = random_password.VeeamBR-V12-password.result
  network_interface_ids = [
    azurerm_network_interface.VeeamBR-V12-NIC-01.id,
  ]

  os_disk {
    name                 = "${var.VMName}-OS-Disk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = var.Publisher
    offer     = var.Offer
    sku       = var.Plan
    version   = "latest"
  }

  plan {
    publisher = var.Publisher
    name      = var.Plan
    product   = var.Offer
  }

  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.VeeamBR-V12-BootStorage.primary_blob_endpoint
  }
}

resource "azurerm_managed_disk" "VeeamBR-V12-DataDisk" {
  count                = var.NoOfDataDisks
  name                 = "${var.VMName}-Data-Disk-${format("%02d", count.index + 1)}"
  location             = var.location
  resource_group_name  = azurerm_resource_group.VeeamBR-V12-RG.name
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = "32"

  tags = var.DeploymentTags
}

resource "azurerm_virtual_machine_data_disk_attachment" "VeeamBR-V12-DataDisk-Attach" {
  count              = var.NoOfDataDisks
  managed_disk_id    = azurerm_managed_disk.VeeamBR-V12-DataDisk[count.index].id
  virtual_machine_id = azurerm_windows_virtual_machine.VeeamBR-V12-VM.id
  caching            = "ReadWrite"
  create_option      = "Attach"
  lun                = count.index
}

resource "azurerm_virtual_machine_extension" "data_disks" {
  depends_on           = [azurerm_windows_virtual_machine.VeeamBR-V12-VM, azurerm_virtual_machine_data_disk_attachment.VeeamBR-V12-DataDisk-Attach]
  name                 = "data_disks"
  virtual_machine_id   = azurerm_windows_virtual_machine.VeeamBR-V12-VM.id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.10"
  settings             = <<SETTINGS
    {
        "commandToExecute": "powershell -ExecutionPolicy Unrestricted -File Customise-Veeam-Backupv2.ps1"
    }
SETTINGS

  protected_settings = jsonencode({
    "fileUris" : ["https://raw.githubusercontent.com/nate8523/Azure-Workloads/main/Customise-Veeam-Backupv2.ps1"]
  })
}