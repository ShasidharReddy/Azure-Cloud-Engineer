variable "subscription_id" {
   description = "Azure subscription ID used by the provider."
   type = string
}

variable "prefix" {
   description = "Short prefix used for networking resources."
   type = string
   default = "prodnet"
}

variable "location" {
   description = "Azure region used for the hub and spokes."
   type = string
   default = "eastus"
}

variable "hub_vnet_cidr" {
   description = "Address space for the hub VNet."
   type = string
   default = "10.50.0.0/16"
}

variable "hub_subnets" {
   description = "CIDRs used by hub service subnets."
   type = object( {
     firewall = string,
     bastion = string,
     gateway = string,
     management = string
  }
  ) default = {
     firewall = "10.50.0.0/24",
     bastion = "10.50.1.0/24",
     gateway = "10.50.2.0/24",
     management = "10.50.3.0/24"
  }

}

variable "spoke_vnets" {
   description = "Map of spoke VNets and workload subnet CIDRs."
   type = map(object( {
     address_space = list(string),
     workload_subnet_cidr = string
  }
  )) default = {
     apps = {
       address_space = ["10.51.0.0/16"],
       workload_subnet_cidr = "10.51.1.0/24"
    }
    ,
     data = {
       address_space = ["10.52.0.0/16"],
       workload_subnet_cidr = "10.52.1.0/24"
    }
    ,
     shared = {
       address_space = ["10.53.0.0/16"],
       workload_subnet_cidr = "10.53.1.0/24"
    }

  }

}

variable "firewall_sku_tier" {
   description = "Azure Firewall SKU tier."
   type = string
   default = "Standard"
}

variable "vpn_gateway_sku" {
   description = "SKU used for the hub VPN Gateway."
   type = string
   default = "VpnGw1"
}

variable "log_retention_in_days" {
   description = "Retention period for network diagnostics."
   type = number
   default = 30
}

variable "tags" {
   description = "Additional tags merged with defaults."
   type = map(string)
   default = {
     owner = "network-team"
  }

}
