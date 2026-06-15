variable "subscription_id" {
  description = "Azure subscription ID used by the provider."
  type        = string
}

variable "prefix" {
  description = "Short prefix used in management group and governance names."
  type        = string
  default     = "corp"
}

variable "display_name_prefix" {
  description = "Friendly display-name prefix used in the hierarchy."
  type        = string
  default     = "Corporate"
}

variable "root_management_group_id" {
  description = "Existing root or parent management group ID."
  type        = string
}

variable "location" {
  description = "Azure region used for governance resources."
  type        = string
  default     = "eastus"
}

variable "allowed_locations" {
  description = "Approved Azure regions enforced by policy."
  type        = list(string)
  default = ["eastus",
  "westus2"]
}

variable "required_tags" {
  description = "Tags that must exist on governed resources."
  type        = list(string)
  default = ["environment",
    "owner",
  "cost_center"]
}

variable "platform_owner_principal_id" {
  description = "Optional principal ID granted Owner at the platform management group."
  type        = string
  default     = ""
}

variable "workload_contributor_principal_id" {
  description = "Optional principal ID granted Contributor at the workloads management group."
  type        = string
  default     = ""
}

variable "sandbox_contributor_principal_id" {
  description = "Optional principal ID granted Contributor at the sandbox management group."
  type        = string
  default     = ""
}

variable "log_retention_in_days" {
  description = "Retention period for governance and activity logs."
  type        = number
  default     = 30
}

variable "monthly_budget_amount" {
  description = "Monthly subscription budget for governance monitoring."
  type        = number
  default     = 5000
}

variable "budget_start_date" {
  description = "Budget start date in RFC3339 format."
  type        = string
  default     = "2025-01-01T00:00:00Z"
}

variable "budget_contact_emails" {
  description = "Budget alert recipients."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Additional tags merged with defaults."
  type        = map(string)
  default = {
    owner = "cloud-governance"
  }

}
