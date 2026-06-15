output "storage_account_name" {
  description = "Name of the ADLS Gen2-enabled storage account."
  value       = azurerm_storage_account.this.name
}

output "data_factory_name" {
  description = "Name of the Azure Data Factory instance."
  value       = azurerm_data_factory.this.name
}

output "private_endpoint_ids" {
  description = "Private endpoint IDs for blob and dfs access."
  value = {
    blob = azurerm_private_endpoint.blob.id,
    dfs  = azurerm_private_endpoint.dfs.id
  }

}

output "container_names" {
  description = "Provisioned ADLS container names."
  value = [azurerm_storage_container.bronze.name,
    azurerm_storage_container.silver.name,
  azurerm_storage_container.gold.name]
}
