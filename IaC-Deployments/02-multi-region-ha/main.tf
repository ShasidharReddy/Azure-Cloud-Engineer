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

locals {

    common_tags = merge( {
     environment = "production",
     project = "multi-region-ha",
     managed_by = "terraform"
  }
  ,
   var.tags)
    region_vm_map = {
     for item in flatten([for region in var.regions : [for idx in range(var.vm_count_per_region) : {
       key = "${region}-${idx + 1}",
       region = region,
       index = idx + 1,
       zone = lookup(var.zones,
       region,
       ["1"])[idx % length(lookup(var.zones,
       region,
       ["1"]))]
    }
    ]]) : item.key => item
  }

    primary_region = var.regions[0]
    secondary_region = var.regions[1]
    cloud_init = base64encode(<<-EOT
    #cloud-config
    package_update: true
    packages: [nginx]
    runcmd:
      - systemctl enable nginx
      - systemctl restart nginx
      - echo "$(hostname)" > /var/www/html/index.html
  EOT
  )

}

resource "random_string" "suffix" {
   length = 5
   upper = false
   special = false
}

resource "azurerm_resource_group" "region" {
   for_each = toset(var.regions)
   name = "rg-${var.prefix}-${each.key}-ha"
   location = each.key
   tags = merge(local.common_tags,
   {
     region = each.key
  }
  )
}

resource "azurerm_virtual_network" "region" {
   for_each = toset(var.regions)
   name = "vnet-${var.prefix}-${each.key}-ha"
   location = each.key
   resource_group_name = azurerm_resource_group.region[each.key].name
   address_space = [var.region_cidrs[each.key].vnet]
   tags = merge(local.common_tags,
   {
     region = each.key
  }
  )
}

resource "azurerm_subnet" "region" {
   for_each = toset(var.regions)
   name = "snet-workload"
   resource_group_name = azurerm_resource_group.region[each.key].name
   virtual_network_name = azurerm_virtual_network.region[each.key].name
   address_prefixes = [var.region_cidrs[each.key].subnet]
}

resource "azurerm_network_security_group" "region" {

    for_each = toset(var.regions)
    name = "nsg-${var.prefix}-${each.key}-ha"
    location = each.key
    resource_group_name = azurerm_resource_group.region[each.key].name
    tags = merge(local.common_tags,
   {
     region = each.key
  }
  )
    security_rule {
     name = "Allow-HTTP"
     priority = 100
     direction = "Inbound"
     access = "Allow"
     protocol = "Tcp"
     source_port_range = "*"
     destination_port_range = "80"
     source_address_prefix = "AzureLoadBalancer"
     destination_address_prefix = "*"
  }

    security_rule {
     name = "Allow-SSH"
     priority = 110
     direction = "Inbound"
     access = "Allow"
     protocol = "Tcp"
     source_port_range = "*"
     destination_port_range = "22"
     source_address_prefix = var.management_source_cidr
     destination_address_prefix = "*"
  }


}

resource "azurerm_subnet_network_security_group_association" "region" {
   for_each = toset(var.regions)
   subnet_id = azurerm_subnet.region[each.key].id
   network_security_group_id = azurerm_network_security_group.region[each.key].id
}

resource "azurerm_public_ip" "lb" {
   for_each = toset(var.regions)
   name = "pip-${var.prefix}-${each.key}-lb"
   location = each.key
   resource_group_name = azurerm_resource_group.region[each.key].name
   allocation_method = "Static"
   sku = "Standard"
   tags = merge(local.common_tags,
   {
     region = each.key
  }
  )
}

resource "azurerm_lb" "region" {
   for_each = toset(var.regions)
   name = "lb-${var.prefix}-${each.key}"
   location = each.key
   resource_group_name = azurerm_resource_group.region[each.key].name
   sku = "Standard"
   tags = merge(local.common_tags,
   {
     region = each.key
  }
  ) frontend_ip_configuration {
     name = "public"
     public_ip_address_id = azurerm_public_ip.lb[each.key].id
  }

}

resource "azurerm_lb_backend_address_pool" "region" {
   for_each = toset(var.regions)
   loadbalancer_id = azurerm_lb.region[each.key].id
   name = "backend"
}

resource "azurerm_lb_probe" "region" {
   for_each = toset(var.regions)
   loadbalancer_id = azurerm_lb.region[each.key].id
   name = "http-probe"
   protocol = "Tcp"
   port = 80
   interval_in_seconds = 5
   number_of_probes = 2
}

