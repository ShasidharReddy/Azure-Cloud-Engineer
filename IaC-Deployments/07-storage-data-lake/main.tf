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
     project = "storage-data-lake",
     managed_by = "terraform"
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
   name = "rg-${var.prefix}-data"
   location = var.location
   tags = local.common_tags
}

resource "azurerm_log_analytics_workspace" "this" {
   name = "law-${var.prefix}-data"
   location = azurerm_resource_group.this.location
   resource_group_name = azurerm_resource_group.this.name
   sku = "PerGB2018"
   retention_in_days = var.log_retention_in_days
   tags = local.common_tags
}

resource "azurerm_virtual_network" "this" {
   name = "vnet-${var.prefix}-data"
   location = azurerm_resource_group.this.location
   resource_group_name = azurerm_resource_group.this.name
   address_space = [var.vnet_cidr]
   tags = local.common_tags
}

resource "azurerm_subnet" "private_endpoints" {
   name = "snet-private-endpoints"
   resource_group_name = azurerm_resource_group.this.name
   virtual_network_name = azurerm_virtual_network.this.name
   address_prefixes = [var.private_endpoint_subnet_cidr]
}

resource "azurerm_storage_account" "this" {

    name = "st${replace(var.prefix, "-", "")}${random_string.suffix.result}"
    resource_group_name = azurerm_resource_group.this.name
    location = azurerm_resource_group.this.location
    account_tier = "Standard"
    account_replication_type = "ZRS"
    account_kind = "StorageV2"
    min_tls_version = "TLS1_2"
    allow_nested_items_to_be_public = false
    is_hns_enabled = true
    public_network_access_enabled = false
    tags = local.common_tags
    blob_properties {
     versioning_enabled = true delete_retention_policy {
       days = var.soft_delete_retention_days
    }
     container_delete_retention_policy {
       days = var.soft_delete_retention_days
    }

  }


}

resource "azurerm_storage_container" "bronze" {
   name = "bronze"
   storage_account_id = azurerm_storage_account.this.id
   container_access_type = "private"
}

resource "azurerm_storage_container" "silver" {
   name = "silver"
   storage_account_id = azurerm_storage_account.this.id
   container_access_type = "private"
}

resource "azurerm_storage_container" "gold" {
   name = "gold"
   storage_account_id = azurerm_storage_account.this.id
   container_access_type = "private"
}

resource "azurerm_storage_management_policy" "this" {
   storage_account_id = azurerm_storage_account.this.id rule {
     name = "tier-and-archive"
     enabled = true filters {
       blob_types = ["blockBlob"]
       prefix_match = ["bronze/",
       "silver/"]
    }
     actions {
       base_blob {
         tier_to_cool_after_days_since_modification_greater_than = 30
         tier_to_archive_after_days_since_modification_greater_than = 90
         delete_after_days_since_modification_greater_than = 365
      }

    }

  }

}

resource "azurerm_private_dns_zone" "blob" {
   name = "privatelink.blob.core.windows.net"
   resource_group_name = azurerm_resource_group.this.name
   tags = local.common_tags
}

resource "azurerm_private_dns_zone" "dfs" {
   name = "privatelink.dfs.core.windows.net"
   resource_group_name = azurerm_resource_group.this.name
   tags = local.common_tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "blob" {
   name = "blob-link"
   resource_group_name = azurerm_resource_group.this.name
   private_dns_zone_name = azurerm_private_dns_zone.blob.name
   virtual_network_id = azurerm_virtual_network.this.id
}

resource "azurerm_private_dns_zone_virtual_network_link" "dfs" {
   name = "dfs-link"
   resource_group_name = azurerm_resource_group.this.name
   private_dns_zone_name = azurerm_private_dns_zone.dfs.name
   virtual_network_id = azurerm_virtual_network.this.id
}

resource "azurerm_private_endpoint" "blob" {
   name = "pep-${var.prefix}-blob"
   location = azurerm_resource_group.this.location
   resource_group_name = azurerm_resource_group.this.name
   subnet_id = azurerm_subnet.private_endpoints.id
   tags = local.common_tags private_service_connection {
     name = "psc-blob"
     private_connection_resource_id = azurerm_storage_account.this.id
     subresource_names = ["blob"]
     is_manual_connection = false
  }
   private_dns_zone_group {
     name = "default"
     private_dns_zone_ids = [azurerm_private_dns_zone.blob.id]
  }

}

resource "azurerm_private_endpoint" "dfs" {
   name = "pep-${var.prefix}-dfs"
   location = azurerm_resource_group.this.location
   resource_group_name = azurerm_resource_group.this.name
   subnet_id = azurerm_subnet.private_endpoints.id
   tags = local.common_tags private_service_connection {
     name = "psc-dfs"
     private_connection_resource_id = azurerm_storage_account.this.id
     subresource_names = ["dfs"]
     is_manual_connection = false
  }
   private_dns_zone_group {
     name = "default"
     private_dns_zone_ids = [azurerm_private_dns_zone.dfs.id]
  }

}

resource "azurerm_data_factory" "this" {
   name = "adf-${var.prefix}"
   location = azurerm_resource_group.this.location
   resource_group_name = azurerm_resource_group.this.name identity {
     type = "SystemAssigned"
  }
   tags = local.common_tags
}

resource "azurerm_data_factory_linked_service_azure_blob_storage" "lake" {
   name = "ls-datalake"
   data_factory_id = azurerm_data_factory.this.id
   connection_string = azurerm_storage_account.this.primary_connection_string
}

resource "azurerm_data_factory_dataset_binary" "bronze" {
   name = "ds-bronze"
   data_factory_id = azurerm_data_factory.this.id
   linked_service_name = azurerm_data_factory_linked_service_azure_blob_storage.lake.name azure_blob_storage_location {
     container = azurerm_storage_container.bronze.name
     path = ""
     filename = ""
  }

}

resource "azurerm_data_factory_dataset_binary" "silver" {
   name = "ds-silver"
   data_factory_id = azurerm_data_factory.this.id
   linked_service_name = azurerm_data_factory_linked_service_azure_blob_storage.lake.name azure_blob_storage_location {
     container = azurerm_storage_container.silver.name
     path = ""
     filename = ""
  }

}

resource "azurerm_data_factory_pipeline" "ingest" {
   name = "copy-bronze-to-silver"
   data_factory_id = azurerm_data_factory.this.id
   activities_json = jsonencode([ {
     name = "CopyBronzeToSilver",
     type = "Copy",
     inputs = [ {
       referenceName = azurerm_data_factory_dataset_binary.bronze.name,
       type = "DatasetReference"
    }
    ],
     outputs = [ {
       referenceName = azurerm_data_factory_dataset_binary.silver.name,
       type = "DatasetReference"
    }
    ],
     typeProperties = {
       source = {
         type = "BinarySource"
      }
      ,
       sink = {
         type = "BinarySink"
      }

    }

  }
  ])
}

resource "azurerm_role_assignment" "blob_contributor" {
   for_each = toset(var.blob_data_contributor_principal_ids)
   scope = azurerm_storage_account.this.id
   role_definition_name = "Storage Blob Data Contributor"
   principal_id = each.value
}

resource "azurerm_monitor_diagnostic_setting" "storage" {
   name = "diag-storage"
   target_resource_id = azurerm_storage_account.this.id
   log_analytics_workspace_id = azurerm_log_analytics_workspace.this.id enabled_log {
     category_group = "allLogs"
  }
   metric {
     category = "AllMetrics"
  }

}
