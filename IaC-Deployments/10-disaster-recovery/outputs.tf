output "recovery_vault_id" {
  description = "Resource ID of the Recovery Services Vault."
  value       = azurerm_recovery_services_vault.this.id
}

output "site_recovery_replication_id" {
  description = "Resource ID of the Site Recovery replicated VM configuration."
  value       = azurerm_site_recovery_replicated_vm.this.id
}

output "traffic_manager_fqdn" {
  description = "Traffic Manager DNS name used for DNS-based failover."
  value       = azurerm_traffic_manager_profile.this.fqdn
}

output "sql_failover_group_id" {
  description = "Resource ID of the SQL failover group used by the DR design."
  value       = azurerm_mssql_failover_group.sql.id
}
