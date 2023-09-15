#######################################################################################################################################################################################################
# Resources Groups
#
########################################################################################################################################################################################################
#  Resource Group Module is Used to Create Resource Groups
module "hub-resourcegroup" {
  source = "./modules/resourcegroups"
  # Resource Group Variables
  az_rg_name     = "Hub-rg"
  az_rg_location = "eastus2"
  az_tags = {
    ApplicationName = "Network"
    Role            = "Network"
    Owner           = "IT"
    Environment     = "Prod"
    CompanyName     = "NETB"
    Criticality     = "Medium"
    DR              = "No"
  }
}

#######################################################################################################################################################################################################
# Resources Groups
#
########################################################################################################################################################################################################
# Resource Group Module is Used to Create Resource Groups
module "spoke1-resourcegroup" {
  source = "./modules/resourcegroups"
  # Resource Group Variables
  az_rg_name     = "spoke-rg"
  az_rg_location = "eastus2"
  az_tags = {
    ApplicationName = "Network"
    Role            = "Network"
    Owner           = "IT"
    Environment     = "Prod"
    CompanyName     = "NETB"
    Criticality     = "Medium"
    DR              = "No"
  }
}
#######################################################################################################################################################################################################
# Resources Groups
#
########################################################################################################################################################################################################
# Resource Group Module is Used to Create Resource Groups
module "mgmt-resourcegroup" {
  source = "./modules/resourcegroups"
  # Resource Group Variables
  az_rg_name     = "JumpControl-rg"
  az_rg_location = "eastus2"
  az_tags = {
    ApplicationName = "Network"
    Role            = "Network"
    Owner           = "IT"
    Environment     = "Prod"
    CompanyName     = "NETB"
    Criticality     = "Medium"
    DR              = "No"
  }
}

# Resource Group Module is Used to Create Resource Groups
module "mgmt-resourcegroup_01" {
  source = "./modules/resourcegroups"
  # Resource Group Variables
  az_rg_name     = "az-mgmt-pr-eastus2-rg"
  az_rg_location = "eastus2"
  az_tags = {
    ApplicationName = "Network"
    Role            = "Network"
    Owner           = "IT"
    Environment     = "Prod"
    CompanyName     = "NETB"
    Criticality     = "Medium"
    DR              = "No"
  }
}


#######################################################################################################################################################################################################
# vnet Module is used to create Virtual Networks and Subnets
#
########################################################################################################################################################################################################
#
module "hub-vnet" {
  source = "./modules/vnet"

  virtual_network_name          = "Hub-vnet"
  resource_group_name           = module.hub-resourcegroup.rg_name
  location                      = module.hub-resourcegroup.rg_location
  virtual_network_address_space = ["10.20.0.0/16"]


  subnet_names = {
    "GatewaySubnet" = {
      subnet_name      = "GatewaySubnet"
      address_prefixes = ["10.20.1.0/24"]
      route_table_name = ""
      snet_delegation  = ""
    },
    "AzureFirewallSubnet" = {
      subnet_name      = "AzureFirewallSubnet"
      address_prefixes = ["10.20.2.0/24"]
      route_table_name = ""
      snet_delegation  = ""
    },
    "ApplicationGatewaySubnet" = {
      subnet_name      = "ApplicationGatewaySubnet"
      address_prefixes = ["10.20.3.0/24"]
      route_table_name = ""
      snet_delegation  = ""
    }
    "AzureBastionSubnet" = {
      subnet_name      = "AzureBastionSubnet"
      address_prefixes = ["10.20.4.0/24"]
      route_table_name = ""
      snet_delegation  = ""
    }
    "JumpboxSubnet" = {
      subnet_name      = "JumpboxSubnet"
      address_prefixes = ["10.20.5.0/24"]
      route_table_name = ""
      snet_delegation  = ""
    }
  }
}

# vnet Module is used to create Virtual Networks and Subnets
module "spoke1-vnet" {
  source = "./modules/vnet"

  virtual_network_name          = "spoke1-vnet"
  resource_group_name           = module.spoke1-resourcegroup.rg_name
  location                      = module.spoke1-resourcegroup.rg_location
  virtual_network_address_space = ["10.21.0.0/16"]
  subnet_names = {
    "az-netb-pr-web-snet" = {
      subnet_name      = "spoke1-pr-web-snet"
      address_prefixes = ["10.21.1.0/24"]
      route_table_name = ""
      snet_delegation  = ""
    },
    "az-netb-pr-db-snet" = {
      subnet_name      = "spoke1-pr-db-snet"
      address_prefixes = ["10.21.2.0/24"]
      route_table_name = ""
      snet_delegation  = ""
    }
  }
}
#######################################################################################################################################################################################################
#
# vnet-peering Module is used to create peering between Virtual Networks
#
########################################################################################################################################################################################################

module "hub-to-spoke1" {
  source     = "./modules/vnet-peering"
  depends_on = [module.hub-vnet, module.spoke1-vnet, module.azure_firewall_01]
  #depends_on = [module.hub-vnet , module.spoke1-vnet , module.application_gateway, module.vpn_gateway , module.azure_firewall_01]

