variable "controller_ip" {
  type = string
}

variable "controller_username" {
  type = string
}

variable "controller_password" {
  type = string
}

variable "public_key" {
  type = string
}

variable "azure_subscription_id" {
  type = string
}

variable "azure_client_id" {
  type = string
}
variable "azure_client_secret" {
  type = string
}

variable "azure_tenant_id" {
  type = string
}

variable "pre_shared_key" {
    default = "aviatrix$123"
}

variable "gw1_tunnel_ip" {
    default = "192.168.1.1/30"
}

variable "gw2_tunnel_ip" {
    default = "192.168.1.2/30"
}

variable "cloud_type" {
  default = 8
}

variable "vnet1_name" {
  default = "VPC1"
}

variable "vnet1_region" {
  default = "East US"
}

variable "vnet1_real_cidr" {
    default = "10.10.10.0/24"
}

variable "vnet1_gw_subnet" {
  default = "10.10.10.0/28"
}

variable "vnet1_natted_cidr" {
    default = "172.16.10.0/24"
}

variable "vnet2_name" {
  default = "VPC2"
}

variable "vnet2_region" {
  default = "East US 2"
}

variable "vnet2_real_cidr" {
    default = "10.10.10.0/24"
}

variable "vnet2_gw_subnet" {
  default = "10.10.10.0/28"
}

variable "vm1_real_ip" {
    default = "10.10.10.20"
}

variable "vm1_nat_ip" {
    default = "172.16.10.20"
}

variable "vm2_real_ip" {
    default = "10.10.10.30"
}

variable "vm2_nat_ip" {
    default = "192.168.10.30"
}

variable "account_name" {
    default = "azure-test-jye"
}

variable "vm1_name" {
  default = "vm1"
}

variable "vm2_name" {
  default = "vm2"
}


variable "admin_username" {
  default = "azureuser"
}
