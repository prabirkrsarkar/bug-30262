# Create Resource Group
resource "azurerm_resource_group" "optra_predict_rg" {
  name     = var.rg_info.name
  location = var.rg_info.location

  tags = {
    Environment = var.tag.Environment
    Dept        = var.tag.Dept
    CostCenter  = var.tag.CostCenter
  }
}

# Create a virtual network within the resource group
resource "azurerm_virtual_network" "optra_predict_vnet" {
  name                = var.vnet_name
  resource_group_name = azurerm_resource_group.optra_predict_rg.name
  location            = azurerm_resource_group.optra_predict_rg.location
  address_space       = var.vnet_address
}

resource "azurerm_subnet" "databricks_private_subnet" {
  name                                           = var.private_subnet_name
  resource_group_name                            = azurerm_resource_group.optra_predict_rg.name
  virtual_network_name                           = azurerm_virtual_network.optra_predict_vnet.name
  address_prefixes                               = var.private_subnet_address
  enforce_private_link_endpoint_network_policies = true

    delegation {
    name = "delegation"

    service_delegation {
      name    = "Microsoft.Databricks/workspaces"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action", "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action"]
      }
    }
  }
  
resource "azurerm_subnet" "databricks_public_subnet" {
  name                                           = var.public_subnet_name
  resource_group_name                            = azurerm_resource_group.optra_predict_rg.name
  virtual_network_name                           = azurerm_virtual_network.optra_predict_vnet.name
  address_prefixes                               = var.public_subnet_address
  enforce_private_link_endpoint_network_policies = true

    delegation {
    name = "delegation"

    service_delegation {
      name    = "Microsoft.Databricks/workspaces"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action", "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action"]
    }
  }
}

resource "azurerm_network_security_group" "optra_predict_databricks_nsg" {
  name                = var.nsg_name
  location            = azurerm_resource_group.optra_predict_rg.location
  resource_group_name = azurerm_resource_group.optra_predict_rg.name  

  security_rule {
    name                       = "Microsoft.Databricks-workspaces_UseOnly_databricks-worker-to-worker-inbound"
    description                = "Required for worker nodes communication within a cluster."
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "VirtualNetwork"
    access                     = "Allow"
    priority                   = 100
    direction                  = "Inbound"
  }

  security_rule {
    name                       = "Microsoft.Databricks-workspaces_UseOnly_databricks-worker-to-databricks-webapp"
    description                = "Required for workers communication with Databricks Webapp."
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "AzureDatabricks"
    access                     = "Allow"
    priority                   = 100
    direction                  = "Outbound"
  }

  security_rule {
    name                       = "Microsoft.Databricks-workspaces_UseOnly_databricks-worker-to-sql"
    description                = "Required for workers communication with Azure SQL services."
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3306"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "Sql"
    access                     = "Allow"
    priority                   = 101
    direction                  = "Outbound"

  }

  security_rule {
    name                       = "Microsoft.Databricks-workspaces_UseOnly_databricks-worker-to-storage"
    description                = "Required for workers communication with Azure Storage services."
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "Storage"
    access                     = "Allow"
    priority                   = 102
    direction                  = "Outbound"
  }

   security_rule {
    name                       = "Microsoft.Databricks-workspaces_UseOnly_databricks-worker-to-worker-outbound"
    description                = "Required for worker nodes communication within a cluster."
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "VirtualNetwork"
    access                     = "Allow"
    priority                   = 103
    direction                  = "Outbound"
  }

  security_rule {
    name                       = "Microsoft.Databricks-workspaces_UseOnly_databricks-worker-to-eventhub"
    description                = "Required for worker communication with Azure Eventhub services."
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "9093"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "EventHub"
    access                     = "Allow"
    priority                   = 104
    direction                  = "Outbound"
  }

  tags = {
    Environment = var.tag.Environment
    Dept        = var.tag.Dept
    CostCenter  = var.tag.CostCenter
  }
}

resource "azurerm_subnet_network_security_group_association" "optra_predict_databricks_public" {
  subnet_id                 = azurerm_subnet.databricks_public_subnet.id
  network_security_group_id = azurerm_network_security_group.optra_predict_databricks_nsg.id
}

resource "azurerm_subnet_network_security_group_association" "optra_predict_databricks_private" {
  subnet_id                 = azurerm_subnet.databricks_private_subnet.id
  network_security_group_id = azurerm_network_security_group.optra_predict_databricks_nsg.id
}

resource "azurerm_databricks_workspace" "optra_predict_databricks_workspace" {
  name                = "databricks-ws"
  resource_group_name = azurerm_resource_group.optra_predict_rg.name
  location            = azurerm_resource_group.optra_predict_rg.location
  sku                 = var.sku

    custom_parameters {
    virtual_network_id  = azurerm_virtual_network.optra_predict_vnet.id
    public_subnet_name  = var.public_subnet_name
    private_subnet_name = var.private_subnet_name
    public_subnet_network_security_group_association_id = azurerm_subnet_network_security_group_association.optra_predict_databricks_public.id
    private_subnet_network_security_group_association_id = azurerm_subnet_network_security_group_association.optra_predict_databricks_private.id
  } 

  tags = {
    Environment = var.tag.Environment
    Dept        = var.tag.Dept
    CostCenter  = var.tag.CostCenter
  }
}
