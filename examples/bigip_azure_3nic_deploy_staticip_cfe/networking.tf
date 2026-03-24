module "network" {
  source              = "Azure/vnet/azurerm"
  version             = "3.0.0"
  vnet_name           = format("%s-vnet-%s", var.prefix, random_id.id.hex)
  resource_group_name = azurerm_resource_group.rg.name
  vnet_location       = var.location
  address_space       = [var.cidr]
  subnet_prefixes     = [var.mgmt_subnet_prefix, var.external_subnet_prefix, var.internal_subnet_prefix]
  subnet_names        = ["mgmt-subnet", "external-public-subnet", "internal-subnet"]

  tags = var.common_tags
}

data "azurerm_subnet" "mgmt" {
  name                 = "mgmt-subnet"
  virtual_network_name = module.network.vnet_name
  resource_group_name  = azurerm_resource_group.rg.name
  depends_on           = [module.network]
}

data "azurerm_subnet" "external-public" {
  name                 = "external-public-subnet"
  virtual_network_name = module.network.vnet_name
  resource_group_name  = azurerm_resource_group.rg.name
  depends_on           = [module.network]
}

data "azurerm_subnet" "internal" {
  name                 = "internal-subnet"
  virtual_network_name = module.network.vnet_name
  resource_group_name  = azurerm_resource_group.rg.name
  depends_on           = [module.network]
}

#
# Create the Network Security group Module to associate with BIGIP-Mgmt-Nic
#
module "mgmt-network-security-group" {
  source              = "Azure/network-security-group/azurerm"
  resource_group_name = azurerm_resource_group.rg.name
  security_group_name = format("%s-mgmt-nsg-%s", var.prefix, random_id.id.hex)
  tags = merge(var.common_tags, {
    role = "mgmt"
  })
}

#
# Create the Network Security group Module to associate with BIGIP-External-Nic
#
module "external-network-security-group-public" {
  source              = "Azure/network-security-group/azurerm"
  resource_group_name = azurerm_resource_group.rg.name
  security_group_name = format("%s-external-public-nsg-%s", var.prefix, random_id.id.hex)
  tags = merge(var.common_tags, {
    role = "external"
  })
}

resource "azurerm_network_security_rule" "mgmt_allow_https" {
  name                        = "Allow_Https"
  priority                    = 200
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  destination_address_prefix  = "*"
  source_address_prefixes     = var.AllowedIPs
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = format("%s-mgmt-nsg-%s", var.prefix, random_id.id.hex)
  depends_on                  = [module.mgmt-network-security-group]
}
resource "azurerm_network_security_rule" "mgmt_allow_ssh" {
  name                        = "Allow_ssh"
  priority                    = 202
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  destination_address_prefix  = "*"
  source_address_prefixes     = var.AllowedIPs
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = format("%s-mgmt-nsg-%s", var.prefix, random_id.id.hex)
  depends_on                  = [module.mgmt-network-security-group]
}

resource "azurerm_network_security_rule" "external_allow_https" {
  name                        = "Allow_Https"
  priority                    = 200
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  destination_address_prefix  = "*"
  source_address_prefixes     = var.AllowedIPs
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = format("%s-external-public-nsg-%s", var.prefix, random_id.id.hex)
  depends_on                  = [module.external-network-security-group-public]
}
resource "azurerm_network_security_rule" "external_allow_ssh" {
  name                        = "Allow_ssh"
  priority                    = 202
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  destination_address_prefix  = "*"
  source_address_prefixes     = var.AllowedIPs
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = format("%s-external-public-nsg-%s", var.prefix, random_id.id.hex)
  depends_on                  = [module.external-network-security-group-public]
}

#
# Create the Network Security group Module to associate with BIGIP-Internal-Nic
#
module "internal-network-security-group" {
  source                = "Azure/network-security-group/azurerm"
  resource_group_name   = azurerm_resource_group.rg.name
  security_group_name   = format("%s-internal-nsg-%s", var.prefix, random_id.id.hex)
  source_address_prefix = [var.internal_subnet_prefix]
  tags = merge(var.common_tags, {
    role = "internal"
  })
}
