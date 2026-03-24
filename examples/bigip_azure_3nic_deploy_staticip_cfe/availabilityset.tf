#
# Create an Availability Set for BIG-IP VMs
#
resource "azurerm_availability_set" "avset" {
  name                         = format("%s-avset-%s", var.prefix, random_id.id.hex)
  location                     = azurerm_resource_group.rg.location
  resource_group_name          = azurerm_resource_group.rg.name
  platform_fault_domain_count  = 2
  platform_update_domain_count = 2
  managed                      = true
  tags                         = var.common_tags
}
