provider "azurerm" {
  //  version = "~>2.0"
  features {}
}

locals {
  # CFE tags — defined once from cfe_label variable
  common_tags_with_cfe = merge(var.common_tags, {
    f5_cfe_label = var.cfe_label
  })

  externalnic_failover_tags = {
    f5_cfe_label              = var.cfe_label
    f5_cloud_failover_nic_map = "external"
  }

  internalnic_failover_tags = {
    f5_cfe_label              = var.cfe_label
    f5_cloud_failover_nic_map = "internal"
  }
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
  create_user_identity        = false
  user_identity               = azurerm_user_assigned_identity.user_identity.id
  DO_URL                      = "https://github.com/F5Networks/f5-declarative-onboarding/releases/download/v1.47.0/f5-declarative-onboarding-1.47.0-14.noarch.rpm"
  AS3_URL                     = "https://github.com/F5Networks/f5-appsvcs-extension/releases/download/v3.56.0/f5-appsvcs-3.56.0-10.noarch.rpm"
  TS_URL                      = "https://github.com/F5Networks/f5-telemetry-streaming/releases/download/v1.41.0/f5-telemetry-1.41.0-1.noarch.rpm"
  CFE_URL                     = "https://github.com/F5Networks/f5-cloud-failover-extension/releases/download/v2.4.0/f5-cloud-failover-2.4.0-0.noarch.rpm"
  FAST_URL                    = "https://github.com/F5Networks/f5-appsvcs-templates/releases/download/v1.26.0/f5-appsvcs-templates-1.26.0-1.noarch.rpm"
  INIT_URL                    = "https://cdn.f5.com/product/cloudsolutions/f5-bigip-runtime-init/v2.0.3/dist/f5-bigip-runtime-init-2.0.3-1.gz.run"
  tags                        = local.common_tags_with_cfe
  externalnic_failover_tags   = local.externalnic_failover_tags
  internalnic_failover_tags   = local.internalnic_failover_tags
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
  create_user_identity        = false
  user_identity               = azurerm_user_assigned_identity.user_identity.id
  DO_URL                      = "https://github.com/F5Networks/f5-declarative-onboarding/releases/download/v1.47.0/f5-declarative-onboarding-1.47.0-14.noarch.rpm"
  AS3_URL                     = "https://github.com/F5Networks/f5-appsvcs-extension/releases/download/v3.56.0/f5-appsvcs-3.56.0-10.noarch.rpm"
  TS_URL                      = "https://github.com/F5Networks/f5-telemetry-streaming/releases/download/v1.41.0/f5-telemetry-1.41.0-1.noarch.rpm"
  CFE_URL                     = "https://github.com/F5Networks/f5-cloud-failover-extension/releases/download/v2.4.0/f5-cloud-failover-2.4.0-0.noarch.rpm"
  FAST_URL                    = "https://github.com/F5Networks/f5-appsvcs-templates/releases/download/v1.26.0/f5-appsvcs-templates-1.26.0-1.noarch.rpm"
  INIT_URL                    = "https://cdn.f5.com/product/cloudsolutions/f5-bigip-runtime-init/v2.0.3/dist/f5-bigip-runtime-init-2.0.3-1.gz.run"
  tags                        = local.common_tags_with_cfe
  externalnic_failover_tags   = local.externalnic_failover_tags
  internalnic_failover_tags   = local.internalnic_failover_tags
  cfe_secondary_vip_disable   = true
}

