variable "subscription_id" {
   description = "Azure subscription ID used by the provider."
   type = string
}

variable "prefix" {
   description = "Short prefix used for monitoring resources."
   type = string
   default = "prodops"
}

variable "location" {
   description = "Region for the monitoring workspace and shared resources."
   type = string
   default = "eastus"
}

variable "log_retention_in_days" {
   description = "Retention period for logs kept in Log Analytics."
   type = number
   default = 30
}

variable "action_group_short_name" {
   description = "Short name used by Azure Monitor action groups."
   type = string
   default = "opsag"
}

variable "email_receivers" {
   description = "List of email recipients for the action group."
   type = list(object( {
     name = string,
     email_address = string
  }
  )) default = []
}

variable "sms_receivers" {
   description = "List of SMS recipients for the action group."
   type = list(object( {
     name = string,
     country_code = string,
     phone_number = string
  }
  )) default = []
}

variable "webhook_receivers" {
   description = "List of webhook endpoints for the action group."
   type = list(object( {
     name = string,
     service_uri = string
  }
  )) default = []
}

variable "vm_resource_ids" {
   description = "Virtual machine resource IDs monitored by metric alerts."
   type = list(string)
   default = []
}

variable "diagnostic_resource_ids" {
   description = "Resource IDs that should forward diagnostics to Log Analytics."
   type = list(string)
   default = []
}

variable "cpu_threshold" {
   description = "Average CPU percentage threshold for VM alerts."
   type = number
   default = 80
}

variable "memory_metric_namespace" {
   description = "Metric namespace used for VM memory alerting."
   type = string
   default = "Insights.VM/memory"
}

variable "memory_metric_name" {
   description = "Metric name used for VM memory alerting."
   type = string
   default = "Available Memory Bytes"
}

variable "memory_threshold" {
   description = "Threshold for the VM memory metric alert."
   type = number
   default = 2147483648
}

variable "disk_metric_namespace" {
   description = "Metric namespace used for VM disk alerting."
   type = string
   default = "Insights.VM/disk"
}

variable "disk_metric_name" {
   description = "Metric name used for VM disk alerting."
   type = string
   default = "OS Disk IOPS Consumed Percentage"
}

variable "disk_threshold" {
   description = "Threshold for the VM disk metric alert."
   type = number
   default = 80
}

variable "monthly_budget_amount" {
   description = "Monthly budget threshold for the monitoring resource group."
   type = number
   default = 500
}

variable "budget_start_date" {
   description = "Budget start date in RFC3339 format."
   type = string
   default = "2025-01-01T00:00:00Z"
}

variable "budget_contact_emails" {
   description = "Emails notified when the monitoring budget threshold is crossed."
   type = list(string)
   default = []
}

variable "tags" {
   description = "Additional tags merged with defaults."
   type = map(string)
   default = {
     owner = "operations-team"
  }

}
