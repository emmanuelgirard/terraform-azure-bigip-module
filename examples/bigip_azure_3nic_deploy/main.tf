provider "azurerm" {
  //  version = "~>2.0"
    features {
        virtual_machine {
          skip_shutdown_and_force_delete = true
          delete_os_disk_on_deletion = true
        }
    }
}

#
# Create a random id
#
resource "random_id" "id" {
  byte_length = 2
}

#
# Create a resource group
#
resource "azurerm_resource_group" "rg" {
  name     = format("%s-rg-%s", var.prefix, random_id.id.hex)
  location = var.location
}

resource "azurerm_ssh_public_key" "f5_key" {
  name                = format("%s-pubkey-%s", var.prefix, random_id.id.hex)
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  public_key          = file("~/.ssh/id_rsa.pub")
}

# #
# #Create N-nic bigip
# #
# module "bigip" {
#   count                       = var.instance_count
#   source                      = "../../"
#   prefix                      = format("%s-3nic", var.prefix)
#   resource_group_name         = azurerm_resource_group.rg.name
#   f5_ssh_publickey            = azurerm_ssh_public_key.f5_key.public_key
#   mgmt_subnet_ids             = [{ "subnet_id" = data.azurerm_subnet.mgmt.id, "public_ip" = true, "private_ip_primary" = "10.2.1.5" }]
#   mgmt_securitygroup_ids      = [module.mgmt-network-security-group.network_security_group_id]
#   external_subnet_ids         = [{ "subnet_id" = data.azurerm_subnet.external-public.id, "public_ip" = true, "private_ip_primary" = "", "private_ip_secondary" = "" }]
#   external_securitygroup_ids  = [module.external-network-security-group-public.network_security_group_id]
#   internal_subnet_ids         = [{ "subnet_id" = data.azurerm_subnet.internal.id, "public_ip" = false, "private_ip_primary" = "" }]
#   internal_securitygroup_ids  = [module.internal-network-security-group.network_security_group_id]
#   availability_zone           = var.availability_zone
#   availabilityZones_public_ip = var.availabilityZones_public_ip
# }

#
#Create N-nic bigip
#
module "bigip" {
  count                       = 2
  source                      = "../../"
  prefix                      = format("%s-3nic-%s", var.prefix, count.index)
  f5_password                 = var.f5_password
  resource_group_name         = azurerm_resource_group.rg.name
  f5_ssh_publickey            = azurerm_ssh_public_key.f5_key.public_key
  mgmt_subnet_ids             = [{ "subnet_id" = data.azurerm_subnet.mgmt.id, "public_ip" = true, "private_ip_primary" = "" }]
  mgmt_securitygroup_ids      = [module.mgmt-network-security-group.network_security_group_id]
  external_subnet_ids         = [{ "subnet_id" = data.azurerm_subnet.external-public.id, "public_ip" = false, "private_ip_primary" = "", "private_ip_secondary" = "" }]
  external_securitygroup_ids  = [module.external-network-security-group-public.network_security_group_id]
  internal_subnet_ids         = [{ "subnet_id" = data.azurerm_subnet.internal.id, "public_ip" = false, "private_ip_primary" = "" }]
  internal_securitygroup_ids  = [module.internal-network-security-group.network_security_group_id]
  availability_zone           = var.availability_zone
  availabilityZones_public_ip = var.availabilityZones_public_ip
  tags                        = var.common_tags
  externalnic_failover_tags   = {f5_cfe_label = "cfe-demo-project", "f5_cloud_failover_nic_map" = "external"}
  internalnic_failover_tags   = {f5_cfe_label = "cfe-demo-project", f5_cloud_failover_nic_map = "internal"}
  user_identity               = azurerm_user_assigned_identity.user_identity.id
  DO_URL = "https://github.com/F5Networks/f5-declarative-onboarding/releases/download/v1.47.0/f5-declarative-onboarding-1.47.0-14.noarch.rpm"
  AS3_URL = "https://github.com/F5Networks/f5-appsvcs-extension/releases/download/v3.56.0/f5-appsvcs-3.56.0-10.noarch.rpm"
  TS_URL = "https://github.com/F5Networks/f5-telemetry-streaming/releases/download/v1.41.0/f5-telemetry-1.41.0-1.noarch.rpm"
  CFE_URL = "https://github.com/F5Networks/f5-cloud-failover-extension/releases/download/v2.2.0/f5-cloud-failover-2.2.0-0.noarch.rpm"
  FAST_URL = "https://github.com/F5Networks/f5-appsvcs-templates/releases/download/v1.26.0/f5-appsvcs-templates-1.26.0-1.noarch.rpm"
}

resource "null_resource" "clusterDO" {

  count = var.instance_count

  provisioner "local-exec" {
    command = "cat > DO_3nic-instance${count.index}.json <<EOL\n ${module.bigip[count.index].onboard_do}\nEOL"
  }
  provisioner "local-exec" {
    when    = destroy
    command = "rm -rf DO_3nic-instance${count.index}.json"
  }
  depends_on = [module.bigip.onboard_do]
}


#
# Create the Network Module to associate with BIGIP
#

module "network" {
  source              = "Azure/vnet/azurerm"
  version             = "3.0.0"
  vnet_name           = format("%s-vnet-%s", var.prefix, random_id.id.hex)
  resource_group_name = azurerm_resource_group.rg.name
  vnet_location       = var.location
  address_space       = [var.cidr]
  subnet_prefixes     = [cidrsubnet(var.cidr, 8, 1), cidrsubnet(var.cidr, 8, 2), cidrsubnet(var.cidr, 8, 3)]
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
  tags = var.common_tags
}

#
# Create the Network Security group Module to associate with BIGIP-External-Nic
#
module "external-network-security-group-public" {
  source              = "Azure/network-security-group/azurerm"
  resource_group_name = azurerm_resource_group.rg.name
  security_group_name = format("%s-external-public-nsg-%s", var.prefix, random_id.id.hex)
  tags = var.common_tags
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
  source_address_prefix = ["10.0.3.0/24"]
  tags = var.common_tags
}
