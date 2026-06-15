variable "subscription_id" {
  description = "Azure subscription ID used by the provider."
  type        = string
}

variable "prefix" {
  description = "Short prefix used for the SQL HA deployment."
  type        = string
  default     = "prodsql"
}

variable "primary_location" {
  description = "Primary Azure region."
  type        = string
  default     = "eastus"
}

variable "secondary_location" {
  description = "Secondary Azure region."
  type        = string
  default     = "westus2"
}

variable "sql_administrator_login" {
  description = "Administrator login for both SQL logical servers."
  type        = string
  default     = "sqladminuser"
}

variable "sql_administrator_password" {
  description = "Administrator password for both SQL logical servers."
  type        = string
  sensitive   = true
}

variable "database_name" {
  description = "Name of the primary Azure SQL database."
  type        = string
  default     = "appdb-prod"
}

variable "database_sku_name" {
  description = "SKU for a standalone Azure SQL database."
  type        = string
  default     = "GP_S_Gen5_2"
}

variable "database_max_size_gb" {
  description = "Maximum database size in GiB."
  type        = number
  default     = 256
}

variable "enable_elastic_pool" {
  description = "Whether the primary database is created in an elastic pool."
  type        = bool
  default     = false
}

variable "elastic_pool_capacity" {
  description = "vCore capacity for the elastic pool."
  type        = number
  default     = 4
}

variable "elastic_pool_max_size_gb" {
  description = "Maximum storage size for the elastic pool."
  type        = number
  default     = 512
}

variable "enable_public_network_access" {
  description = "Whether public network access remains enabled on the SQL servers."
  type        = bool
  default     = false
}

variable "failover_grace_minutes" {
  description = "Grace period before automatic failover is triggered."
  type        = number
  default     = 60
}

variable "primary_vnet_cidr" {
  description = "VNet address space for the primary private endpoint network."
  type        = string
  default     = "10.60.0.0/16"
}

variable "secondary_vnet_cidr" {
  description = "VNet address space for the secondary private endpoint network."
  type        = string
  default     = "10.61.0.0/16"
}

variable "primary_private_endpoint_subnet_cidr" {
  description = "Subnet CIDR for the primary SQL private endpoint."
  type        = string
  default     = "10.60.1.0/24"
}

variable "secondary_private_endpoint_subnet_cidr" {
  description = "Subnet CIDR for the secondary SQL private endpoint."
  type        = string
  default     = "10.61.1.0/24"
}

variable "log_retention_in_days" {
  description = "Retention period for SQL diagnostics."
  type        = number
  default     = 30
}

variable "tags" {
  description = "Additional tags merged with defaults."
  type        = map(string)
  default = {
    owner = "database-team"
  }

}
