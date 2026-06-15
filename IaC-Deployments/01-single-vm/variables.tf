variable "subscription_id" {
  description = "Azure subscription ID used by the provider."
  type        = string
}

variable "prefix" {
  description = "Short naming prefix."
  type        = string
  default     = "prod"
}

variable "vm_name" {
  description = "Name of the Linux VM."
  type        = string
  default     = "vm-prod-01"
}

variable "location" {
  description = "Azure region for the deployment."
  type        = string
  default     = "eastus"
}

variable "vm_size" {
  description = "Azure VM size."
  type        = string
  default     = "Standard_D2s_v5"
}

variable "admin_username" {
  description = "Linux administrator username."
  type        = string
  default     = "azureadmin"
}

variable "ssh_public_key" {
  description = "SSH public key content."
  type        = string
}

variable "vnet_cidr" {
  description = "CIDR for the VNet."
  type        = string
  default     = "10.10.0.0/16"
}

variable "subnet_cidr" {
  description = "CIDR for the workload subnet."
  type        = string
  default     = "10.10.1.0/24"
}

variable "data_disk_size_gb" {
  description = "Managed data disk size in GiB."
  type        = number
  default     = 128
}

variable "tags" {
  description = "Additional tags merged with defaults."
  type        = map(string)
  default = {
    owner = "cloud-platform"
  }

}
