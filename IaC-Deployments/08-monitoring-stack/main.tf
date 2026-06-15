terraform {

    required_version = ">= 1.6.0"
    required_providers {
     azurerm = {
       source = "hashicorp/azurerm",
       version = "~> 4.0"
    }
    ,
     random = {
       source = "hashicorp/random",
       version = "~> 3.6"
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
     project = "monitoring-stack",
     managed_by = "terraform"
  }
  ,
   var.tags)
}

resource "random_uuid" "workbook" {

}

resource "azurerm_resource_group" "this" {
   name = "rg-${var.prefix}-monitoring"
   location = var.location
   tags = local.common_tags
}

resource "azurerm_log_analytics_workspace" "this" {
   name = "law-${var.prefix}-ops"
   location = azurerm_resource_group.this.location
   resource_group_name = azurerm_resource_group.this.name
   sku = "PerGB2018"
   retention_in_days = var.log_retention_in_days
   tags = local.common_tags
}

resource "azurerm_application_insights" "this" {
   name = "appi-${var.prefix}-ops"
   location = azurerm_resource_group.this.location
   resource_group_name = azurerm_resource_group.this.name
   application_type = "web"
   workspace_id = azurerm_log_analytics_workspace.this.id
   tags = local.common_tags
}

resource "azurerm_monitor_action_group" "this" {

    name = "ag-${var.prefix}-ops"
    resource_group_name = azurerm_resource_group.this.name
    short_name = var.action_group_short_name
    tags = local.common_tags
    dynamic "email_receiver" {
     for_each = var.email_receivers content {
       name = email_receiver.value.name
       email_address = email_receiver.value.email_address
    }

  }

    dynamic "sms_receiver" {
     for_each = var.sms_receivers content {
       name = sms_receiver.value.name
       country_code = sms_receiver.value.country_code
       phone_number = sms_receiver.value.phone_number
    }

  }

    dynamic "webhook_receiver" {
     for_each = var.webhook_receivers content {
       name = webhook_receiver.value.name
       service_uri = webhook_receiver.value.service_uri
    }

  }


}

resource "azurerm_monitor_metric_alert" "cpu" {
   count = length(var.vm_resource_ids) > 0 ? 1 : 0
   name = "alert-${var.prefix}-vm-cpu"
   resource_group_name = azurerm_resource_group.this.name
   scopes = var.vm_resource_ids
   description = "High VM CPU detected"
   severity = 2
   frequency = "PT1M"
   window_size = "PT5M"
   tags = local.common_tags criteria {
     metric_namespace = "Microsoft.Compute/virtualMachines"
     metric_name = "Percentage CPU"
     aggregation = "Average"
     operator = "GreaterThan"
     threshold = var.cpu_threshold
  }
   action {
     action_group_id = azurerm_monitor_action_group.this.id
  }

}

resource "azurerm_monitor_metric_alert" "memory" {
   count = length(var.vm_resource_ids) > 0 ? 1 : 0
   name = "alert-${var.prefix}-vm-memory"
   resource_group_name = azurerm_resource_group.this.name
   scopes = var.vm_resource_ids
   description = "Low VM memory detected"
   severity = 2
   frequency = "PT5M"
   window_size = "PT15M"
   tags = local.common_tags criteria {
     metric_namespace = var.memory_metric_namespace
     metric_name = var.memory_metric_name
     aggregation = "Average"
     operator = "LessThan"
     threshold = var.memory_threshold
  }
   action {
     action_group_id = azurerm_monitor_action_group.this.id
  }

}

resource "azurerm_monitor_metric_alert" "disk" {
   count = length(var.vm_resource_ids) > 0 ? 1 : 0
   name = "alert-${var.prefix}-vm-disk"
   resource_group_name = azurerm_resource_group.this.name
   scopes = var.vm_resource_ids
   description = "Disk capacity alert for monitored VMs"
   severity = 2
   frequency = "PT5M"
   window_size = "PT15M"
   tags = local.common_tags criteria {
     metric_namespace = var.disk_metric_namespace
     metric_name = var.disk_metric_name
     aggregation = "Average"
     operator = "GreaterThan"
     threshold = var.disk_threshold
  }
   action {
     action_group_id = azurerm_monitor_action_group.this.id
  }

}

resource "azurerm_monitor_scheduled_query_rules_alert_v2" "heartbeat" {
   name = "alert-${var.prefix}-heartbeat"
   resource_group_name = azurerm_resource_group.this.name
   location = azurerm_resource_group.this.location
   scopes = [azurerm_log_analytics_workspace.this.id]
   evaluation_frequency = "PT5M"
   window_duration = "PT10M"
   severity = 2
   description = "Detects missing VM heartbeats."
   enabled = true
   tags = local.common_tags criteria {
     query = "Heartbeat | summarize LastSeen=max(TimeGenerated) by Computer | where LastSeen < ago(10m)"
     time_aggregation_method = "Count"
     operator = "GreaterThan"
     threshold = 0
  }
   action {
     action_groups = [azurerm_monitor_action_group.this.id]
  }

}

resource "azurerm_monitor_scheduled_query_rules_alert_v2" "errors" {
   name = "alert-${var.prefix}-app-errors"
   resource_group_name = azurerm_resource_group.this.name
   location = azurerm_resource_group.this.location
   scopes = [azurerm_application_insights.this.id]
   evaluation_frequency = "PT5M"
   window_duration = "PT15M"
   severity = 3
   description = "Detects recent application exceptions."
   enabled = true
   tags = local.common_tags criteria {
     query = "exceptions | where timestamp > ago(15m) | summarize ErrorCount=count()"
     time_aggregation_method = "Count"
     operator = "GreaterThan"
     threshold = 0
  }
   action {
     action_groups = [azurerm_monitor_action_group.this.id]
  }

}

resource "azurerm_monitor_diagnostic_setting" "resources" {
   for_each = toset(var.diagnostic_resource_ids)
   name = "diag-${replace(basename(each.value), ".", "-")}"
   target_resource_id = each.value
   log_analytics_workspace_id = azurerm_log_analytics_workspace.this.id enabled_log {
     category_group = "allLogs"
  }
   metric {
     category = "AllMetrics"
  }

}

resource "azurerm_application_insights_workbook" "this" {
   name = random_uuid.workbook.result
   resource_group_name = azurerm_resource_group.this.name
   location = azurerm_resource_group.this.location
   display_name = "${var.prefix} Operations Workbook"
   source_id = azurerm_application_insights.this.id
   data_json = jsonencode( {
     version = "Notebook/1.0",
     items = [ {
       type = 1,
       content = {
         json = "## Operations Summary\nThis workbook centralizes Application Insights and Log Analytics views for the monitoring stack."
      }

    }
    ],
     isLocked = false
  }
  ) tags = local.common_tags
}

resource "azurerm_consumption_budget_resource_group" "this" {
   name = "budget-${var.prefix}-monitoring"
   resource_group_id = azurerm_resource_group.this.id
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
     contact_groups = [azurerm_monitor_action_group.this.id]
  }

}
