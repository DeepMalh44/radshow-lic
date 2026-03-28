# STG01 / networking-secondary
# Secondary region VNet (10.2.0.0/16) — mirrors primary subnet layout
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

dependency "resource_group_secondary" {
  config_path = "../resource-group-secondary"
}

inputs = {
  resource_group_name      = dependency.resource_group_secondary.outputs.name
  location                 = local.env_vars.locals.secondary_location
  vnet_name                = "vnet-${local.env_vars.locals.name_prefix}-${local.env_vars.locals.secondary_short}"
  address_space            = ["10.2.0.0/16"]
  enable_private_dns_zones = false  # DNS zones centralized in primary

  subnets = {
    "snet-apim" = {
      address_prefixes  = ["10.2.1.0/24"]
      service_endpoints = ["Microsoft.Web"]
    }
    "snet-app" = {
      address_prefixes = ["10.2.2.0/24"]
      delegation = {
        name    = "Microsoft.Web/serverFarms"
        actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
      }
    }
    "snet-func" = {
      address_prefixes = ["10.2.3.0/24"]
      delegation = {
        name    = "Microsoft.Web/serverFarms"
        actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
      }
    }
    "snet-aca" = {
      address_prefixes = ["10.2.4.0/23"]
      delegation = {
        name    = "Microsoft.App/environments"
        actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
      }
    }
    "snet-pe" = {
      address_prefixes = ["10.2.6.0/24"]
    }
    "snet-sqlmi" = {
      address_prefixes = ["10.2.8.0/24"]
      is_sqlmi_subnet  = true
      delegation = {
        name    = "Microsoft.Sql/managedInstances"
        actions = ["Microsoft.Network/virtualNetworks/subnets/join/action", "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action", "Microsoft.Network/virtualNetworks/subnets/unprepareNetworkPolicies/action"]
      }
    }
    "snet-redis" = {
      address_prefixes = ["10.2.9.0/24"]
    }
  }
}
