variable "subscription_id" {
  description = "Azure subscription ID used by the provider."
  type        = string
}

variable "prefix" {
  description = "Short prefix used for data lake resource names."
  type        = string
  default     = "proddata"
}

variable "location" {
  description = "Region where storage and data movement resources are deployed."
  type        = string
  default     = "eastus"
}

variable "vnet_cidr" {
  description = "Address space for the private endpoint VNet."
  type        = string
  default     = "10.70.0.0/16"
}

variable "private_endpoint_subnet_cidr" {
  description = "Subnet CIDR reserved for storage private endpoints."
  type        = string
  default     = "10.70.1.0/24"
}

variable "soft_delete_retention_days" {
  description = "Blob and container soft-delete retention period in days."
  type        = number
  default     = 14
}

variable "log_retention_in_days" {
  description = "Retention period for storage diagnostics."
  type        = number
  default     = 30
}

variable "blob_data_contributor_principal_ids" {
  description = "Principal IDs that should receive Storage Blob Data Contributor."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Additional tags merged with defaults."
  type        = map(string)
  default = {
    owner = "data-platform"
  }

}
