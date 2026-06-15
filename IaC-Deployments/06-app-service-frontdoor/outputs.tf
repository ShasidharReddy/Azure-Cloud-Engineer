output "frontdoor_endpoint_hostname" {
  description = "Default hostname of the Front Door endpoint."
  value       = azurerm_cdn_frontdoor_endpoint.this.host_name
}

output "regional_web_apps" {
  description = "Map of regional App Service names and hostnames."
  value = {
    for key,
    app in azurerm_linux_web_app.this : key => {
      name     = app.name,
      hostname = app.default_hostname
    }

  }

}

output "custom_domain_hostname" {
  description = "Configured Front Door custom domain if enabled."
  value       = var.enable_custom_domain ? azurerm_cdn_frontdoor_custom_domain.this[0].host_name : null
}

output "frontdoor_profile_id" {
  description = "Resource ID of the Azure Front Door profile."
  value       = azurerm_cdn_frontdoor_profile.this.id
}
