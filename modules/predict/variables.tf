
variable "sku" {
  type = string
  }


variable "rg_info" {
  type = object({
    name     = string
    location = string
  })
}

variable "tag" {
  type = object({
    Environment = string
    Dept        = string
    CostCenter  = string
  })
}

variable "vnet_name" {
  type = string
  }

variable "vnet_address" {
  type    = list(string)
  }

variable "nsg_name" {
  type = string
  }

variable "private_subnet_name" {
  type = string
}

variable "public_subnet_name" {
  type = string
  }

variable "private_subnet_address" {
  type    = list(string)
}

variable "public_subnet_address" {
  type    = list(string)
}
