# Create the Storage Account for CFE state
resource "azurerm_storage_account" "storage_account" {
  name                     = format("%sstorage%s", var.prefix, random_id.id.hex)
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags                     = var.common_tags
}
