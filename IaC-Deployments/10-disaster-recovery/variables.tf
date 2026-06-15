variable "subscription_id" {
  description = "Azure subscription ID used by the provider."
  type        = string
}

variable "prefix" {
  description = "Short prefix used for disaster recovery resources."
  type        = string
  default     = "proddr"
}

variable "primary_location" {
  description = "Primary region where the protected workload runs."
  type        = string
  default     = "eastus"
}

variable "secondary_location" {
  description = "Recovery region used for failover."
  type        = string
  default     = "westus2"
}

variable "primary_vnet_cidr" {
  description = "Address space of the source/primary VNet representation."
  type        = string
  default     = "10.80.0.0/16"
}

variable "secondary_vnet_cidr" {
  description = "Address space of the recovery VNet."
  type        = string
  default     = "10.81.0.0/16"
}

variable "secondary_subnet_cidr" {
  description = "Recovery subnet CIDR used by failed-over VMs."
  type        = string
  default     = "10.81.1.0/24"
}

variable "source_vm_id" {
  description = "Resource ID of the existing source VM protected by Site Recovery."
  type        = string
}

variable "source_os_disk_id" {
  description = "Managed disk ID of the source VM OS disk."
  type        = string
}

variable "source_data_disk_ids" {
  description = "Managed disk IDs of any data disks that should be replicated."
  type        = list(string)
  default     = []
}

variable "source_network_interface_id" {
  description = "Resource ID of the source VM network interface used for recovery mapping."
  type        = string
}

variable "primary_public_ip_resource_id" {
  description = "Resource ID of the primary region public IP used by Traffic Manager."
  type        = string
}

variable "secondary_public_ip_resource_id" {
  description = "Resource ID of the secondary region public IP used by Traffic Manager."
  type        = string
}

variable "target_zone" {
  description = "Availability zone for the recovered VM in the target region."
  type        = string
  default     = "1"
}

variable "target_disk_type" {
  description = "Disk type applied to failed-over VM disks."
  type        = string
  default     = "Premium_LRS"
}

variable "target_replica_disk_type" {
  description = "Replica disk type used by Azure Site Recovery."
  type        = string
  default     = "Premium_LRS"
}

variable "recovery_point_retention_in_minutes" {
  description = "Recovery point retention window used by the Site Recovery policy."
  type        = number
  default     = 1440
}

variable "application_consistent_snapshot_frequency_in_minutes" {
  description = "Frequency of application-consistent snapshots for Site Recovery."
  type        = number
  default     = 240
}

variable "rpo_target_minutes" {
  description = "Documented target recovery point objective in minutes."
  type        = number
  default     = 15
}

variable "rto_target_minutes" {
  description = "Documented target recovery time objective in minutes."
  type        = number
  default     = 60
}

variable "sql_administrator_login" {
  description = "Administrator login for the DR SQL logical servers."
  type        = string
  default     = "sqladminuser"
}

variable "sql_administrator_password" {
  description = "Administrator password for the DR SQL logical servers."
  type        = string
  sensitive   = true
}

variable "sql_database_name" {
  description = "Name of the SQL database protected by the failover group."
  type        = string
  default     = "appdb-prod"
}

variable "sql_database_sku_name" {
  description = "SKU for the DR SQL database."
  type        = string
  default     = "GP_S_Gen5_2"
}

variable "sql_failover_grace_minutes" {
  description = "Grace period before automatic SQL failover occurs."
  type        = number
  default     = 60
}

variable "tags" {
  description = "Additional tags merged with defaults."
  type        = map(string)
  default = {
    owner = "business-continuity"
  }

}
