terraform {

    required_version = ">= 1.6.0"
    required_providers {

        azurerm = {
       source = "hashicorp/azurerm",
       version = "~> 4.0"
    }

        random  = {
       source = "hashicorp/random",
        version = "~> 3.6"
    }


  }


}

provider "azurerm" {
   features {

  }
   subscription_id = var.subscription_id
}

data "azurerm_subscription" "current" {

}

locals {

    name_prefix = lower(replace("${var.prefix}-${var.vm_name}",
   "_",
   "-"))
    common_tags = merge( {
     environment = "production",
     project = "single-vm",
     managed_by = "terraform",
     subscription = data.azurerm_subscription.current.display_name
  }
  ,
   var.tags)

}

resource "random_string" "suffix" {
   length = 6
   upper = false
   special = false
}

resource "azurerm_resource_group" "this" {
   name = "rg-${local.name_prefix}"
   location = var.location
   tags = local.common_tags
}

resource "azurerm_virtual_network" "this" {
   name = "vnet-${local.name_prefix}"
   location = azurerm_resource_group.this.location
   resource_group_name = azurerm_resource_group.this.name
   address_space = [var.vnet_cidr]
   tags = local.common_tags
}

resource "azurerm_subnet" "this" {
   name = "snet-workload"
   resource_group_name = azurerm_resource_group.this.name
   virtual_network_name = azurerm_virtual_network.this.name
   address_prefixes = [var.subnet_cidr]
}

resource "azurerm_network_security_group" "this" {

    name = "nsg-${local.name_prefix}"
    location = azurerm_resource_group.this.location
    resource_group_name = azurerm_resource_group.this.name
    tags = local.common_tags
    security_rule {
     name = "Allow-SSH"
     priority = 100
     direction = "Inbound"
     access = "Allow"
     protocol = "Tcp"
     source_port_range = "*"
     destination_port_range = "22"
     source_address_prefix = "*"
     destination_address_prefix = "*"
  }

    security_rule {
     name = "Allow-RDP"
     priority = 110
     direction = "Inbound"
     access = "Allow"
     protocol = "Tcp"
     source_port_range = "*"
     destination_port_range = "3389"
     source_address_prefix = "*"
     destination_address_prefix = "*"
  }


}

resource "azurerm_subnet_network_security_group_association" "this" {
   subnet_id = azurerm_subnet.this.id
   network_security_group_id = azurerm_network_security_group.this.id
}

resource "azurerm_public_ip" "this" {
   name = "pip-${local.name_prefix}"
   location = azurerm_resource_group.this.location
   resource_group_name = azurerm_resource_group.this.name
   allocation_method = "Static"
   sku = "Standard"
   zones = ["1",
   "2",
   "3"] tags = local.common_tags
}

resource "azurerm_network_interface" "this" {

    name = "nic-${local.name_prefix}"
    location = azurerm_resource_group.this.location
    resource_group_name = azurerm_resource_group.this.name
    tags = local.common_tags
    ip_configuration {
     name = "primary"
     subnet_id = azurerm_subnet.this.id
     private_ip_address_allocation = "Dynamic"
     public_ip_address_id = azurerm_public_ip.this.id
  }


}

resource "azurerm_storage_account" "bootdiag" {
   name = "st${replace(local.name_prefix, "-", "")}${random_string.suffix.result}"
   resource_group_name = azurerm_resource_group.this.name
   location = azurerm_resource_group.this.location
   account_tier = "Standard"
   account_replication_type = "LRS"
   min_tls_version = "TLS1_2"
   allow_nested_items_to_be_public = false
   tags = local.common_tags
}

resource "azurerm_linux_virtual_machine" "this" {

    name = var.vm_name
    location = azurerm_resource_group.this.location
    resource_group_name = azurerm_resource_group.this.name
    size = var.vm_size
    admin_username = var.admin_username
    disable_password_authentication = true
    network_interface_ids = [azurerm_network_interface.this.id]
    tags = local.common_tags
    admin_ssh_key {
     username = var.admin_username
     public_key = var.ssh_public_key
  }

    os_disk {
     name = "osdisk-${local.name_prefix}"
     caching = "ReadWrite"
     storage_account_type = "Premium_LRS"
     disk_size_gb = 64
  }

    source_image_reference {
     publisher = "Canonical"
     offer = "0001-com-ubuntu-server-jammy"
     sku = "22_04-lts-gen2"
     version = "latest"
  }

    boot_diagnostics {
     storage_account_uri = azurerm_storage_account.bootdiag.primary_blob_endpoint
  }


}

resource "azurerm_managed_disk" "data" {
   name = "datadisk-${local.name_prefix}"
   location = azurerm_resource_group.this.location
   resource_group_name = azurerm_resource_group.this.name
   storage_account_type = "Premium_LRS"
   create_option = "Empty"
   disk_size_gb = var.data_disk_size_gb
   tags = local.common_tags
}

resource "azurerm_virtual_machine_data_disk_attachment" "data" {
   managed_disk_id = azurerm_managed_disk.data.id
   virtual_machine_id = azurerm_linux_virtual_machine.this.id
   lun = 10
   caching = "ReadWrite"
}
