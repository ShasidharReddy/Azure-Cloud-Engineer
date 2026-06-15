output "public_ip" {
  description = "Public IP address assigned to the VM."
  value       = azurerm_public_ip.this.ip_address
}

output "private_ip" {
  description = "Private IP assigned to the NIC."
  value       = azurerm_network_interface.this.private_ip_address
}

output "vm_id" {
  description = "Resource ID of the Linux VM."
  value       = azurerm_linux_virtual_machine.this.id
}

output "resource_group_name" {
  description = "Resource group hosting the single VM deployment."
  value       = azurerm_resource_group.this.name
}
