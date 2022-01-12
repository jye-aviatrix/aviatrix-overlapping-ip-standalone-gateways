terraform {
  required_providers {
    aviatrix = {
      source  = "AviatrixSystems/aviatrix"
      version = "~> 2.20"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 2.91.0"
    }
  }
  required_version = ">= 1.0"
}

# Configure Aviatrix provider
provider "aviatrix" {
  controller_ip           = var.controller_ip
  username                = var.controller_username
  password                = var.controller_password
#   skip_version_validation = false
#   version                 = "2.19.0"
}

provider "azurerm" {
  features {}
  subscription_id = var.azure_subscription_id
  client_id       = var.azure_client_id
  client_secret   = var.azure_client_secret
  tenant_id       = var.azure_tenant_id
}


resource "aviatrix_vpc" "vpc_1" {
    cloud_type = var.cloud_type
    account_name = var.account_name
    name = var.vnet1_name
    aviatrix_transit_vpc = false
    aviatrix_firenet_vpc = false
    region = var.vnet1_region
    cidr = var.vnet1_real_cidr
}

resource "aviatrix_vpc" "vpc_2" {
    cloud_type = var.cloud_type
    account_name = var.account_name
    name = var.vnet2_name
    aviatrix_transit_vpc = false
    aviatrix_firenet_vpc = false
    region = var.vnet2_region
    cidr = var.vnet2_real_cidr
}

resource "aviatrix_gateway" "gw1" {
    single_az_ha = true
    gw_name = "GW1"
    vpc_id = aviatrix_vpc.vpc_1.vpc_id
    cloud_type = var.cloud_type
    vpc_reg = var.vnet1_region
    gw_size = "Standard_B1ms"
    account_name = var.account_name
    subnet = var.vnet1_gw_subnet
}

resource "aviatrix_gateway" "gw2" {
    single_az_ha = true
    gw_name = "GW2"
    vpc_id = aviatrix_vpc.vpc_2.vpc_id
    cloud_type = var.cloud_type
    vpc_reg = var.vnet2_region
    gw_size = "Standard_B1ms"
    account_name = var.account_name
    subnet = var.vnet2_gw_subnet
}



resource "aviatrix_site2cloud" "gw1_to_gw2" {
    vpc_id = aviatrix_vpc.vpc_1.vpc_id
    connection_name = "GW1-to-GW2"
    connection_type = "unmapped"
    remote_gateway_type = "avx"
    tunnel_type = "route"
    primary_cloud_gateway_name = aviatrix_gateway.gw1.gw_name
    remote_gateway_ip = aviatrix_gateway.gw2.eip
    ha_enabled = false
    private_route_encryption = false
    remote_subnet_cidr = var.vnet2_real_cidr
    local_subnet_cidr = var.vnet1_natted_cidr
    custom_algorithms = false
    pre_shared_key = var.pre_shared_key
    backup_pre_shared_key = ""
    enable_dead_peer_detection = true
    enable_ikev2 = true
    enable_active_active = false
    forward_traffic_to_transit = false
    custom_mapped = false
    local_tunnel_ip = var.gw1_tunnel_ip
    remote_tunnel_ip = var.gw2_tunnel_ip
}


resource "aviatrix_site2cloud" "gw2_to_gw1" {
    vpc_id = aviatrix_vpc.vpc_2.vpc_id
    connection_name = "GW2-to-GW1"
    connection_type = "unmapped"
    remote_gateway_type = "avx"
    tunnel_type = "route"
    primary_cloud_gateway_name = aviatrix_gateway.gw2.gw_name
    remote_gateway_ip = aviatrix_gateway.gw1.eip
    ha_enabled = false
    private_route_encryption = false
    remote_subnet_cidr = var.vnet1_natted_cidr
    local_subnet_cidr = var.vnet2_real_cidr
    custom_algorithms = false
    pre_shared_key = var.pre_shared_key
    backup_pre_shared_key = ""
    enable_dead_peer_detection = true
    enable_ikev2 = true
    enable_active_active = false
    forward_traffic_to_transit = false
    custom_mapped = false
    local_tunnel_ip = var.gw2_tunnel_ip
    remote_tunnel_ip = var.gw1_tunnel_ip
}

resource "aviatrix_gateway_dnat" "gateway_dnat" {
    gw_name = aviatrix_gateway.gw1.gw_name

    # GW2 to GW1
    dnat_policy {
        src_cidr = "${var.vm2_real_ip}/32"
        dst_cidr = "${var.vm1_nat_ip}/32"
        protocol = "all"
        connection = "${aviatrix_site2cloud.gw1_to_gw2.connection_name}@site2cloud"
        dnat_ips = var.vm1_real_ip
        apply_route_entry = false
    }

    # GW1 to GW2
    dnat_policy {
        src_cidr = "${var.vm1_real_ip}/32"
        dst_cidr = "${var.vm2_nat_ip}/32"
        protocol = "all"
        interface = "eth0"
        connection = "None"
        dnat_ips = var.vm2_real_ip
        apply_route_entry = true
    }

    

    sync_to_ha = false
}

resource "aviatrix_gateway_snat" "gateway_snat" {
    gw_name = aviatrix_gateway.gw1.gw_name
    snat_mode = "customized_snat"

    # GW1 to GW2
    snat_policy {
        src_cidr = "${var.vm1_real_ip}/32"
        dst_cidr = "${var.vm2_real_ip}/32"
        protocol = "all"
        interface = "eth0"
        connection = "${aviatrix_site2cloud.gw1_to_gw2.connection_name}@site2cloud"
        snat_ips = var.vm1_nat_ip
    }

    # GW2 to GW1
    snat_policy {
        src_cidr = "${var.vm2_real_ip}/32"
        dst_cidr = "${var.vm1_real_ip}/32"
        protocol = "all"
        interface = "eth0"
        connection = "None"
        snat_ips = var.vm2_nat_ip
    }

    sync_to_ha = false
}


module "vm1" {
  source = "./modules/linux-vm"
  vm_name = "vm1"
  resource_group_name = aviatrix_vpc.vpc_1.resource_group
  location = var.vnet1_region
  subnet_id = aviatrix_vpc.vpc_1.public_subnets[1].subnet_id
  public_key = var.public_key
  admin_username = var.admin_username
  private_ip_address = var.vm1_real_ip
}


module "vm2" {
  source = "./modules/linux-vm"
  vm_name = "vm2"
  resource_group_name = aviatrix_vpc.vpc_2.resource_group
  location = var.vnet2_region
  subnet_id = aviatrix_vpc.vpc_2.public_subnets[1].subnet_id
  public_key = var.public_key
  admin_username = var.admin_username
  private_ip_address = var.vm2_real_ip
}

