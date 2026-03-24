variable "prefix" {
  description = "Prefix for resources created by this module"
  type        = string
  default     = "tf-azure-bigip"
}

variable "f5_password" {
  description = "BIG-IP admin password. If not specified, a random password will be generated."
  type        = string
  sensitive   = true
  default     = ""
}

variable "location" {}

variable "AllowedIPs" {}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "cfe_label" {
  description = "CFE label used to identify failover objects (NICs, IPs, storage). Defined once and referenced in common_tags, NIC failover tags, and CFE declaration."
  type        = string
  default     = "cfe-demo-project"
}

variable "cidr" {
  description = "Azure VNet CIDR encompassing all subnets"
  type        = string
  default     = "10.9.46.0/23"
}

variable "mgmt_subnet_prefix" {
  description = "CIDR prefix for the management subnet"
  type        = string
  default     = "10.9.47.16/29"
}

variable "external_subnet_prefix" {
  description = "CIDR prefix for the external subnet"
  type        = string
  default     = "10.9.46.0/24"
}

variable "internal_subnet_prefix" {
  description = "CIDR prefix for the internal subnet"
  type        = string
  default     = "10.9.47.0/28"
}

