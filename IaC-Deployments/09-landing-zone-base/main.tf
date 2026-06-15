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

data "azurerm_subscription" "current" {

}

locals {
   common_tags = merge( {
     environment = "production",
     project = "landing-zone-base",
     managed_by = "terraform"
  }
  ,
   var.tags)
}

resource "azurerm_resource_group" "governance" {
   name = "rg-${var.prefix}-governance"
   location = var.location
   tags = local.common_tags
}

resource "azurerm_log_analytics_workspace" "this" {
   name = "law-${var.prefix}-governance"
   location = azurerm_resource_group.governance.location
   resource_group_name = azurerm_resource_group.governance.name
   sku = "PerGB2018"
   retention_in_days = var.log_retention_in_days
   tags = local.common_tags
}

resource "azurerm_management_group" "platform" {
   name = "${var.prefix}-platform"
   display_name = "${var.display_name_prefix} Platform"
   parent_management_group_id = var.root_management_group_id
}

resource "azurerm_management_group" "workloads" {
   name = "${var.prefix}-workloads"
   display_name = "${var.display_name_prefix} Workloads"
   parent_management_group_id = var.root_management_group_id
}

resource "azurerm_management_group" "sandbox" {
   name = "${var.prefix}-sandbox"
   display_name = "${var.display_name_prefix} Sandbox"
   parent_management_group_id = var.root_management_group_id
}

resource "azurerm_policy_definition" "allowed_locations" {
   name = "${var.prefix}-allowed-locations"
   policy_type = "Custom"
   mode = "Indexed"
   display_name = "Allowed deployment locations"
   management_group_id = azurerm_management_group.workloads.id
   description = "Restricts resource deployment to approved Azure regions."
   parameters = jsonencode( {
     allowedLocations = {
       type = "Array",
       metadata = {
         description = "Approved Azure regions"
      }

    }

  }
  ) policy_rule = jsonencode( {
     if = {
       not = {
         field = "location",
         in = "[parameters('allowedLocations')]"
      }

    }
    ,
     then = {
       effect = "deny"
    }

  }
  )
}

resource "azurerm_policy_definition" "required_tags" {
   name = "${var.prefix}-required-tags"
   policy_type = "Custom"
   mode = "All"
   display_name = "Required resource tags"
   management_group_id = azurerm_management_group.workloads.id
   description = "Requires key business tags on resources."
   policy_rule = jsonencode( {
     if = {
       anyOf = [for tag in var.required_tags : {
         field = "[concat('tags[', '${tag}', ']')]",
         exists = "false"
      }
      ]
    }
    ,
     then = {
       effect = "deny"
    }

  }
  )
}

resource "azurerm_policy_definition" "deny_public_ip" {
   name = "${var.prefix}-deny-public-ip"
   policy_type = "Custom"
   mode = "All"
   display_name = "Deny public IP resources"
   management_group_id = azurerm_management_group.platform.id
   description = "Prevents creation of standalone Azure Public IP resources."
   policy_rule = jsonencode( {
     if = {
       field = "type",
       equals = "Microsoft.Network/publicIPAddresses"
    }
    ,
     then = {
       effect = "deny"
    }

  }
  )
}

resource "azurerm_management_group_policy_assignment" "allowed_locations" {
   name = "allowed-locations"
   display_name = "Allowed deployment locations"
   management_group_id = azurerm_management_group.workloads.id
   policy_definition_id = azurerm_policy_definition.allowed_locations.id
   enforce = true
   parameters = jsonencode( {
     allowedLocations = {
       value = var.allowed_locations
    }

  }
  )
}

resource "azurerm_management_group_policy_assignment" "required_tags" {
   name = "required-tags"
   display_name = "Required tags policy"
   management_group_id = azurerm_management_group.workloads.id
   policy_definition_id = azurerm_policy_definition.required_tags.id
   enforce = true
}

resource "azurerm_management_group_policy_assignment" "deny_public_ip" {
   name = "deny-public-ip"
   display_name = "Deny public IP resources"
   management_group_id = azurerm_management_group.platform.id
   policy_definition_id = azurerm_policy_definition.deny_public_ip.id
   enforce = true
}

resource "azurerm_role_assignment" "platform_owner" {
   count = var.platform_owner_principal_id == "" ? 0 : 1
   scope = azurerm_management_group.platform.id
   role_definition_name = "Owner"
   principal_id = var.platform_owner_principal_id
}

resource "azurerm_role_assignment" "workload_contributor" {
   count = var.workload_contributor_principal_id == "" ? 0 : 1
   scope = azurerm_management_group.workloads.id
   role_definition_name = "Contributor"
   principal_id = var.workload_contributor_principal_id
}

resource "azurerm_role_assignment" "sandbox_contributor" {
   count = var.sandbox_contributor_principal_id == "" ? 0 : 1
   scope = azurerm_management_group.sandbox.id
   role_definition_name = "Contributor"
   principal_id = var.sandbox_contributor_principal_id
}

resource "azurerm_monitor_diagnostic_setting" "subscription_activity_logs" {
   name = "diag-activity-logs"
   target_resource_id = data.azurerm_subscription.current.id
   log_analytics_workspace_id = azurerm_log_analytics_workspace.this.id enabled_log {
     category = "Administrative"
  }
   enabled_log {
     category = "Policy"
  }
   enabled_log {
     category = "Security"
  }
   enabled_log {
     category = "ServiceHealth"
  }
   enabled_log {
     category = "Alert"
  }
   enabled_log {
     category = "Recommendation"
  }
   metric {
     category = "AllMetrics"
  }

}

resource "azurerm_consumption_budget_subscription" "this" {
   name = "budget-${var.prefix}-landing-zone"
   subscription_id = data.azurerm_subscription.current.id
   amount = var.monthly_budget_amount
   time_grain = "Monthly" time_period {
     start_date = var.budget_start_date
  }
   notification {
     enabled = true
     threshold = 80
     operator = "GreaterThan"
     threshold_type = "Actual"
     contact_emails = var.budget_contact_emails
  }

}
