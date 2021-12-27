# Output definitions

output "databricks_private_subnet_id" {
     description = "Subnet id of Databricks private subnet"
     value = azurerm_subnet.databricks_private_subnet.id
   }
