terraform {

    required_version = ">= 1.6.0"
    required_providers {
     azurerm = {
       source = "hashicorp/azurerm",
       version = "~> 4.0"
    }

  }


}

provider "azurerm" {
   features {

  }
   subscription_id = var.subscription_id
}

locals {
   common_tags = merge( {
     environment = "production",
     project = "hub-spoke",
     managed_by = "terraform"
  }
  ,
   var.tags)
}

resource "azurerm_resource_group" "this" {
   name = "rg-${var.prefix}-network"
   location = var.location
   tags = local.common_tags
}

resource "azurerm_log_analytics_workspace" "this" {
   name = "law-${var.prefix}-network"
   location = azurerm_resource_group.this.location
   resource_group_name = azurerm_resource_group.this.name
   sku = "PerGB2018"
   retention_in_days = var.log_retention_in_days
   tags = local.common_tags
}

resource "azurerm_virtual_network" "hub" {
   name = "vnet-${var.prefix}-hub"
   location = azurerm_resource_group.this.location
   resource_group_name = azurerm_resource_group.this.name
   address_space = [var.hub_vnet_cidr]
   tags = local.common_tags
}

resource "azurerm_subnet" "hub_firewall" {
   name = "AzureFirewallSubnet"
   resource_group_name = azurerm_resource_group.this.name
   virtual_network_name = azurerm_virtual_network.hub.name
   address_prefixes = [var.hub_subnets.firewall]
}

resource "azurerm_subnet" "hub_bastion" {
   name = "AzureBastionSubnet"
   resource_group_name = azurerm_resource_group.this.name
   virtual_network_name = azurerm_virtual_network.hub.name
   address_prefixes = [var.hub_subnets.bastion]
}

resource "azurerm_subnet" "hub_gateway" {
   name = "GatewaySubnet"
   resource_group_name = azurerm_resource_group.this.name
   virtual_network_name = azurerm_virtual_network.hub.name
   address_prefixes = [var.hub_subnets.gateway]
}

resource "azurerm_subnet" "hub_management" {
   name = "snet-management"
   resource_group_name = azurerm_resource_group.this.name
   virtual_network_name = azurerm_virtual_network.hub.name
   address_prefixes = [var.hub_subnets.management]
}

resource "azurerm_public_ip" "firewall" {
   name = "pip-${var.prefix}-fw"
   location = var.location
   resource_group_name = azurerm_resource_group.this.name
   allocation_method = "Static"
   sku = "Standard"
   tags = local.common_tags
}

resource "azurerm_public_ip" "bastion" {
   name = "pip-${var.prefix}-bastion"
   location = var.location
   resource_group_name = azurerm_resource_group.this.name
   allocation_method = "Static"
   sku = "Standard"
   tags = local.common_tags
}

resource "azurerm_public_ip" "vpn" {
   name = "pip-${var.prefix}-vpn"
   location = var.location
   resource_group_name = azurerm_resource_group.this.name
   allocation_method = "Static"
   sku = "Standard"
   tags = local.common_tags
}

resource "azurerm_firewall" "this" {
   name = "fw-${var.prefix}-hub"
   location = var.location
   resource_group_name = azurerm_resource_group.this.name
   sku_name = "AZFW_VNet"
   sku_tier = var.firewall_sku_tier
   tags = local.common_tags ip_configuration {
     name = "configuration"
     subnet_id = azurerm_subnet.hub_firewall.id
     public_ip_address_id = azurerm_public_ip.firewall.id
  }

}

resource "azurerm_bastion_host" "this" {
   name = "bas-${var.prefix}-hub"
   location = var.location
   resource_group_name = azurerm_resource_group.this.name
   tags = local.common_tags ip_configuration {
     name = "configuration"
     subnet_id = azurerm_subnet.hub_bastion.id
     public_ip_address_id = azurerm_public_ip.bastion.id
  }

}

resource "azurerm_virtual_network_gateway" "this" {
   name = "vgw-${var.prefix}-hub"
   location = var.location
   resource_group_name = azurerm_resource_group.this.name
   type = "Vpn"
   vpn_type = "RouteBased"
   sku = var.vpn_gateway_sku
   active_active = false
   enable_bgp = false
   tags = local.common_tags ip_configuration {
     name = "vpngw"
     public_ip_address_id = azurerm_public_ip.vpn.id
     subnet_id = azurerm_subnet.hub_gateway.id
     private_ip_address_allocation = "Dynamic"
  }

}

