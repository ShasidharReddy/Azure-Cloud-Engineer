output "management_group_ids" {
  description = "Management group IDs created by the landing-zone base deployment."
  value = {
    platform  = azurerm_management_group.platform.id,
    workloads = azurerm_management_group.workloads.id,
    sandbox   = azurerm_management_group.sandbox.id
  }

}

output "log_analytics_workspace_id" {
  description = "Governance Log Analytics workspace resource ID."
  value       = azurerm_log_analytics_workspace.this.id
}

output "policy_definition_ids" {
  description = "Custom policy definition IDs."
  value = {
    allowed_locations = azurerm_policy_definition.allowed_locations.id,
    required_tags     = azurerm_policy_definition.required_tags.id,
    deny_public_ip    = azurerm_policy_definition.deny_public_ip.id
  }

}

output "governance_resource_group_name" {
  description = "Governance resource group name."
  value       = azurerm_resource_group.governance.name
}
