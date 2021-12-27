variable "client_certificate_path" {
        type = string
}

variable "client_certificate_password" {
        type = string
}

variable "subscription_id" {
        type = string
}

variable "client_id" {
  type = string
}

variable "tenant_id" {
   type = string
}

variable "rg_state_info" {
  type = object({
    name    = string
    location = string
  })
}

variable "tfstatestorage" {
    type = string
}

variable "tfstatecontainer" {
    type = string
}