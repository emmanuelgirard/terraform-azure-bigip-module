provider "azurerm" {
  //  version = "~>2.0"
  features {}
}

#
# Create a random id
#
resource "random_id" "id" {
  byte_length = 2
}

resource "azurerm_ssh_public_key" "f5_key" {
  name                = format("%s-pubkey-%s", var.prefix, random_id.id.hex)
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  public_key          = file("~/.ssh/id_rsa.pub")
}

#
# Create BIG-IP A (active) with static IPs and availability set
#
module "bigip_a" {
  source                      = "../../"
  prefix                      = format("%s-3nic-a", var.prefix)
  resource_group_name         = azurerm_resource_group.rg.name
  f5_password                 = var.f5_password
  f5_ssh_publickey            = azurerm_ssh_public_key.f5_key.public_key
  mgmt_subnet_ids             = [{ "subnet_id" = data.azurerm_subnet.mgmt.id, "public_ip" = true, "private_ip_primary" = "10.9.47.20" }]
  mgmt_securitygroup_ids      = [module.mgmt-network-security-group.network_security_group_id]
  external_subnet_ids         = [{ "subnet_id" = data.azurerm_subnet.external-public.id, "public_ip" = true, "private_ip_primary" = "10.9.46.4", "private_ip_secondary" = "10.9.46.6" }]
  external_securitygroup_ids  = [module.external-network-security-group-public.network_security_group_id]
  internal_subnet_ids         = [{ "subnet_id" = data.azurerm_subnet.internal.id, "public_ip" = false, "private_ip_primary" = "10.9.47.4" }]
  internal_securitygroup_ids  = [module.internal-network-security-group.network_security_group_id]
  availability_zone           = null
  availabilityZones_public_ip = "No-Zone"
  availability_set_id         = azurerm_availability_set.avset.id
  user_identity               = azurerm_user_assigned_identity.user_identity.id
  DO_URL                      = "https://github.com/F5Networks/f5-declarative-onboarding/releases/download/v1.47.0/f5-declarative-onboarding-1.47.0-14.noarch.rpm"
  AS3_URL                     = "https://github.com/F5Networks/f5-appsvcs-extension/releases/download/v3.56.0/f5-appsvcs-3.56.0-10.noarch.rpm"
  TS_URL                      = "https://github.com/F5Networks/f5-telemetry-streaming/releases/download/v1.41.0/f5-telemetry-1.41.0-1.noarch.rpm"
  CFE_URL                     = "https://github.com/F5Networks/f5-cloud-failover-extension/releases/download/v2.4.0/f5-cloud-failover-2.4.0-0.noarch.rpm"
  FAST_URL                    = "https://github.com/F5Networks/f5-appsvcs-templates/releases/download/v1.26.0/f5-appsvcs-templates-1.26.0-1.noarch.rpm"
  INIT_URL                    = "https://cdn.f5.com/product/cloudsolutions/f5-bigip-runtime-init/v2.0.3/dist/f5-bigip-runtime-init-2.0.3-1.gz.run"
  tags                        = var.common_tags
  cfe_secondary_vip_disable   = false
}

#
# Create BIG-IP B (standby) with static IPs and availability set
#
module "bigip_b" {
  source                      = "../../"
  prefix                      = format("%s-3nic-b", var.prefix)
  resource_group_name         = azurerm_resource_group.rg.name
  f5_password                 = var.f5_password
  f5_ssh_publickey            = azurerm_ssh_public_key.f5_key.public_key
  mgmt_subnet_ids             = [{ "subnet_id" = data.azurerm_subnet.mgmt.id, "public_ip" = true, "private_ip_primary" = "10.9.47.21" }]
  mgmt_securitygroup_ids      = [module.mgmt-network-security-group.network_security_group_id]
  external_subnet_ids         = [{ "subnet_id" = data.azurerm_subnet.external-public.id, "public_ip" = true, "private_ip_primary" = "10.9.46.5", "private_ip_secondary" = "" }]
  external_securitygroup_ids  = [module.external-network-security-group-public.network_security_group_id]
  internal_subnet_ids         = [{ "subnet_id" = data.azurerm_subnet.internal.id, "public_ip" = false, "private_ip_primary" = "10.9.47.5" }]
  internal_securitygroup_ids  = [module.internal-network-security-group.network_security_group_id]
  availability_zone           = null
  availabilityZones_public_ip = "No-Zone"
  availability_set_id         = azurerm_availability_set.avset.id
  user_identity               = azurerm_user_assigned_identity.user_identity.id
  DO_URL                      = "https://github.com/F5Networks/f5-declarative-onboarding/releases/download/v1.47.0/f5-declarative-onboarding-1.47.0-14.noarch.rpm"
  AS3_URL                     = "https://github.com/F5Networks/f5-appsvcs-extension/releases/download/v3.56.0/f5-appsvcs-3.56.0-10.noarch.rpm"
  TS_URL                      = "https://github.com/F5Networks/f5-telemetry-streaming/releases/download/v1.41.0/f5-telemetry-1.41.0-1.noarch.rpm"
  CFE_URL                     = "https://github.com/F5Networks/f5-cloud-failover-extension/releases/download/v2.4.0/f5-cloud-failover-2.4.0-0.noarch.rpm"
  FAST_URL                    = "https://github.com/F5Networks/f5-appsvcs-templates/releases/download/v1.26.0/f5-appsvcs-templates-1.26.0-1.noarch.rpm"
  INIT_URL                    = "https://cdn.f5.com/product/cloudsolutions/f5-bigip-runtime-init/v2.0.3/dist/f5-bigip-runtime-init-2.0.3-1.gz.run"
  tags                        = var.common_tags
  cfe_secondary_vip_disable   = true
}

resource "null_resource" "clusterDO_a" {
  provisioner "local-exec" {
    command = "cat > DO_3nic-bigip-a.json <<EOL\n ${module.bigip_a.onboard_do}\nEOL"
  }
  provisioner "local-exec" {
    when    = destroy
    command = "rm -rf DO_3nic-bigip-a.json"
  }
  depends_on = [module.bigip_a.onboard_do]
}

resource "null_resource" "clusterDO_b" {
  provisioner "local-exec" {
    command = "cat > DO_3nic-bigip-b.json <<EOL\n ${module.bigip_b.onboard_do}\nEOL"
  }
  provisioner "local-exec" {
    when    = destroy
    command = "rm -rf DO_3nic-bigip-b.json"
  }
  depends_on = [module.bigip_b.onboard_do]
}
