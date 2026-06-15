terraform {

    required_version = ">= 1.6.0"
    required_providers {
     azurerm = {
       source = "hashicorp/azurerm",
       version = "~> 4.0"
    }
    ,
     random = {
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
     project = "disaster-recovery",
     managed_by = "terraform"
  }
  ,
   var.tags)
}

resource "random_string" "suffix" {
   length = 5
   upper = false
   special = false
}

resource "azurerm_resource_group" "primary" {
   name = "rg-${var.prefix}-dr-primary"
   location = var.primary_location
   tags = merge(local.common_tags,
   {
     region = var.primary_location
  }
  )
}

resource "azurerm_resource_group" "secondary" {
   name = "rg-${var.prefix}-dr-secondary"
   location = var.secondary_location
   tags = merge(local.common_tags,
   {
     region = var.secondary_location
  }
  )
}

resource "azurerm_virtual_network" "primary" {
   name = "vnet-${var.prefix}-primary"
   location = azurerm_resource_group.primary.location
   resource_group_name = azurerm_resource_group.primary.name
   address_space = [var.primary_vnet_cidr]
   tags = local.common_tags
}

resource "azurerm_virtual_network" "secondary" {
   name = "vnet-${var.prefix}-secondary"
   location = azurerm_resource_group.secondary.location
   resource_group_name = azurerm_resource_group.secondary.name
   address_space = [var.secondary_vnet_cidr]
   tags = local.common_tags
}

resource "azurerm_subnet" "secondary" {
   name = "snet-recovery"
   resource_group_name = azurerm_resource_group.secondary.name
   virtual_network_name = azurerm_virtual_network.secondary.name
   address_prefixes = [var.secondary_subnet_cidr]
}

resource "azurerm_public_ip" "secondary" {
   name = "pip-${var.prefix}-dr-secondary"
   location = azurerm_resource_group.secondary.location
   resource_group_name = azurerm_resource_group.secondary.name
   allocation_method = "Static"
   sku = "Basic"
   tags = local.common_tags
}

resource "azurerm_recovery_services_vault" "this" {
   name = "rsv-${var.prefix}"
   location = azurerm_resource_group.secondary.location
   resource_group_name = azurerm_resource_group.secondary.name
   sku = "Standard"
   storage_mode_type = "GeoRedundant"
   soft_delete_enabled = true
   tags = local.common_tags
}

resource "azurerm_storage_account" "cache" {
   name = "st${replace(var.prefix, "-", "")}${random_string.suffix.result}dr"
   location = azurerm_resource_group.primary.location
   resource_group_name = azurerm_resource_group.primary.name
   account_tier = "Standard"
   account_replication_type = "GRS"
   min_tls_version = "TLS1_2"
   allow_nested_items_to_be_public = false
   tags = local.common_tags
}

resource "azurerm_site_recovery_fabric" "primary" {
   name = "primary-fabric"
   resource_group_name = azurerm_resource_group.secondary.name
   recovery_vault_name = azurerm_recovery_services_vault.this.name
   location = azurerm_resource_group.primary.location
}

resource "azurerm_site_recovery_fabric" "secondary" {
   name = "secondary-fabric"
   resource_group_name = azurerm_resource_group.secondary.name
   recovery_vault_name = azurerm_recovery_services_vault.this.name
   location = azurerm_resource_group.secondary.location
}

resource "azurerm_site_recovery_protection_container" "primary" {
   name = "primary-protection-container"
   resource_group_name = azurerm_resource_group.secondary.name
   recovery_vault_name = azurerm_recovery_services_vault.this.name
   recovery_fabric_name = azurerm_site_recovery_fabric.primary.name
}

resource "azurerm_site_recovery_protection_container" "secondary" {
   name = "secondary-protection-container"
   resource_group_name = azurerm_resource_group.secondary.name
   recovery_vault_name = azurerm_recovery_services_vault.this.name
   recovery_fabric_name = azurerm_site_recovery_fabric.secondary.name
}

