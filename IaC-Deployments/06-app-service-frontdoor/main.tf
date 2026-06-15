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

locals {
   common_tags = merge( {
     environment = "production",
     project = "app-service-frontdoor",
     managed_by = "terraform"
  }
  ,
   var.tags) app_regions = {
     primary = var.primary_location,
     secondary = var.secondary_location
  }

}

resource "azurerm_resource_group" "this" {
   name = "rg-${var.prefix}-web"
   location = var.primary_location
   tags = local.common_tags
}

resource "azurerm_log_analytics_workspace" "this" {
   name = "law-${var.prefix}-web"
   location = azurerm_resource_group.this.location
   resource_group_name = azurerm_resource_group.this.name
   sku = "PerGB2018"
   retention_in_days = var.log_retention_in_days
   tags = local.common_tags
}

resource "azurerm_application_insights" "this" {
   for_each = local.app_regions
   name = "appi-${var.prefix}-${each.key}"
   location = each.value
   resource_group_name = azurerm_resource_group.this.name
   workspace_id = azurerm_log_analytics_workspace.this.id
   application_type = "web"
   tags = merge(local.common_tags,
   {
     region = each.value
  }
  )
}

resource "azurerm_service_plan" "this" {
   for_each = local.app_regions
   name = "asp-${var.prefix}-${each.key}"
   location = each.value
   resource_group_name = azurerm_resource_group.this.name
   os_type = "Linux"
   sku_name = var.app_service_sku
   tags = merge(local.common_tags,
   {
     region = each.value
  }
  )
}

resource "azurerm_linux_web_app" "this" {
   for_each = local.app_regions
   name = "app-${var.prefix}-${each.key}"
   location = each.value
   resource_group_name = azurerm_resource_group.this.name
   service_plan_id = azurerm_service_plan.this[each.key].id
   https_only = true
   tags = merge(local.common_tags,
   {
     region = each.value
  }
  ) identity {
     type = "SystemAssigned"
  }
   site_config {
     always_on = true application_stack {
       node_version = "18-lts"
    }
     health_check_path = "/"
  }
   app_settings = {
     APPINSIGHTS_INSTRUMENTATIONKEY = azurerm_application_insights.this[each.key].instrumentation_key
     APPLICATIONINSIGHTS_CONNECTION_STRING = azurerm_application_insights.this[each.key].connection_string
     WEBSITE_RUN_FROM_PACKAGE = "0"
     WEBSITES_ENABLE_APP_SERVICE_STORAGE = "false"
     SCM_DO_BUILD_DURING_DEPLOYMENT = "true"
  }

}

resource "azurerm_linux_web_app_slot" "staging" {
   for_each = local.app_regions
   name = "staging"
   app_service_id = azurerm_linux_web_app.this[each.key].id
   https_only = true
   tags = merge(local.common_tags,
   {
     region = each.value
  }
  ) site_config {
     always_on = true application_stack {
       node_version = "18-lts"
    }

  }
   app_settings = {
     APPINSIGHTS_INSTRUMENTATIONKEY = azurerm_application_insights.this[each.key].instrumentation_key
     APPLICATIONINSIGHTS_CONNECTION_STRING = azurerm_application_insights.this[each.key].connection_string
     SLOT_NAME = "staging"
  }

}

resource "azurerm_monitor_autoscale_setting" "this" {

    for_each = local.app_regions
    name = "autoscale-${var.prefix}-${each.key}"
    location = each.value
    resource_group_name = azurerm_resource_group.this.name
    target_resource_id = azurerm_service_plan.this[each.key].id
    tags = merge(local.common_tags,
   {
     region = each.value
  }
  )
    profile {

        name = "default"
        capacity {
       default = tostring(var.autoscale_default)
       minimum = tostring(var.autoscale_minimum)
       maximum = tostring(var.autoscale_maximum)
    }

        rule {
       metric_trigger {
         metric_name = "CpuPercentage"
         metric_resource_id = azurerm_service_plan.this[each.key].id
         time_grain = "PT1M"
         statistic = "Average"
         time_window = "PT10M"
         time_aggregation = "Average"
         operator = "GreaterThan"
         threshold = var.scale_out_cpu_threshold
      }
       scale_action {
         direction = "Increase"
         type = "ChangeCount"
         value = "1"
         cooldown = "PT5M"
      }

    }

        rule {
       metric_trigger {
         metric_name = "CpuPercentage"
         metric_resource_id = azurerm_service_plan.this[each.key].id
         time_grain = "PT1M"
         statistic = "Average"
         time_window = "PT10M"
         time_aggregation = "Average"
         operator = "LessThan"
         threshold = var.scale_in_cpu_threshold
      }
       scale_action {
         direction = "Decrease"
         type = "ChangeCount"
         value = "1"
         cooldown = "PT10M"
      }

    }


  }


}

