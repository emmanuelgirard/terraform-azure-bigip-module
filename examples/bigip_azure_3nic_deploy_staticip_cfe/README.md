# Deploys F5 BIG-IP Azure Cloud

* This Terraform module deploys `3-NIC` BIG-IP in Azure cloud with **static IP** addressing
* Two BIG-IP instances (bigip-A and bigip-B) deployed in an **Azure Availability Set**
* **User-assigned managed identity** with custom CFE role and Contributor permissions
* **Cloud Failover Extension (CFE)** storage account for state management
* Management interface: **10.9.47.16/29** (bigip-A: 10.9.47.20, bigip-B: 10.9.47.21)
* External interface: **10.9.46.0/24** (bigip-A: 10.9.46.4 / VIP 10.9.46.6, bigip-B: 10.9.46.5)
* Internal interface: **10.9.47.0/28** (bigip-A: 10.9.47.4, bigip-B: 10.9.47.5)
* Public IPs on both management and external interfaces
* Random generated `password` for login to BIG-IP (in case of explicit `f5_password` not provided and default value of `az_key_vault_authentication` is false )

## Example Usage

```hcl
module "bigip_a" {
  source                      = "F5Networks/bigip-module/azure"
  prefix                      = format("%s-bigip-a", var.prefix)
  resource_group_name         = azurerm_resource_group.rg.name
  f5_ssh_publickey            = azurerm_ssh_public_key.f5_key.public_key
  mgmt_subnet_ids             = [{ "subnet_id" = data.azurerm_subnet.mgmt.id, "public_ip" = true, "private_ip_primary" = "10.9.47.20" }]
  mgmt_securitygroup_ids      = [module.mgmt-network-security-group.network_security_group_id]
  external_subnet_ids         = [{ "subnet_id" = data.azurerm_subnet.external-public.id, "public_ip" = true, "private_ip_primary" = "10.9.46.4", "private_ip_secondary" = "10.9.46.6" }]
  external_securitygroup_ids  = [module.external-network-security-group-public.network_security_group_id]
  internal_subnet_ids         = [{ "subnet_id" = data.azurerm_subnet.internal.id, "public_ip" = false, "private_ip_primary" = "10.9.47.4" }]
  internal_securitygroup_ids  = [module.internal-network-security-group.network_security_group_id]
  availability_set_id         = azurerm_availability_set.avset.id
  user_identity               = azurerm_user_assigned_identity.user_identity.id
  externalnic_failover_tags   = { ... }
  internalnic_failover_tags   = { ... }
  tags                        = var.common_tags
}

module "bigip_b" {
  source                      = "F5Networks/bigip-module/azure"
  prefix                      = format("%s-bigip-b", var.prefix)
  resource_group_name         = azurerm_resource_group.rg.name
  f5_ssh_publickey            = azurerm_ssh_public_key.f5_key.public_key
  mgmt_subnet_ids             = [{ "subnet_id" = data.azurerm_subnet.mgmt.id, "public_ip" = true, "private_ip_primary" = "10.9.47.21" }]
  mgmt_securitygroup_ids      = [module.mgmt-network-security-group.network_security_group_id]
  external_subnet_ids         = [{ "subnet_id" = data.azurerm_subnet.external-public.id, "public_ip" = true, "private_ip_primary" = "10.9.46.5", "private_ip_secondary" = "" }]
  external_securitygroup_ids  = [module.external-network-security-group-public.network_security_group_id]
  internal_subnet_ids         = [{ "subnet_id" = data.azurerm_subnet.internal.id, "public_ip" = false, "private_ip_primary" = "10.9.47.5" }]
  internal_securitygroup_ids  = [module.internal-network-security-group.network_security_group_id]
  availability_set_id         = azurerm_availability_set.avset.id
  user_identity               = azurerm_user_assigned_identity.user_identity.id
  externalnic_failover_tags   = { ... }
  internalnic_failover_tags   = { ... }
  tags                        = var.common_tags
}
```

* Modify `terraform.tfvars` according to the requirement by changing `location` and `AllowedIPs` variables as follows

```hcl
location   = "canadacentral"
AllowedIPs = ["0.0.0.0/0"]
```

* Next, Run the following commands to `create` and `destroy` your configuration

```shell
$terraform init
$terraform plan
$terraform apply
$terraform destroy
```

### Optional Input Variables

| Name | Description | Type | Default |
|------|-------------|------|---------|
| prefix | Prefix for resources created by this module | `string` | tf-azure-bigip |
| location | Azure region for deployment | `string` | - |
| AllowedIPs | Allowed source IPs for NSG rules | `list` | - |
| common_tags | Tags applied to all resources | `map` | {} |
| cidr | Azure VNet CIDR | `string` | 10.9.46.0/23 |
| mgmt_subnet_prefix | Management subnet CIDR | `string` | 10.9.47.16/29 |
| external_subnet_prefix | External subnet CIDR | `string` | 10.9.46.0/24 |
| internal_subnet_prefix | Internal subnet CIDR | `string` | 10.9.47.0/28 |

### Output Variables

| Name | Description |
|------|-------------|
| mgmtPublicIP_a | Management public IP for bigip-A |
| mgmtPublicIP_b | Management public IP for bigip-B |
| mgmtPort | Mgmt Port |
| f5\_username | BIG-IP username |
| bigip\_password\_a | BIG-IP Password for bigip-A (if dynamic_password is choosen it will be random generated password or if azure_keyvault is choosen it will be key vault secret name ) |
| bigip\_password\_b | BIG-IP Password for bigip-B |
| mgmtPublicURL_a | Complete url including DNS and port for bigip-A |
| mgmtPublicURL_b | Complete url including DNS and port for bigip-B |
| resourcegroup_name | Resource Group in which objects are created |
| public_addresses_a | List of BIG-IP public addresses for bigip-A |
| public_addresses_b | List of BIG-IP public addresses for bigip-B |
| private_addresses_a | List of BIG-IP private addresses for bigip-A |
| private_addresses_b | List of BIG-IP private addresses for bigip-B |

~> **NOTE** A local json file will get generated which contains the DO declaration

### Steps to clone and use the module locally

```shell
$git clone https://github.com/F5Networks/terraform-azure-bigip-module
$cd terraform-azure-bigip-module/examples/bigip_azure_3nic_deploy_staticip_cfe/
```
