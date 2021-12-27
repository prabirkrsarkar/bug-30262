terraform {
 required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "2.85.0"
    }
  }
 backend "azurerm" {
    resource_group_name  =  "terraform-state-rg"
    storage_account_name =  "xxxxxxxxxx"
    container_name       =  "xxxxxxxxxxxx"
    key                  =  "xxxxxxxxxxxxx"
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


# Deploy the Predict Stack

module "predict" {
  source = "./modules/predict"

  rg_info = {
  name     = "terraform-predict-rg-test"
  location = "East US2"
    }

tag = {
  Environment = "Development"
  Dept        = "Dept123"
  CostCenter  = "00123"
}

sku = "premium"

vnet_name = "vnet-databricks-dev-test"

vnet_address = ["10.179.0.0/16"]

nsg_name = "nsg-databricks-dev"

private_subnet_name = "private-snet-databricks-test"

public_subnet_name = "public-snet-databricks-test"

private_subnet_address = ["10.179.0.0/18"]

public_subnet_address = ["10.179.64.0/18"]

}


# Deploy the Analyze Stack

module "analyze" {
  source = "./modules/analyze"
  
rg_info = {
  name     = "terraform-analyze-rg-test"
  location = "East US2"
}

vnet_name = "vnet-analyze-test"

vnet_address = ["10.0.0.0/24"]

datasubnet_address = ["10.0.0.32/28"]

datalake = {
  name                     = "xxxxxxxx"
  account_tier             = "Standard"
  account_replication_type = "LRS"

}

datalake_filesystem = "xxxxxxx"

datalake_virtual_network_subnet_ids = [module.predict.databricks_private_subnet_id]

tag = {
  Environment = "Development"
  Dept        = "Dept123"
  CostCenter  = "00123"
  }
 depends_on = [
    module.predict,
  ]
}