locals {
  external_prefix_length = split("/", var.external_subnet_prefix)[1]
  internal_prefix_length = split("/", var.internal_subnet_prefix)[1]

  do_bigip_a = templatefile("${path.module}/templates/onboard_do_3nic_cfe.tpl", {
    hostname        = module.bigip_a.mgmtPublicDNS
    name_servers    = join(",", formatlist("\"%s\"", ["168.63.129.16"]))
    ntp_servers     = join(",", formatlist("\"%s\"", ["169.254.169.123"]))
    vlan_name1      = "external-public-subnet"
    self_ip1        = module.bigip_a.private_addresses["public_private"]["private_ip"][0]
    self_ip1_mask   = local.external_prefix_length
    vlan_name2      = "internal-subnet"
    self_ip2        = module.bigip_a.private_addresses["internal_private"]["private_ip"][0]
    self_ip2_mask   = local.internal_prefix_length
    gateway         = cidrhost(var.external_subnet_prefix, 1)
    bigip_username  = module.bigip_a.f5_username
    local_password  = var.f5_password != "" ? var.f5_password : module.bigip_a.bigip_password
    remote_password = var.f5_password != "" ? var.f5_password : module.bigip_b.bigip_password
    remote_host     = "10.9.47.5"
    local_host      = "10.9.47.4"
    member_a        = "10.9.47.4"
    member_b        = "10.9.47.5"
  })

  do_bigip_b = templatefile("${path.module}/templates/onboard_do_3nic_cfe.tpl", {
    hostname        = module.bigip_b.mgmtPublicDNS
    name_servers    = join(",", formatlist("\"%s\"", ["168.63.129.16"]))
    ntp_servers     = join(",", formatlist("\"%s\"", ["169.254.169.123"]))
    vlan_name1      = "external-public-subnet"
    self_ip1        = module.bigip_b.private_addresses["public_private"]["private_ip"][0]
    self_ip1_mask   = local.external_prefix_length
    vlan_name2      = "internal-subnet"
    self_ip2        = module.bigip_b.private_addresses["internal_private"]["private_ip"][0]
    self_ip2_mask   = local.internal_prefix_length
    gateway         = cidrhost(var.external_subnet_prefix, 1)
    bigip_username  = module.bigip_b.f5_username
    local_password  = var.f5_password != "" ? var.f5_password : module.bigip_b.bigip_password
    remote_password = var.f5_password != "" ? var.f5_password : module.bigip_a.bigip_password
    remote_host     = "10.9.47.4"
    local_host      = "10.9.47.5"
    member_a        = "10.9.47.4"
    member_b        = "10.9.47.5"
  })

  cfe_declaration = templatefile("${path.module}/templates/cfe_declaration.tpl", {
    storage_account_name = azurerm_storage_account.storage_account.name
    failover_vip         = "10.9.46.6"
  })
}

resource "local_file" "do_bigip_a" {
  content  = local.do_bigip_a
  filename = "${path.module}/DO_3nic-bigip-a.json"

  depends_on = [module.bigip_a]
}

resource "local_file" "do_bigip_b" {
  content  = local.do_bigip_b
  filename = "${path.module}/DO_3nic-bigip-b.json"

  depends_on = [module.bigip_b]
}

resource "local_file" "cfe_declaration" {
  content  = local.cfe_declaration
  filename = "${path.module}/cfe_declaration.json"

  depends_on = [module.bigip_a, module.bigip_b]
}

resource "local_file" "deploy_do_a" {
  content = templatefile("${path.module}/templates/deploy_do.sh.tpl", {
    bigip_name            = "bigip-A"
    bigip_mgmt_ip         = module.bigip_a.mgmtPublicIP
    bigip_mgmt_port       = module.bigip_a.mgmtPort
    bigip_username        = module.bigip_a.f5_username
    bigip_password_output = "bigip_password_a"
    do_filename           = "DO_3nic-bigip-a.json"
  })
  filename        = "${path.module}/deploy_do_a.sh"
  file_permission = "0755"

  depends_on = [module.bigip_a]
}

resource "local_file" "deploy_do_b" {
  content = templatefile("${path.module}/templates/deploy_do.sh.tpl", {
    bigip_name            = "bigip-B"
    bigip_mgmt_ip         = module.bigip_b.mgmtPublicIP
    bigip_mgmt_port       = module.bigip_b.mgmtPort
    bigip_username        = module.bigip_b.f5_username
    bigip_password_output = "bigip_password_b"
    do_filename           = "DO_3nic-bigip-b.json"
  })
  filename        = "${path.module}/deploy_do_b.sh"
  file_permission = "0755"

  depends_on = [module.bigip_b]
}