resource "azurerm_site_recovery_replication_policy" "this" {
   name = "policy-${var.prefix}"
   resource_group_name = azurerm_resource_group.secondary.name
   recovery_vault_name = azurerm_recovery_services_vault.this.name
   recovery_point_retention_in_minutes = var.recovery_point_retention_in_minutes
   application_consistent_snapshot_frequency_in_minutes = var.application_consistent_snapshot_frequency_in_minutes
}

resource "azurerm_site_recovery_protection_container_mapping" "this" {
   name = "mapping-${var.prefix}"
   resource_group_name = azurerm_resource_group.secondary.name
   recovery_vault_name = azurerm_recovery_services_vault.this.name
   recovery_fabric_name = azurerm_site_recovery_fabric.primary.name
   recovery_source_protection_container_name = azurerm_site_recovery_protection_container.primary.name
   recovery_target_protection_container_id = azurerm_site_recovery_protection_container.secondary.id
   recovery_replication_policy_id = azurerm_site_recovery_replication_policy.this.id
}

resource "azurerm_site_recovery_network_mapping" "this" {
   name = "network-mapping-${var.prefix}"
   resource_group_name = azurerm_resource_group.secondary.name
   recovery_vault_name = azurerm_recovery_services_vault.this.name
   source_recovery_fabric_name = azurerm_site_recovery_fabric.primary.name
   target_recovery_fabric_name = azurerm_site_recovery_fabric.secondary.name
   source_network_id = azurerm_virtual_network.primary.id
   target_network_id = azurerm_virtual_network.secondary.id
}

resource "azurerm_site_recovery_replicated_vm" "this" {

    name = "replication-${var.prefix}"
    resource_group_name = azurerm_resource_group.secondary.name
    recovery_vault_name = azurerm_recovery_services_vault.this.name
    source_recovery_fabric_name = azurerm_site_recovery_fabric.primary.name
    source_vm_id = var.source_vm_id
    recovery_replication_policy_id = azurerm_site_recovery_replication_policy.this.id
    source_recovery_protection_container_name = azurerm_site_recovery_protection_container.primary.name
    target_resource_group_id = azurerm_resource_group.secondary.id
    target_recovery_fabric_id = azurerm_site_recovery_fabric.secondary.id
    target_recovery_protection_container_id = azurerm_site_recovery_protection_container.secondary.id
    target_zone = var.target_zone
    managed_disk {
     disk_id = var.source_os_disk_id
     staging_storage_account_id = azurerm_storage_account.cache.id
     target_resource_group_id = azurerm_resource_group.secondary.id
     target_disk_type = var.target_disk_type
     target_replica_disk_type = var.target_replica_disk_type
  }

    dynamic "managed_disk" {
     for_each = var.source_data_disk_ids content {
       disk_id = managed_disk.value
       staging_storage_account_id = azurerm_storage_account.cache.id
       target_resource_group_id = azurerm_resource_group.secondary.id
       target_disk_type = var.target_disk_type
       target_replica_disk_type = var.target_replica_disk_type
    }

  }

    network_interface {
     source_network_interface_id = var.source_network_interface_id
     target_subnet_name = azurerm_subnet.secondary.name
     recovery_public_ip_address_id = azurerm_public_ip.secondary.id
  }

    depends_on = [azurerm_site_recovery_protection_container_mapping.this,
   azurerm_site_recovery_network_mapping.this]

}

resource "azurerm_automation_account" "this" {
   name = "aa-${var.prefix}-dr"
   location = azurerm_resource_group.secondary.location
   resource_group_name = azurerm_resource_group.secondary.name
   sku_name = "Basic"
   tags = local.common_tags identity {
     type = "SystemAssigned"
  }

}

resource "azurerm_automation_runbook" "precheck" {
   name = "precheck-dr"
   location = azurerm_resource_group.secondary.location
   resource_group_name = azurerm_resource_group.secondary.name
   automation_account_name = azurerm_automation_account.this.name
   runbook_type = "PowerShell"
   log_verbose = true
   log_progress = true
   content = <<-PS1
param([string]$Direction = "PrimaryToRecovery")
Write-Output "Running DR pre-checks for $Direction"
PS1

}

