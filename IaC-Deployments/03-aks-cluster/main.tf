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

data "azurerm_client_config" "current" {

}

locals {
   common_tags = merge( {
     environment = "production",
     project = "aks-cluster",
     managed_by = "terraform"
  }
  ,
   var.tags)
}

resource "azurerm_resource_group" "this" {
   name = "rg-${var.prefix}-aks"
   location = var.location
   tags = local.common_tags
}

resource "azurerm_log_analytics_workspace" "this" {
   name = "law-${var.prefix}-aks"
   location = azurerm_resource_group.this.location
   resource_group_name = azurerm_resource_group.this.name
   sku = "PerGB2018"
   retention_in_days = var.log_retention_in_days
   tags = local.common_tags
}

resource "azurerm_container_registry" "this" {
   name = replace("${var.prefix}aksacr",
   "-",
   "") resource_group_name = azurerm_resource_group.this.name
   location = azurerm_resource_group.this.location
   sku = "Premium"
   admin_enabled = false
   public_network_access_enabled = true
   tags = local.common_tags
}

resource "azurerm_key_vault" "this" {
   name = replace("kv-${var.prefix}-aks",
   "-",
   "") location = azurerm_resource_group.this.location
   resource_group_name = azurerm_resource_group.this.name
   tenant_id = data.azurerm_client_config.current.tenant_id
   sku_name = "standard"
   purge_protection_enabled = true
   soft_delete_retention_days = 14
   enable_rbac_authorization = true
   tags = local.common_tags
}

resource "azurerm_virtual_network" "this" {
   name = "vnet-${var.prefix}-aks"
   location = azurerm_resource_group.this.location
   resource_group_name = azurerm_resource_group.this.name
   address_space = [var.vnet_cidr]
   tags = local.common_tags
}

resource "azurerm_subnet" "aks" {
   name = "snet-aks"
   resource_group_name = azurerm_resource_group.this.name
   virtual_network_name = azurerm_virtual_network.this.name
   address_prefixes = [var.aks_subnet_cidr]
}

resource "azurerm_subnet" "private_endpoints" {
   name = "snet-private-endpoints"
   resource_group_name = azurerm_resource_group.this.name
   virtual_network_name = azurerm_virtual_network.this.name
   address_prefixes = [var.private_endpoint_subnet_cidr]
}

resource "azurerm_kubernetes_cluster" "this" {

    name = "aks-${var.prefix}"
    location = azurerm_resource_group.this.location
    resource_group_name = azurerm_resource_group.this.name
    dns_prefix = "${var.prefix}-aks"
    kubernetes_version = var.kubernetes_version
    sku_tier = "Standard"
    private_cluster_enabled = var.private_cluster_enabled
    role_based_access_control_enabled = true
    azure_policy_enabled = true
    oidc_issuer_enabled = true
    workload_identity_enabled = true
    local_account_disabled = true
    tags = local.common_tags
    default_node_pool {
     name = "system"
     vm_size = var.system_node_pool_vm_size
     node_count = var.system_node_count
     zones = var.system_node_pool_zones
     max_pods = 50
     orchestrator_version = var.kubernetes_version
     only_critical_addons_enabled = true
     os_disk_size_gb = 128
     type = "VirtualMachineScaleSets"
     vnet_subnet_id = azurerm_subnet.aks.id
  }

    identity {
     type = "SystemAssigned"
  }

    network_profile {
     network_plugin = "azure"
     network_policy = "calico"
     load_balancer_sku = "standard"
     outbound_type = "loadBalancer"
     service_cidr = var.service_cidr
     dns_service_ip = var.dns_service_ip
  }

    azure_active_directory_role_based_access_control {
     managed = true
     azure_rbac_enabled = true
     admin_group_object_ids = var.admin_group_object_ids
  }

    oms_agent {
     log_analytics_workspace_id = azurerm_log_analytics_workspace.this.id
  }

    key_vault_secrets_provider {
     secret_rotation_enabled = true
     secret_rotation_interval = "2m"
  }


}

resource "azurerm_kubernetes_cluster_node_pool" "user" {
   name = "usernp"
   kubernetes_cluster_id = azurerm_kubernetes_cluster.this.id
   vm_size = var.user_node_pool_vm_size
   mode = "User"
   enable_auto_scaling = true
   min_count = var.user_node_pool_min_count
   max_count = var.user_node_pool_max_count
   max_pods = 50
   node_labels = var.user_node_labels
   orchestrator_version = var.kubernetes_version
   os_disk_size_gb = 128
   vnet_subnet_id = azurerm_subnet.aks.id
   zones = var.user_node_pool_zones
   tags = local.common_tags
}

resource "azurerm_role_assignment" "acr_pull" {
   scope = azurerm_container_registry.this.id
   role_definition_name = "AcrPull"
   principal_id = azurerm_kubernetes_cluster.this.kubelet_identity[0].object_id
}
