output "primary_sql_server_fqdn" {
  description = "Primary SQL server FQDN."
  value       = azurerm_mssql_server.primary.fully_qualified_domain_name
}

output "secondary_sql_server_fqdn" {
  description = "Secondary SQL server FQDN."
  value       = azurerm_mssql_server.secondary.fully_qualified_domain_name
}

output "failover_group_id" {
  description = "Resource ID of the SQL failover group."
  value       = azurerm_mssql_failover_group.this.id
}

output "private_dns_zone_name" {
  description = "Private DNS zone used for SQL private endpoint resolution."
  value       = azurerm_private_dns_zone.sql.name
}