resource "azurerm_automation_runbook" "postfailover" {
   name = "postfailover-dr"
   location = azurerm_resource_group.secondary.location
   resource_group_name = azurerm_resource_group.secondary.name
   automation_account_name = azurerm_automation_account.this.name
   runbook_type = "PowerShell"
   log_verbose = true
   log_progress = true
   content = <<-PS1
param([string]$Direction = "PrimaryToRecovery")
Write-Output "Running post-failover tasks for $Direction"
PS1

}

resource "azurerm_site_recovery_replication_recovery_plan" "this" {
   name = "plan-${var.prefix}"
   recovery_vault_id = azurerm_recovery_services_vault.this.id
   source_recovery_fabric_id = azurerm_site_recovery_fabric.primary.id
   target_recovery_fabric_id = azurerm_site_recovery_fabric.secondary.id shutdown_recovery_group {
     pre_action {
       name = "precheck"
       type = "AutomationRunbookActionDetails"
       fail_over_directions = ["PrimaryToRecovery"]
       fail_over_types = ["PlannedFailover",
       "UnplannedFailover",
       "TestFailover"] fabric_location = "Recovery"
       runbook_id = azurerm_automation_runbook.precheck.id
    }

  }
   failover_recovery_group {

  }
   boot_recovery_group {
     replicated_protected_items = [azurerm_site_recovery_replicated_vm.this.id] post_action {
       name = "postfailover"
       type = "AutomationRunbookActionDetails"
       fail_over_directions = ["PrimaryToRecovery"]
       fail_over_types = ["PlannedFailover",
       "UnplannedFailover",
       "TestFailover"] fabric_location = "Recovery"
       runbook_id = azurerm_automation_runbook.postfailover.id
    }

  }

}

resource "azurerm_traffic_manager_profile" "this" {
   name = "tm-${var.prefix}-dr"
   resource_group_name = azurerm_resource_group.primary.name
   traffic_routing_method = "Priority"
   tags = local.common_tags dns_config {
     relative_name = "tm-${var.prefix}-dr"
     ttl = 30
  }
   monitor_config {
     protocol = "TCP"
     port = 443
     path = "/"
  }

}

resource "azurerm_traffic_manager_azure_endpoint" "primary" {
   name = "primary-app"
   profile_id = azurerm_traffic_manager_profile.this.id
   target_resource_id = var.primary_public_ip_resource_id
   priority = 1
   weight = 100
}

resource "azurerm_traffic_manager_azure_endpoint" "secondary" {
   name = "secondary-app"
   profile_id = azurerm_traffic_manager_profile.this.id
   target_resource_id = var.secondary_public_ip_resource_id
   priority = 2
   weight = 100
}

resource "azurerm_mssql_server" "primary" {
   name = "sql-${var.prefix}-dr-pri-${random_string.suffix.result}"
   resource_group_name = azurerm_resource_group.primary.name
   location = azurerm_resource_group.primary.location
   version = "12.0"
   administrator_login = var.sql_administrator_login
   administrator_login_password = var.sql_administrator_password
   minimum_tls_version = "1.2"
   tags = local.common_tags
}

resource "azurerm_mssql_server" "secondary" {
   name = "sql-${var.prefix}-dr-sec-${random_string.suffix.result}"
   resource_group_name = azurerm_resource_group.secondary.name
   location = azurerm_resource_group.secondary.location
   version = "12.0"
   administrator_login = var.sql_administrator_login
   administrator_login_password = var.sql_administrator_password
   minimum_tls_version = "1.2"
   tags = local.common_tags
}

resource "azurerm_mssql_database" "primary" {
   name = var.sql_database_name
   server_id = azurerm_mssql_server.primary.id
   sku_name = var.sql_database_sku_name
   tags = local.common_tags
}

resource "azurerm_mssql_failover_group" "sql" {
   name = "fog-${var.prefix}-dr"
   server_id = azurerm_mssql_server.primary.id
   databases = [azurerm_mssql_database.primary.id]
   tags = local.common_tags partner_server {
     id = azurerm_mssql_server.secondary.id
  }
   read_write_endpoint_failover_policy {
     mode = "Automatic"
     grace_minutes = var.sql_failover_grace_minutes
  }

}
