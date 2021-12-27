
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "2.85.0"
        }
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}

  subscription_id             = var.subscription_id
  client_id                   = var.client_id
  client_certificate_path     = var.client_certificate_path
  client_certificate_password = var.client_certificate_password
  tenant_id                   = var.tenant_id
}

resource "azurerm_resource_group" "optra_tfstate_rg" {
  name     = var.rg_state_info.name
  location = var.rg_state_info.location
}

resource "azurerm_management_lock" "optra_resource_group_lock" {
  name       = "resource-group-lock"
  scope      = azurerm_resource_group.optra_tfstate_rg.id
  lock_level = "CanNotDelete"
  notes      = "This Resource Group has a Delete Lock"
}

resource "azurerm_storage_account" "tfstate_storage" {
  name                     = var.tfstatestorage
  resource_group_name      = azurerm_resource_group.optra_tfstate_rg.name
  location                 = azurerm_resource_group.optra_tfstate_rg.location
  account_tier             = "Standard"
  account_replication_type = "GRS"
}

resource "azurerm_storage_container" "tfstate_container" {
  name                  = var.tfstatecontainer
  storage_account_name  = azurerm_storage_account.tfstate_storage.name
  container_access_type = "private"
}