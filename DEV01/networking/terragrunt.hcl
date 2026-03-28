# DEV01 / networking
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

inputs = {
  resource_group_name = dependency.resource_group.outputs.name
  location            = local.env_vars.locals.primary_location
  vnet_name           = "vnet-${local.env_vars.locals.name_prefix}-${local.env_vars.locals.primary_short}"
  address_space       = ["10.0.0.0/16"]

  subnets = {
    "snet-apim" = {
      address_prefixes  = ["10.0.1.0/24"]
      service_endpoints = ["Microsoft.Web"]
    }
    "snet-app" = {
      address_prefixes = ["10.0.2.0/24"]
      delegation = {
        name    = "Microsoft.Web/serverFarms"
        actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
      }
    }
    "snet-func" = {
      address_prefixes = ["10.0.3.0/24"]
      delegation = {
        name    = "Microsoft.Web/serverFarms"
        actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
      }
    }
    "snet-aca" = {
      address_prefixes = ["10.0.4.0/23"]
      delegation = {
        name    = "Microsoft.App/environments"
        actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
      }
    }
    "snet-pe" = {
      address_prefixes = ["10.0.6.0/24"]
    }
    "snet-sqlmi" = {
      address_prefixes = ["10.0.8.0/24"]
      is_sqlmi_subnet  = true
      delegation = {
        name    = "Microsoft.Sql/managedInstances"
        actions = ["Microsoft.Network/virtualNetworks/subnets/join/action", "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action", "Microsoft.Network/virtualNetworks/subnets/unprepareNetworkPolicies/action"]
      }
    }
    "snet-redis" = {
      address_prefixes = ["10.0.9.0/24"]
    }
  }
}
