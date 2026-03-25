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

variable "license_key_a" {
  description = "BIG-IP registration key for bigip-A. Leave empty for PAYG/hourly images."
  type        = string
  sensitive   = true
  default     = ""
}

variable "license_key_b" {
  description = "BIG-IP registration key for bigip-B. Leave empty for PAYG/hourly images."
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


variable "f5_image_name" {
  type        = string
  default     = "f5-bigip-virtual-edition-25m-better-hourly"
  description = <<-EOD
After finding the image to use with the Azure CLI with a variant of the following;

az vm image list --publisher f5-networks --all -f better

{
    "offer": "f5-big-ip-better",
    "publisher": "f5-networks",
    "sku": "f5-bigip-virtual-edition-25m-better-hourly",
    "urn": "f5-networks:f5-big-ip-better:f5-bigip-virtual-edition-25m-better-hourly:14.1.404001",
    "version": "14.1.404001"
}

f5_image_name is equivalent to the "sku" returned.
EOD  
}
variable "f5_version" {
  type        = string
  default     = "17.5.105000"
  description = <<-EOD
After finding the image to use with the Azure CLI with a variant of the following;

az vm image list --publisher f5-networks --all -f better

{
    "offer": "f5-big-ip-better",
    "publisher": "f5-networks",
    "sku": "f5-bigip-virtual-edition-25m-better-hourly",
    "urn": "f5-networks:f5-big-ip-better:f5-bigip-virtual-edition-25m-better-hourly:14.1.404001",
    "version": "14.1.404001"
}

f5_version is equivalent to the "version" returned.
EOD  
}

variable "f5_product_name" {
  type        = string
  default     = "f5-big-ip-better"
  description = <<-EOD
After finding the image to use with the Azure CLI with a variant of the following;

az vm image list --publisher f5-networks --all -f better

{
    "offer": "f5-big-ip-better",
    "publisher": "f5-networks",
    "sku": "f5-bigip-virtual-edition-25m-better-hourly",
    "urn": "f5-networks:f5-big-ip-better:f5-bigip-virtual-edition-25m-better-hourly:14.1.404001",
    "version": "14.1.404001"
}

f5_product_name is equivalent to the "offer" returned.
EOD  
}