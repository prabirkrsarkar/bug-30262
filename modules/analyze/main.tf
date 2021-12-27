
# Create Resource Group
resource "azurerm_resource_group" "optra_rg" {
  name     = var.rg_info.name
  location = var.rg_info.location

  tags = {
    Environment = var.tag.Environment
    Dept = var.tag.Dept
    CostCenter = var.tag.CostCenter
  }
}

# Create a virtual network within the resource group
resource "azurerm_virtual_network" "optra_vnet" {
  name                = var.vnet_name
  resource_group_name = azurerm_resource_group.optra_rg.name
  location            = azurerm_resource_group.optra_rg.location
  address_space       = var.vnet_address
}

# Create Data Subnet
resource "azurerm_subnet" "optra_data_subnet" {
  name                                           = "DataSubnet"
  resource_group_name                            = azurerm_resource_group.optra_rg.name
  virtual_network_name                           = azurerm_virtual_network.optra_vnet.name
  address_prefixes                               = var.datasubnet_address
  enforce_private_link_endpoint_network_policies = true
  service_endpoints                              = ["Microsoft.KeyVault"]

  /*delegation {
    name = "delegation"

    service_delegation {
      name    = "Microsoft.ContainerInstance/containerGroups"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action", "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action"]
    }
  }*/
}

data "azurerm_client_config" "current" {}

# Create DataLake
resource "azurerm_storage_account" "optra" {
  name                     = var.datalake.name
  resource_group_name      = azurerm_resource_group.optra_rg.name
  location                 = azurerm_resource_group.optra_rg.location
  account_tier             = var.datalake.account_tier
  account_replication_type = var.datalake.account_replication_type
  is_hns_enabled           = true
  access_tier              = "Hot"
  min_tls_version          = "TLS1_2"
  
  network_rules {
    bypass         = ["AzureServices"]
    default_action = "Deny"
  # ip_rules                   = ["100.0.0.1"]
    virtual_network_subnet_ids = var.datalake_virtual_network_subnet_ids
  }
  
  enable_https_traffic_only = true
  
  account_kind              = "StorageV2"

  tags = {
    Environment = var.tag.Environment
    Dept        = var.tag.Dept
    CostCenter  = var.tag.CostCenter
  }

}

# Create Storage Account File System
resource "azurerm_storage_data_lake_gen2_filesystem" "optra" {
  name               = var.datalake_filesystem
  storage_account_id = azurerm_storage_account.optra.id
}


# Create Private DNS Zone for DataLake
resource "azurerm_private_dns_zone" "optra_datalake_dnszone" {
  name                = "privatelink.dfs.core.windows.net"
  resource_group_name = azurerm_resource_group.optra_rg.name
}

# Create Private DNS Zone Network Link for DataLake
resource "azurerm_private_dns_zone_virtual_network_link" "optra_datalake_networklink" {
  name                  = "optra-datalake"
  resource_group_name   = azurerm_resource_group.optra_rg.name
  private_dns_zone_name = azurerm_private_dns_zone.optra_datalake_dnszone.name
  virtual_network_id    = azurerm_virtual_network.optra_vnet.id
}

# Create Private End Point for DataLake
resource "azurerm_private_endpoint" "optra_datalake_pvendpoint" {
  name                = "datalake-priv-endpoint"
  location            = azurerm_resource_group.optra_rg.location
  resource_group_name = azurerm_resource_group.optra_rg.name
  subnet_id           = azurerm_subnet.optra_data_subnet.id

  private_service_connection {
    name                           = "datalake-connection"
    is_manual_connection           = false
    private_connection_resource_id = azurerm_storage_account.optra.id
    subresource_names              = ["dfs"]
  }
}