  virtual_network_peering_name = "Hub-vnet-to-spoke1-vnet"
  resource_group_name          = module.hub-resourcegroup.rg_name
  virtual_network_name         = module.hub-vnet.vnet_name
  remote_virtual_network_id    = module.spoke1-vnet.vnet_id
  allow_virtual_network_access = "true"
  allow_forwarded_traffic      = "true"
  allow_gateway_transit        = "true"
  use_remote_gateways          = "false"

}

#######################################################################################################################################################################################################
#
# vnet-peering Module is used to create peering between Virtual Networks
#
########################################################################################################################################################################################################



module "spoke1-to-hub" {
  source = "./modules/vnet-peering"

  virtual_network_peering_name = "spoke1-vnet-to-hub-vnet"
  resource_group_name          = module.spoke1-resourcegroup.rg_name
  virtual_network_name         = module.spoke1-vnet.vnet_name
  remote_virtual_network_id    = module.hub-vnet.vnet_id
  allow_virtual_network_access = "true"
  allow_forwarded_traffic      = "true"
  allow_gateway_transit        = "false"

  use_remote_gateways = "false"
  depends_on          = [module.hub-vnet, module.spoke1-vnet]
}
#######################################################################################################################################################################################################
#
# routetables Module is used to create route tables and associate them with Subnets created by Virtual Networks
#
########################################################################################################################################################################################################



module "route_tables" {
  source     = "./modules/routetables"
  depends_on = [module.hub-vnet, module.spoke1-vnet]

  route_table_name              = "az-netb-pr-eastus2-route"
  location                      = module.hub-resourcegroup.rg_location
  resource_group_name           = module.hub-resourcegroup.rg_name
  disable_bgp_route_propagation = false

  route_name             = "ToAzureFirewall"
  address_prefix         = "0.0.0.0/0"
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = module.azure_firewall_01.azure_firewall_private_ip

  subnet_ids = [
    module.spoke1-vnet.vnet_subnet_id[0],
    module.spoke1-vnet.vnet_subnet_id[1]
  ]

}
#######################################################################################################################################################################################################
#
# publicip Module is used to create Public IP Address
#
########################################################################################################################################################################################################




module "public_ip_01" {
  source = "./modules/publicip"

  # Used for VPN Gateway
  public_ip_name      = "Hub-vgw-pip01"
  resource_group_name = module.hub-resourcegroup.rg_name
  location            = module.hub-resourcegroup.rg_location
  allocation_method   = "Static"
  sku                 = "Standard"
}

# publicip Module is used to create Public IP Address
module "public_ip_02" {
  source = "./modules/publicip"

  # Used for Application Gateway
  public_ip_name      = "Hub-agw-pip02"
  resource_group_name = module.hub-resourcegroup.rg_name
  location            = module.hub-resourcegroup.rg_location
  allocation_method   = "Static"
  sku                 = "Standard"
}

# publicip Module is used to create Public IP Address
module "public_ip_03" {
  source = "./modules/publicip"

  # Used for Azure Firewall
  public_ip_name      = "Hub-afw-pip03"
  resource_group_name = module.hub-resourcegroup.rg_name
  location            = module.hub-resourcegroup.rg_location
  allocation_method   = "Static"
  sku                 = "Standard"
}

# publicip Module is used to create Public IP Address
module "public_ip_04" {
  source = "./modules/publicip"

  # Used for Azure Bastion
  public_ip_name      = "bation-afw-pip04"
  resource_group_name = module.hub-resourcegroup.rg_name
  location            = module.hub-resourcegroup.rg_location
  allocation_method   = "Static"
  sku                 = "Standard"
}

# azurefirewall Module is used to create Azure Firewall
# Firewall Policy
# Associate Firewall Policy with Azure Firewall
# Network and Application Firewall Rules
module "azure_firewall_01" {
  source     = "./modules/azurefirewall"
  depends_on = [module.hub-vnet]

  azure_firewall_name = "Hub-eastus2-afw"
  location            = module.hub-resourcegroup.rg_location
  resource_group_name = module.hub-resourcegroup.rg_name
  sku_name            = "AZFW_VNet"
  sku_tier            = "Standard"

  ipconfig_name        = "configuration"
  subnet_id            = module.hub-vnet.vnet_subnet_id[2]
  public_ip_address_id = module.public_ip_03.public_ip_address_id

  azure_firewall_policy_coll_group_name = "Hub-eastus2-afw-coll-pol01"
  azure_firewall_policy_name            = "Hub-eastus2-afw-pol01"
  priority                              = 100