resource "azurerm_cdn_frontdoor_profile" "this" {
   name = "afd-${var.prefix}"
   resource_group_name = azurerm_resource_group.this.name
   sku_name = "Standard_AzureFrontDoor"
   tags = local.common_tags
}

resource "azurerm_cdn_frontdoor_endpoint" "this" {
   name = "afd-${var.prefix}-ep"
   cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.this.id
   tags = local.common_tags
}

resource "azurerm_cdn_frontdoor_origin_group" "this" {
   name = "og-${var.prefix}"
   cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.this.id
   session_affinity_enabled = false load_balancing {
     additional_latency_in_milliseconds = 0
     sample_size = 4
     successful_samples_required = 3
  }
   health_probe {
     interval_in_seconds = 30
     path = "/"
     protocol = "Https"
     request_type = "GET"
  }

}

resource "azurerm_cdn_frontdoor_origin" "this" {
   for_each = local.app_regions
   name = "origin-${each.key}"
   cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.this.id
   host_name = azurerm_linux_web_app.this[each.key].default_hostname
   origin_host_header = azurerm_linux_web_app.this[each.key].default_hostname
   http_port = 80
   https_port = 443
   enabled = true
   certificate_name_check_enabled = true
   priority = each.key == "primary" ? 1 : 2
   weight = 1000
}

resource "azurerm_cdn_frontdoor_firewall_policy" "this" {
   name = "waf-${var.prefix}"
   resource_group_name = azurerm_resource_group.this.name
   sku_name = azurerm_cdn_frontdoor_profile.this.sku_name
   enabled = true
   mode = "Prevention"
   custom_block_response_status_code = 403
   custom_block_response_body = base64encode("Request blocked by Azure Front Door WAF")
   tags = local.common_tags managed_rule {
     type = "DefaultRuleSet"
     version = "1.0"
     action = "Block"
  }

}

resource "azurerm_dns_zone" "this" {
   count = var.enable_custom_domain ? 1 : 0
   name = var.dns_zone_name
   resource_group_name = azurerm_resource_group.this.name
   tags = local.common_tags
}

resource "azurerm_cdn_frontdoor_custom_domain" "this" {
   count = var.enable_custom_domain ? 1 : 0
   name = "fd-${var.prefix}-custom"
   cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.this.id
   dns_zone_id = azurerm_dns_zone.this[0].id
   host_name = "${var.custom_subdomain}.${var.dns_zone_name}" tls {
     certificate_type = "ManagedCertificate"
     minimum_version = "TLS12"
  }

}

resource "azurerm_dns_txt_record" "validation" {
   count = var.enable_custom_domain ? 1 : 0
   name = "_dnsauth.${var.custom_subdomain}"
   zone_name = azurerm_dns_zone.this[0].name
   resource_group_name = azurerm_resource_group.this.name
   ttl = 3600 record {
     value = azurerm_cdn_frontdoor_custom_domain.this[0].validation_token
  }

}

resource "azurerm_cdn_frontdoor_route" "this" {
   name = "route-${var.prefix}"
   cdn_frontdoor_endpoint_id = azurerm_cdn_frontdoor_endpoint.this.id
   cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.this.id
   cdn_frontdoor_origin_ids = [for _,
   origin in azurerm_cdn_frontdoor_origin.this : origin.id] enabled = true
   forwarding_protocol = "HttpsOnly"
   https_redirect_enabled = true
   patterns_to_match = ["/*"]
   supported_protocols = ["Http",
   "Https"] link_to_default_domain = true
   cdn_frontdoor_custom_domain_ids = var.enable_custom_domain ? [azurerm_cdn_frontdoor_custom_domain.this[0].id] : []
   depends_on = [azurerm_cdn_frontdoor_origin.this]
}

resource "azurerm_cdn_frontdoor_security_policy" "this" {
   name = "security-${var.prefix}"
   cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.this.id security_policies {
     firewall {
       cdn_frontdoor_firewall_policy_id = azurerm_cdn_frontdoor_firewall_policy.this.id association {
         domain {
           cdn_frontdoor_domain_id = azurerm_cdn_frontdoor_endpoint.this.id
        }
         patterns_to_match = ["/*"]
      }

    }

  }

}

resource "azurerm_cdn_frontdoor_custom_domain_association" "this" {
   count = var.enable_custom_domain ? 1 : 0
   cdn_frontdoor_custom_domain_id = azurerm_cdn_frontdoor_custom_domain.this[0].id
   cdn_frontdoor_route_ids = [azurerm_cdn_frontdoor_route.this.id]
}

resource "azurerm_dns_cname_record" "this" {
   count = var.enable_custom_domain ? 1 : 0
   name = var.custom_subdomain
   zone_name = azurerm_dns_zone.this[0].name
   resource_group_name = azurerm_resource_group.this.name
   ttl = 3600
   record = azurerm_cdn_frontdoor_endpoint.this.host_name
   depends_on = [azurerm_cdn_frontdoor_custom_domain_association.this]
}
