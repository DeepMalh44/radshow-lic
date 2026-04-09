# STG01 / networking
include "root" {
  path = find_in_parent_folders()
}

include "env" {
  path           = "${get_terragrunt_dir()}/../../_envcommon/networking.hcl"
  merge_strategy = "deep"
}

locals {
  env_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
}

dependency "resource_group" {
  config_path = "../resource-group"
}

dependency "networking_secondary" {
  config_path = "../networking-secondary"

  mock_outputs = {
    vnet_id = "mock-secondary-vnet-id"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
  skip_outputs = !fileexists("${get_terragrunt_dir()}/../networking-secondary/terragrunt.hcl")
}

inputs = {
  resource_group_name = dependency.resource_group.outputs.name
  location            = local.env_vars.locals.primary_location
  vnet_name           = "vnet-${local.env_vars.locals.name_prefix}-${local.env_vars.locals.primary_short}"
  address_space       = ["10.1.0.0/16"]
  secondary_vnet_id   = dependency.networking_secondary.outputs.vnet_id

  enable_sqlmi_public_endpoint = true

  subnets = {
    "snet-apim" = {
      address_prefixes  = ["10.1.1.0/24"]
      service_endpoints = ["Microsoft.Web"]
      is_apim_subnet    = true
    }
    "snet-app" = {
      address_prefixes = ["10.1.2.0/24"]
      delegation = {
        name    = "Microsoft.Web/serverFarms"
        actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
      }
    }
    "snet-func" = {
      address_prefixes = ["10.1.3.0/24"]
      delegation = {
        name    = "Microsoft.Web/serverFarms"
        actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
      }
    }
    "snet-aca" = {
      address_prefixes = ["10.1.4.0/23"]
      delegation = {
        name    = "Microsoft.App/environments"
        actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
      }
    }
    "snet-pe" = {
      address_prefixes = ["10.1.6.0/24"]
    }
    "snet-sqlmi" = {
      address_prefixes = ["10.1.8.0/24"]
      is_sqlmi_subnet  = true
      delegation = {
        name    = "Microsoft.Sql/managedInstances"
        actions = ["Microsoft.Network/virtualNetworks/subnets/join/action", "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action", "Microsoft.Network/virtualNetworks/subnets/unprepareNetworkPolicies/action"]
      }
    }
    "snet-redis" = {
      address_prefixes = ["10.1.9.0/24"]
    }
    "snet-aci" = {
      address_prefixes = ["10.1.7.0/24"]
      delegation = {
        name    = "Microsoft.ContainerInstance/containerGroups"
        actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
      }
    }
    "snet-appgw" = {
      address_prefixes = ["10.1.10.0/24"]
      is_appgw_subnet  = true
    }
  }
}
