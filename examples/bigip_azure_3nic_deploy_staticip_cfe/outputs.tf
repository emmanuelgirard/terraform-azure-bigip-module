output "mgmtPublicIP_a" {
  value = module.bigip_a.mgmtPublicIP
}

output "mgmtPublicIP_b" {
  value = module.bigip_b.mgmtPublicIP
}

output "mgmtPublicDNS_a" {
  value = module.bigip_a.mgmtPublicDNS
}

output "mgmtPublicDNS_b" {
  value = module.bigip_b.mgmtPublicDNS
}

output "bigip_username_a" {
  value = module.bigip_a.f5_username
}

output "bigip_username_b" {
  value = module.bigip_b.f5_username
}

output "bigip_password_a" {
  value = module.bigip_a.bigip_password
}

output "bigip_password_b" {
  value = module.bigip_b.bigip_password
}

output "mgmtPort_a" {
  value = module.bigip_a.mgmtPort
}

output "mgmtPort_b" {
  value = module.bigip_b.mgmtPort
}

output "mgmtPublicURL_a" {
  description = "mgmtPublicURL for bigip-A"
  value       = format("https://%s:%s", module.bigip_a.mgmtPublicDNS, module.bigip_a.mgmtPort)
}

output "mgmtPublicURL_b" {
  description = "mgmtPublicURL for bigip-B"
  value       = format("https://%s:%s", module.bigip_b.mgmtPublicDNS, module.bigip_b.mgmtPort)
}

output "resourcegroup_name" {
  description = "Resource Group in which objects are created"
  value       = azurerm_resource_group.rg.name
}

output "public_addresses_a" {
  value = module.bigip_a.public_addresses
}

output "public_addresses_b" {
  value = module.bigip_b.public_addresses
}

output "private_addresses_a" {
  value = module.bigip_a.private_addresses
}

output "private_addresses_b" {
  value = module.bigip_b.private_addresses
}

output "bigip_instance_ids" {
  description = "List of BIG-IP instance IDs"
  value       = [module.bigip_a.bigip_instance_ids, module.bigip_b.bigip_instance_ids]
}

output "user_identity_id" {
  description = "The ID of the user-assigned managed identity used for CFE"
  value       = azurerm_user_assigned_identity.user_identity.id
}
