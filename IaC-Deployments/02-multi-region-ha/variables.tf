variable "subscription_id" {
   description = "Azure subscription ID used by the provider."
   type = string
}

variable "prefix" {
   description = "Short prefix added to resource names."
   type = string
   default = "prodha"
}

variable "regions" {
   description = "Ordered list of Azure regions."
   type = list(string)
   default = ["eastus",
   "westus2"]
}

variable "vm_count_per_region" {
   description = "Number of VMs per region."
   type = number
   default = 2
}

variable "zones" {
   description = "Availability zones to cycle through per region."
   type = map(list(string))
   default = {
     eastus = ["1",
     "2"],
     westus2 = ["1",
     "2"]
  }

}

variable "region_cidrs" {
   description = "Per-region VNet and subnet CIDR configuration."
   type = map(object( {
     vnet = string,
     subnet = string
  }
  )) default = {
     eastus = {
       vnet = "10.20.0.0/16",
       subnet = "10.20.1.0/24"
    }
    ,
     westus2 = {
       vnet = "10.30.0.0/16",
       subnet = "10.30.1.0/24"
    }

  }

}

variable "vm_size" {
   description = "VM size used across all regions."
   type = string
   default = "Standard_D2s_v5"
}

variable "admin_username" {
   description = "Admin username for Linux VMs."
   type = string
   default = "azureadmin"
}

variable "ssh_public_key" {
   description = "SSH public key applied to all VMs."
   type = string
}

variable "management_source_cidr" {
   description = "CIDR allowed to SSH to regional VMs."
   type = string
   default = "0.0.0.0/0"
}

variable "tags" {
   description = "Additional tags merged with defaults."
   type = map(string)
   default = {
     owner = "cloud-platform"
  }

}
