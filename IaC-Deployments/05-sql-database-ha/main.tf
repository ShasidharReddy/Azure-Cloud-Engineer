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

data "azurerm_client_config" "current" {

}

locals {
   common_tags = merge( {
     environment = "production",
     project = "sql-database-ha",
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
   name = "rg-${var.prefix}-sql-primary"
   location = var.primary_location
   tags = merge(local.common_tags,
   {
     region = var.primary_location
  }
  )
}

resource "azurerm_resource_group" "secondary" {
   name = "rg-${var.prefix}-sql-secondary"
   location = var.secondary_location
   tags = merge(local.common_tags,
   {
     region = var.secondary_location
  }
  )
}

resource "azurerm_log_analytics_workspace" "this" {
   name = "law-${var.prefix}-sql"
   location = azurerm_resource_group.primary.location
   resource_group_name = azurerm_resource_group.primary.name
   sku = "PerGB2018"
   retention_in_days = var.log_retention_in_days
   tags = local.common_tags
}

resource "azurerm_key_vault" "this" {

    name = "kv${replace(var.prefix, "-", "")}${random_string.suffix.result}"
    location = azurerm_resource_group.primary.location
    resource_group_name = azurerm_resource_group.primary.name
    tenant_id = data.azurerm_client_config.current.tenant_id
    sku_name = "standard"
    purge_protection_enabled = true
    soft_delete_retention_days = 14
    enable_rbac_authorization = false
    tags = local.common_tags
    access_policy {
     tenant_id = data.azurerm_client_config.current.tenant_id
     object_id = data.azurerm_client_config.current.object_id
     key_permissions = ["Create",
    "Delete",
    "Get",
    "GetRotationPolicy",
    "List",
    "Purge",
    "Recover",
    "Update"]
  }


}

resource "azurerm_key_vault_key" "tde" {
   name = "sql-tde-key"
   key_vault_id = azurerm_key_vault.this.id
   key_type = "RSA"
   key_size = 2048
   key_opts = ["unwrapKey",
   "wrapKey"]
}

resource "azurerm_virtual_network" "primary" {
   name = "vnet-${var.prefix}-sql-primary"
   location = azurerm_resource_group.primary.location
   resource_group_name = azurerm_resource_group.primary.name
   address_space = [var.primary_vnet_cidr]
   tags = local.common_tags
}

resource "azurerm_virtual_network" "secondary" {
   name = "vnet-${var.prefix}-sql-secondary"
   location = azurerm_resource_group.secondary.location
   resource_group_name = azurerm_resource_group.secondary.name
   address_space = [var.secondary_vnet_cidr]
   tags = local.common_tags
}

resource "azurerm_subnet" "primary" {
   name = "snet-private-endpoint"
   resource_group_name = azurerm_resource_group.primary.name
   virtual_network_name = azurerm_virtual_network.primary.name
   address_prefixes = [var.primary_private_endpoint_subnet_cidr]
}

resource "azurerm_subnet" "secondary" {
   name = "snet-private-endpoint"
   resource_group_name = azurerm_resource_group.secondary.name
   virtual_network_name = azurerm_virtual_network.secondary.name
   address_prefixes = [var.secondary_private_endpoint_subnet_cidr]
}

resource "azurerm_private_dns_zone" "sql" {
   name = "privatelink.database.windows.net"
   resource_group_name = azurerm_resource_group.primary.name
   tags = local.common_tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "primary" {
   name = "sql-primary-link"
   resource_group_name = azurerm_resource_group.primary.name
   private_dns_zone_name = azurerm_private_dns_zone.sql.name
   virtual_network_id = azurerm_virtual_network.primary.id
}

resource "azurerm_private_dns_zone_virtual_network_link" "secondary" {
   name = "sql-secondary-link"
   resource_group_name = azurerm_resource_group.primary.name
   private_dns_zone_name = azurerm_private_dns_zone.sql.name
   virtual_network_id = azurerm_virtual_network.secondary.id
}

resource "azurerm_mssql_server" "primary" {
   name = "sql-${var.prefix}-pri-${random_string.suffix.result}"
   resource_group_name = azurerm_resource_group.primary.name
   location = azurerm_resource_group.primary.location
   version = "12.0"
   administrator_login = var.sql_administrator_login
   administrator_login_password = var.sql_administrator_password
   minimum_tls_version = "1.2"
   public_network_access_enabled = var.enable_public_network_access
   tags = merge(local.common_tags,
   {
     region = var.primary_location
  }
  ) identity {
     type = "SystemAssigned"
  }
   lifecycle {
     ignore_changes = [transparent_data_encryption_key_vault_key_id]
  }

}

resource "azurerm_mssql_server" "secondary" {
   name = "sql-${var.prefix}-sec-${random_string.suffix.result}"
   resource_group_name = azurerm_resource_group.secondary.name
   location = azurerm_resource_group.secondary.location
   version = "12.0"
   administrator_login = var.sql_administrator_login
   administrator_login_password = var.sql_administrator_password
   minimum_tls_version = "1.2"
   public_network_access_enabled = var.enable_public_network_access
   tags = merge(local.common_tags,
   {
     region = var.secondary_location
  }
  ) identity {
     type = "SystemAssigned"
  }
   lifecycle {
     ignore_changes = [transparent_data_encryption_key_vault_key_id]
  }

}

resource "azurerm_key_vault_access_policy" "primary_sql" {
   key_vault_id = azurerm_key_vault.this.id
   tenant_id = azurerm_mssql_server.primary.identity[0].tenant_id
   object_id = azurerm_mssql_server.primary.identity[0].principal_id
   key_permissions = ["Get",
   "WrapKey",
   "UnwrapKey"]
}

resource "azurerm_key_vault_access_policy" "secondary_sql" {
   key_vault_id = azurerm_key_vault.this.id
   tenant_id = azurerm_mssql_server.secondary.identity[0].tenant_id
   object_id = azurerm_mssql_server.secondary.identity[0].principal_id
   key_permissions = ["Get",
   "WrapKey",
   "UnwrapKey"]
}

resource "azurerm_mssql_server_transparent_data_encryption" "primary" {
   server_id = azurerm_mssql_server.primary.id
   key_vault_key_id = azurerm_key_vault_key.tde.id
   auto_rotation_enabled = true
   depends_on = [azurerm_key_vault_access_policy.primary_sql]
}

resource "azurerm_mssql_server_transparent_data_encryption" "secondary" {
   server_id = azurerm_mssql_server.secondary.id
   key_vault_key_id = azurerm_key_vault_key.tde.id
   auto_rotation_enabled = true
   depends_on = [azurerm_key_vault_access_policy.secondary_sql]
}

resource "azurerm_mssql_elasticpool" "primary" {
   count = var.enable_elastic_pool ? 1 : 0
   name = "ep-${var.prefix}-primary"
   server_id = azurerm_mssql_server.primary.id
   max_size_gb = var.elastic_pool_max_size_gb
   zone_redundant = true
   tags = local.common_tags sku {
     name = "GP_Gen5"
     tier = "GeneralPurpose"
     family = "Gen5"
     capacity = var.elastic_pool_capacity
  }
   per_database_settings {
     min_capacity = 0.25
     max_capacity = 2
  }

}

resource "azurerm_mssql_database" "primary" {
   name = var.database_name
   server_id = azurerm_mssql_server.primary.id
   sku_name = var.enable_elastic_pool ? null : var.database_sku_name
   elastic_pool_id = var.enable_elastic_pool ? azurerm_mssql_elasticpool.primary[0].id : null
   collation = "SQL_Latin1_General_CP1_CI_AS"
   max_size_gb = var.database_max_size_gb
   zone_redundant = true
   transparent_data_encryption_enabled = true
   tags = local.common_tags
}

resource "azurerm_mssql_failover_group" "this" {
   name = "fog-${var.prefix}"
   server_id = azurerm_mssql_server.primary.id
   databases = [azurerm_mssql_database.primary.id]
   tags = local.common_tags partner_server {
     id = azurerm_mssql_server.secondary.id
  }
   read_write_endpoint_failover_policy {
     mode = "Automatic"
     grace_minutes = var.failover_grace_minutes
  }

}

resource "azurerm_mssql_firewall_rule" "allow_azure_services_primary" {
   name = "AllowAzureServices"
   server_id = azurerm_mssql_server.primary.id
   start_ip_address = "0.0.0.0"
   end_ip_address = "0.0.0.0"
}

resource "azurerm_mssql_firewall_rule" "allow_azure_services_secondary" {
   name = "AllowAzureServices"
   server_id = azurerm_mssql_server.secondary.id
   start_ip_address = "0.0.0.0"
   end_ip_address = "0.0.0.0"
}

resource "azurerm_private_endpoint" "primary" {
   name = "pep-${var.prefix}-sql-primary"
   location = azurerm_resource_group.primary.location
   resource_group_name = azurerm_resource_group.primary.name
   subnet_id = azurerm_subnet.primary.id
   tags = local.common_tags private_service_connection {
     name = "psc-sql-primary"
     private_connection_resource_id = azurerm_mssql_server.primary.id
     subresource_names = ["sqlServer"]
     is_manual_connection = false
  }
   private_dns_zone_group {
     name = "default"
     private_dns_zone_ids = [azurerm_private_dns_zone.sql.id]
  }

}

resource "azurerm_private_endpoint" "secondary" {
   name = "pep-${var.prefix}-sql-secondary"
   location = azurerm_resource_group.secondary.location
   resource_group_name = azurerm_resource_group.secondary.name
   subnet_id = azurerm_subnet.secondary.id
   tags = local.common_tags private_service_connection {
     name = "psc-sql-secondary"
     private_connection_resource_id = azurerm_mssql_server.secondary.id
     subresource_names = ["sqlServer"]
     is_manual_connection = false
  }
   private_dns_zone_group {
     name = "default"
     private_dns_zone_ids = [azurerm_private_dns_zone.sql.id]
  }

}

resource "azurerm_monitor_diagnostic_setting" "primary_sql" {
   name = "diag-sql-primary"
   target_resource_id = azurerm_mssql_server.primary.id
   log_analytics_workspace_id = azurerm_log_analytics_workspace.this.id enabled_log {
     category_group = "allLogs"
  }
   metric {
     category = "AllMetrics"
  }

}

resource "azurerm_monitor_diagnostic_setting" "secondary_sql" {
   name = "diag-sql-secondary"
   target_resource_id = azurerm_mssql_server.secondary.id
   log_analytics_workspace_id = azurerm_log_analytics_workspace.this.id enabled_log {
     category_group = "allLogs"
  }
   metric {
     category = "AllMetrics"
  }

}
