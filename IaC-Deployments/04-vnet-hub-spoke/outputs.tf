output "hub_vnet_id" {
  description = "Resource ID of the hub VNet."
  value       = azurerm_virtual_network.hub.id
}

output "spoke_vnet_ids" {
  description = "Map of spoke VNet IDs."
  value = {
    for k,
    v in azurerm_virtual_network.spoke : k => v.id
  }

}

output "firewall_private_ip" {
  description = "Private IP of Azure Firewall."
  value       = azurerm_firewall.this.ip_configuration[0].private_ip_address
}

output "bastion_host_name" {
  description = "Name of the Azure Bastion host."
  value       = azurerm_bastion_host.this.name
}
