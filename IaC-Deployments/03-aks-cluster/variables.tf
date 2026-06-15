variable "subscription_id" {
  description = "Azure subscription ID used by the provider."
  type        = string
}

variable "prefix" {
  description = "Short prefix for AKS-related names."
  type        = string
  default     = "prodaks"
}

variable "location" {
  description = "Region where AKS is deployed."
  type        = string
  default     = "eastus"
}

variable "kubernetes_version" {
  description = "Pinned Kubernetes version."
  type        = string
  default     = "1.29.7"
}

variable "private_cluster_enabled" {
  description = "Whether the AKS API endpoint is private."
  type        = bool
  default     = false
}

variable "vnet_cidr" {
  description = "Address space for the AKS VNet."
  type        = string
  default     = "10.40.0.0/16"
}

variable "aks_subnet_cidr" {
  description = "Subnet CIDR delegated to AKS nodes."
  type        = string
  default     = "10.40.1.0/24"
}

variable "private_endpoint_subnet_cidr" {
  description = "Subnet CIDR reserved for private endpoints."
  type        = string
  default     = "10.40.2.0/24"
}

variable "service_cidr" {
  description = "Kubernetes service CIDR."
  type        = string
  default     = "10.41.0.0/16"
}

variable "dns_service_ip" {
  description = "Cluster DNS service IP."
  type        = string
  default     = "10.41.0.10"
}

variable "system_node_pool_vm_size" {
  description = "VM size for system nodes."
  type        = string
  default     = "Standard_D4s_v5"
}

variable "system_node_count" {
  description = "Desired node count for the system pool."
  type        = number
  default     = 3
}

variable "system_node_pool_zones" {
  description = "Availability zones used by the system pool."
  type        = list(string)
  default = ["1",
    "2",
  "3"]
}

variable "user_node_pool_vm_size" {
  description = "VM size for the user node pool."
  type        = string
  default     = "Standard_D4s_v5"
}

variable "user_node_pool_min_count" {
  description = "Minimum number of user nodes."
  type        = number
  default     = 2
}

variable "user_node_pool_max_count" {
  description = "Maximum number of user nodes."
  type        = number
  default     = 6
}

variable "user_node_pool_zones" {
  description = "Availability zones used by the user node pool."
  type        = list(string)
  default = ["1",
    "2",
  "3"]
}

variable "user_node_labels" {
  description = "Labels applied to user-pool nodes."
  type        = map(string)
  default = {
    workload = "general"
  }

}

variable "admin_group_object_ids" {
  description = "Entra group object IDs granted AKS admin access."
  type        = list(string)
  default     = []
}

variable "log_retention_in_days" {
  description = "Retention period for Container Insights data."
  type        = number
  default     = 30
}

variable "tags" {
  description = "Additional tags merged with defaults."
  type        = map(string)
  default = {
    owner = "platform-team"
  }

}