resource "azurerm_lb_rule" "region" {
   for_each = toset(var.regions)
   loadbalancer_id = azurerm_lb.region[each.key].id
   name = "http"
   protocol = "Tcp"
   frontend_port = 80
   backend_port = 80
   frontend_ip_configuration_name = "public"
   probe_id = azurerm_lb_probe.region[each.key].id
   backend_address_pool_ids = [azurerm_lb_backend_address_pool.region[each.key].id]
}

resource "azurerm_network_interface" "vm" {
   for_each = local.region_vm_map
   name = "nic-${var.prefix}-${each.value.region}-${each.value.index}"
   location = each.value.region
   resource_group_name = azurerm_resource_group.region[each.value.region].name
   tags = merge(local.common_tags,
   {
     region = each.value.region
  }
  ) ip_configuration {
     name = "internal"
     subnet_id = azurerm_subnet.region[each.value.region].id
     private_ip_address_allocation = "Dynamic"
  }

}

resource "azurerm_network_interface_backend_address_pool_association" "vm" {
   for_each = local.region_vm_map
   network_interface_id = azurerm_network_interface.vm[each.key].id
   ip_configuration_name = "internal"
   backend_address_pool_id = azurerm_lb_backend_address_pool.region[each.value.region].id
}

resource "azurerm_linux_virtual_machine" "vm" {

    for_each = local.region_vm_map
    name = "vm-${var.prefix}-${each.value.region}-${each.value.index}"
    location = each.value.region
    resource_group_name = azurerm_resource_group.region[each.value.region].name
    size = var.vm_size
    admin_username = var.admin_username
    disable_password_authentication = true
    network_interface_ids = [azurerm_network_interface.vm[each.key].id]
    zone = each.value.zone
    custom_data = local.cloud_init
    tags = merge(local.common_tags,
   {
     region = each.value.region,
     zone = each.value.zone
  }
  )
    admin_ssh_key {
     username = var.admin_username
     public_key = var.ssh_public_key
  }

    os_disk {
     name = "osdisk-${var.prefix}-${each.value.region}-${each.value.index}"
     caching = "ReadWrite"
     storage_account_type = "Premium_LRS"
  }

    source_image_reference {
     publisher = "Canonical"
     offer = "0001-com-ubuntu-server-jammy"
     sku = "22_04-lts-gen2"
     version = "latest"
  }


}

resource "azurerm_traffic_manager_profile" "global" {

    name = "tm-${var.prefix}-${random_string.suffix.result}"
    resource_group_name = azurerm_resource_group.region[local.primary_region].name
    traffic_routing_method = "Priority"
    tags = local.common_tags
    dns_config {
     relative_name = "tm-${var.prefix}-${random_string.suffix.result}"
     ttl = 30
  }

    monitor_config {
     protocol = "HTTP"
     port = 80
     path = "/"
     expected_status_code_ranges = ["200-399"]
     interval_in_seconds = 30
     timeout_in_seconds = 9
     tolerated_number_of_failures = 3
  }


}

resource "azurerm_traffic_manager_azure_endpoint" "regional" {
   for_each = toset(var.regions)
   name = "ep-${each.key}"
   profile_id = azurerm_traffic_manager_profile.global.id
   target_resource_id = azurerm_public_ip.lb[each.key].id
   priority = index(var.regions,
   each.key) + 1 weight = 100
}

resource "azurerm_virtual_network_peering" "primary_to_secondary" {
   name = "peer-${local.primary_region}-to-${local.secondary_region}"
   resource_group_name = azurerm_resource_group.region[local.primary_region].name
   virtual_network_name = azurerm_virtual_network.region[local.primary_region].name
   remote_virtual_network_id = azurerm_virtual_network.region[local.secondary_region].id
   allow_virtual_network_access = true
   allow_forwarded_traffic = true
}

resource "azurerm_virtual_network_peering" "secondary_to_primary" {
   name = "peer-${local.secondary_region}-to-${local.primary_region}"
   resource_group_name = azurerm_resource_group.region[local.secondary_region].name
   virtual_network_name = azurerm_virtual_network.region[local.secondary_region].name
   remote_virtual_network_id = azurerm_virtual_network.region[local.primary_region].id
   allow_virtual_network_access = true
   allow_forwarded_traffic = true
}

resource "azurerm_storage_account" "shared" {
   name = "st${var.prefix}ha${random_string.suffix.result}"
   location = azurerm_resource_group.region[local.primary_region].location
   resource_group_name = azurerm_resource_group.region[local.primary_region].name
   account_tier = "Standard"
   account_replication_type = "GRS"
   min_tls_version = "TLS1_2"
   allow_nested_items_to_be_public = false
   tags = local.common_tags
}