resource "local_file" "deploy_cfe_a" {
  content = templatefile("${path.module}/templates/deploy_cfe.sh.tpl", {
    bigip_name            = "bigip-A"
    bigip_mgmt_ip         = module.bigip_a.mgmtPublicIP
    bigip_mgmt_port       = module.bigip_a.mgmtPort
    bigip_username        = module.bigip_a.f5_username
    bigip_password_output = "bigip_password_a"
    cfe_filename          = "cfe_declaration.json"
  })
  filename        = "${path.module}/deploy_cfe_a.sh"
  file_permission = "0755"

  depends_on = [module.bigip_a]
}

resource "local_file" "deploy_cfe_b" {
  content = templatefile("${path.module}/templates/deploy_cfe.sh.tpl", {
    bigip_name            = "bigip-B"
    bigip_mgmt_ip         = module.bigip_b.mgmtPublicIP
    bigip_mgmt_port       = module.bigip_b.mgmtPort
    bigip_username        = module.bigip_b.f5_username
    bigip_password_output = "bigip_password_b"
    cfe_filename          = "cfe_declaration.json"
  })
  filename        = "${path.module}/deploy_cfe_b.sh"
  file_permission = "0755"

  depends_on = [module.bigip_b]
}

resource "local_file" "deploy_do_a_ps1" {
  content = templatefile("${path.module}/templates/deploy_do.ps1.tpl", {
    bigip_name            = "bigip-A"
    bigip_mgmt_ip         = module.bigip_a.mgmtPublicIP
    bigip_mgmt_port       = module.bigip_a.mgmtPort
    bigip_username        = module.bigip_a.f5_username
    bigip_password_output = "bigip_password_a"
    do_filename           = "DO_3nic-bigip-a.json"
  })
  filename = "${path.module}/deploy_do_a.ps1"

  depends_on = [module.bigip_a]
}

resource "local_file" "deploy_do_b_ps1" {
  content = templatefile("${path.module}/templates/deploy_do.ps1.tpl", {
    bigip_name            = "bigip-B"
    bigip_mgmt_ip         = module.bigip_b.mgmtPublicIP
    bigip_mgmt_port       = module.bigip_b.mgmtPort
    bigip_username        = module.bigip_b.f5_username
    bigip_password_output = "bigip_password_b"
    do_filename           = "DO_3nic-bigip-b.json"
  })
  filename = "${path.module}/deploy_do_b.ps1"

  depends_on = [module.bigip_b]
}

resource "local_file" "deploy_cfe_a_ps1" {
  content = templatefile("${path.module}/templates/deploy_cfe.ps1.tpl", {
    bigip_name            = "bigip-A"
    bigip_mgmt_ip         = module.bigip_a.mgmtPublicIP
    bigip_mgmt_port       = module.bigip_a.mgmtPort
    bigip_username        = module.bigip_a.f5_username
    bigip_password_output = "bigip_password_a"
    cfe_filename          = "cfe_declaration.json"
  })
  filename = "${path.module}/deploy_cfe_a.ps1"

  depends_on = [module.bigip_a]
}

resource "local_file" "deploy_cfe_b_ps1" {
  content = templatefile("${path.module}/templates/deploy_cfe.ps1.tpl", {
    bigip_name            = "bigip-B"
    bigip_mgmt_ip         = module.bigip_b.mgmtPublicIP
    bigip_mgmt_port       = module.bigip_b.mgmtPort
    bigip_username        = module.bigip_b.f5_username
    bigip_password_output = "bigip_password_b"
    cfe_filename          = "cfe_declaration.json"
  })
  filename = "${path.module}/deploy_cfe_b.ps1"

  depends_on = [module.bigip_b]
}
