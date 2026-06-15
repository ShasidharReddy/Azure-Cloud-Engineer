output "log_analytics_workspace_id" {
  description = "Resource ID of the shared Log Analytics workspace."
  value       = azurerm_log_analytics_workspace.this.id
}

output "application_insights_connection_string" {
  description = "Connection string for Application Insights."
  value       = azurerm_application_insights.this.connection_string
  sensitive   = true
}

output "action_group_id" {
  description = "Resource ID of the Azure Monitor action group."
  value       = azurerm_monitor_action_group.this.id
}

output "workbook_id" {
  description = "Resource ID of the Azure Workbook."
  value       = azurerm_application_insights_workbook.this.id
}
