output "traffic_manager_fqdn" {
  description = "Global Traffic Manager DNS name."
  value       = azurerm_traffic_manager_profile.global.fqdn
}

output "regional_load_balancer_public_ips" {
  description = "Regional load balancer IPs."
  value = {
    for region,
    ip in azurerm_public_ip.lb : region => ip.ip_address
  }

}

output "shared_storage_account_name" {
  description = "Shared geo-redundant storage account name."
  value       = azurerm_storage_account.shared.name
}

output "virtual_machine_ids" {
  description = "Map of VM instance keys to resource IDs."
  value = {
    for key,
    vm in azurerm_linux_virtual_machine.vm : key => vm.id
  }

}