resource "azurerm_virtual_network" "spoke" {
   for_each = var.spoke_vnets
   name = "vnet-${var.prefix}-${each.key}"
   location = var.location
   resource_group_name = azurerm_resource_group.this.name
   address_space = each.value.address_space
   tags = merge(local.common_tags,
   {
     spoke = each.key
  }
  )
}

resource "azurerm_subnet" "spoke_workload" {
   for_each = var.spoke_vnets
   name = "snet-workload"
   resource_group_name = azurerm_resource_group.this.name
   virtual_network_name = azurerm_virtual_network.spoke[each.key].name
   address_prefixes = [each.value.workload_subnet_cidr]
}

resource "azurerm_network_security_group" "spoke" {
   for_each = var.spoke_vnets
   name = "nsg-${var.prefix}-${each.key}"
   location = var.location
   resource_group_name = azurerm_resource_group.this.name
   tags = merge(local.common_tags,
   {
     spoke = each.key
  }
  ) security_rule {
     name = "Allow-Hub-Management"
     priority = 100
     direction = "Inbound"
     access = "Allow"
     protocol = "Tcp"
     source_port_range = "*"
     destination_port_range = "*"
     source_address_prefix = var.hub_subnets.management
     destination_address_prefix = "*"
  }

}

resource "azurerm_subnet_network_security_group_association" "spoke" {
   for_each = var.spoke_vnets
   subnet_id = azurerm_subnet.spoke_workload[each.key].id
   network_security_group_id = azurerm_network_security_group.spoke[each.key].id
}

resource "azurerm_route_table" "spoke" {
   for_each = var.spoke_vnets
   name = "rt-${var.prefix}-${each.key}"
   location = var.location
   resource_group_name = azurerm_resource_group.this.name
   tags = merge(local.common_tags,
   {
     spoke = each.key
  }
  ) route {
     name = "default-to-firewall"
     address_prefix = "0.0.0.0/0"
     next_hop_type = "VirtualAppliance"
     next_hop_in_ip_address = azurerm_firewall.this.ip_configuration[0].private_ip_address
  }

}

resource "azurerm_subnet_route_table_association" "spoke" {
   for_each = var.spoke_vnets
   subnet_id = azurerm_subnet.spoke_workload[each.key].id
   route_table_id = azurerm_route_table.spoke[each.key].id
}

resource "azurerm_virtual_network_peering" "hub_to_spoke" {
   for_each = var.spoke_vnets
   name = "peer-hub-to-${each.key}"
   resource_group_name = azurerm_resource_group.this.name
   virtual_network_name = azurerm_virtual_network.hub.name
   remote_virtual_network_id = azurerm_virtual_network.spoke[each.key].id
   allow_virtual_network_access = true
   allow_forwarded_traffic = true
   allow_gateway_transit = true
}

resource "azurerm_virtual_network_peering" "spoke_to_hub" {
   for_each = var.spoke_vnets
   name = "peer-${each.key}-to-hub"
   resource_group_name = azurerm_resource_group.this.name
   virtual_network_name = azurerm_virtual_network.spoke[each.key].name
   remote_virtual_network_id = azurerm_virtual_network.hub.id
   allow_virtual_network_access = true
   allow_forwarded_traffic = true
   use_remote_gateways = true
}

resource "azurerm_monitor_diagnostic_setting" "firewall" {
   name = "diag-firewall"
   target_resource_id = azurerm_firewall.this.id
   log_analytics_workspace_id = azurerm_log_analytics_workspace.this.id enabled_log {
     category_group = "allLogs"
  }
   metric {
     category = "AllMetrics"
  }

}

resource "azurerm_monitor_diagnostic_setting" "bastion" {
   name = "diag-bastion"
   target_resource_id = azurerm_bastion_host.this.id
   log_analytics_workspace_id = azurerm_log_analytics_workspace.this.id enabled_log {
     category_group = "allLogs"
  }
   metric {
     category = "AllMetrics"
  }

}

resource "azurerm_monitor_diagnostic_setting" "vpn" {
   name = "diag-vpn"
   target_resource_id = azurerm_virtual_network_gateway.this.id
   log_analytics_workspace_id = azurerm_log_analytics_workspace.this.id enabled_log {
     category_group = "allLogs"
  }
   metric {
     category = "AllMetrics"
  }

}
