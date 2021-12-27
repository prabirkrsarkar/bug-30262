
variable "rg_info" {
  type = object({
    name     = string
    location = string
  })
}

variable "vnet_name" {
  type = string
}

variable "vnet_address" {
  type = list(string)
}


variable "datasubnet_address" {
  type = list(string)
}

variable "datalake" {
  type = object({
    name                     = string
    account_tier             = string
    account_replication_type = string
  })
}

variable "datalake_filesystem" {
  type = string
}

variable "datalake_virtual_network_subnet_ids" {
	type = list(string)
   }

variable "tag" {
  type = object({
    Environment = string
    Dept        = string
    CostCenter  = string
  })
}