  network_rule_coll_name_01     = "Blocked_Network_Rules"
  network_rule_coll_priority_01 = "2000"
  network_rule_coll_action_01   = "Deny"
  network_rules_01 = [
    {
      name                  = "Blocked_rule_1"
      source_addresses      = ["10.1.0.0/16"]
      destination_addresses = ["10.8.8.8", "8.10.4.4"]
      destination_ports     = [11]
      protocols             = ["TCP"]
    },
    {
      name                  = "Blocked_rule_2"
      source_addresses      = ["10.1.0.0/16"]
      destination_addresses = ["10.8.8.8", "8.10.4.4"]
      destination_ports     = [21]
      protocols             = ["TCP"]
    },
    {
      name                  = "Blocked_rule_3"
      source_addresses      = ["10.1.0.0/16"]
      destination_addresses = ["10.8.8.8", "8.10.4.4"]
      destination_ports     = [11]
      protocols             = ["TCP"]
    },
    {
      name                  = "Blocked_rule_4"
      source_addresses      = ["10.1.0.0/16"]
      destination_addresses = ["10.8.8.8", "8.10.4.4"]
      destination_ports     = [21]
      protocols             = ["TCP"]
    }
  ]

  network_rule_coll_name_02     = "Allowed_Network_Rules"
  network_rule_coll_priority_02 = "3000"
  network_rule_coll_action_02   = "Allow"
  network_rules_02 = [
    {
      name                  = "Allowed_Network_rule_1"
      source_addresses      = ["10.1.0.0/16"]
      destination_addresses = ["172.21.1.10", "8.10.4.4"]
      destination_ports     = [11]
      protocols             = ["TCP"]
    },
    {
      name                  = "Allowed_Network_rule_2"
      source_addresses      = ["10.1.0.0/16"]
      destination_addresses = ["172.21.1.10", "8.10.4.4"]
      destination_ports     = [21]
      protocols             = ["TCP"]
    },
    {
      name                  = "Allowed_Network_rule_3"
      source_addresses      = ["10.1.0.0/16"]
      destination_addresses = ["172.21.1.10", "8.10.4.4"]
      destination_ports     = [11]
      protocols             = ["TCP"]
    },
    {
      name                  = "Allowed_Network_rule_4"
      source_addresses      = ["10.1.0.0/16"]
      destination_addresses = ["172.21.1.10", "8.10.4.4"]
      destination_ports     = [21]
      protocols             = ["TCP"]
    }
  ]


  application_rule_coll_name     = "Allowed_websites"
  application_rule_coll_priority = "4000"
  application_rule_coll_action   = "Allow"
  application_rules = [
    {
      name              = "Allowed_website_01"
      source_addresses  = ["*"]
      destination_fqdns = ["bing.co.uk"]
    },
    {
      name              = "Allowed_website_02"
      source_addresses  = ["*"]
      destination_fqdns = ["*.bing.com"]
    }
  ]
  application_protocols = [
    {
      type = "Http"
      port = 80
    },
    {
      type = "Https"
      port = 443
    }
  ]
  dnat_rule_coll_name     = "DNATCollection"
  dnat_rule_coll_priority = "1000"
  dnat_rule_coll_action   = "Dnat"
  dnat_rules = [
    {
      name                = "DNATRuleRDP"
      protocols           = ["TCP"]
      source_addresses    = ["*"]
      destination_address = module.public_ip_03.public_ip_address
      destination_ports   = ["10"] #3389 if you need RDP
      translated_address  = "10.21.4.4"
      translated_port     = "10" #3389 if you need RDP



    },

  ]
}





#######################################################################################################################################################################################################
#
# vm-windows Module is used to create Windows Desktop Virtual Machines
# Uncomment this line to delete the OS disk automatically when deleting the VM
#
########################################################################################################################################################################################################

module "vm-jumpbox-01" {
  source                        = "./modules/vm-windows"
  virtual_machine_name          = "aznetbrjump01"
  nic_name                      = "aznetbrjump01-nic"
  location                      = module.mgmt-resourcegroup_01.rg_location
  resource_group_name           = module.mgmt-resourcegroup_01.rg_name
  ipconfig_name                 = "ipconfig1"
  subnet_id                     = module.hub-vnet.vnet_subnet_id[4]
  private_ip_address_allocation = "Dynamic"
  private_ip_address            = ""
  vm_size                       = "Standard_D2s_v3"

  delete_os_disk_on_termination = true

  delete_data_disks_on_termination = true

  publisher       = "MicrosoftWindowsDesktop"
  offer           = "windows-11"
  sku             = "win11-22h2-pro"
  storage_version = "latest"

  os_disk_name      = "aznetbrjump01osdisk"
  caching           = "ReadWrite"
  create_option     = "FromImage"
  managed_disk_type = "Premium_LRS"

  admin_username = "netb.admin" #this should be put into keyvualt
  admin_password = "Password1234!"

  provision_vm_agent = true
  depends_on         = [module.spoke1-vnet]
}

# bastion Module is used to create Bastion in Hub Virtual Network - To Console into Virtual Machines Securely
module "vm-bastion" {
  source = "./modules/bastion"

  bastion_host_name   = "Hub-eastus2-jmp-bastion"
  resource_group_name = module.hub-resourcegroup.rg_name
  location            = module.hub-resourcegroup.rg_location

  ipconfig_name        = "configuration"
  subnet_id            = module.hub-vnet.vnet_subnet_id[1]
  public_ip_address_id = module.public_ip_04.public_ip_address_id

  depends_on = [module.hub-vnet, module.azure_firewall_01, module.vm-jumpbox-01]
}
