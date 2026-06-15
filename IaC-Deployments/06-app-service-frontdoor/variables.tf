variable "subscription_id" {
  description = "Azure subscription ID used by the provider."
  type        = string
}

variable "prefix" {
  description = "Short prefix used for web resources."
  type        = string
  default     = "prodweb"
}

variable "primary_location" {
  description = "Primary region hosting the first App Service."
  type        = string
  default     = "eastus"
}

variable "secondary_location" {
  description = "Secondary region hosting the second App Service."
  type        = string
  default     = "westus2"
}

variable "app_service_sku" {
  description = "SKU for both App Service Plans."
  type        = string
  default     = "P1v3"
}

variable "autoscale_minimum" {
  description = "Minimum App Service Plan instance count."
  type        = number
  default     = 2
}

variable "autoscale_default" {
  description = "Default App Service Plan instance count."
  type        = number
  default     = 2
}

variable "autoscale_maximum" {
  description = "Maximum App Service Plan instance count."
  type        = number
  default     = 5
}

variable "scale_out_cpu_threshold" {
  description = "CPU threshold that triggers scale-out."
  type        = number
  default     = 70
}

variable "scale_in_cpu_threshold" {
  description = "CPU threshold that triggers scale-in."
  type        = number
  default     = 30
}

variable "enable_custom_domain" {
  description = "Whether to provision custom-domain DNS resources."
  type        = bool
  default     = false
}

variable "dns_zone_name" {
  description = "Azure DNS zone name when custom domain support is enabled."
  type        = string
  default     = "example.com"
}

variable "custom_subdomain" {
  description = "Subdomain published through Front Door."
  type        = string
  default     = "app"
}

variable "log_retention_in_days" {
  description = "Retention period for web telemetry."
  type        = number
  default     = 30
}

variable "tags" {
  description = "Additional tags merged with defaults."
  type        = map(string)
  default = {
    owner = "application-platform"
  }

}
