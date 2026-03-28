# PRD01 / apim
# Premium Classic with multi-region gateway in secondary
include "root" {
  path = find_in_parent_folders()
}

include "env" {
  path           = "${get_terragrunt_dir()}/../../_envcommon/apim.hcl"
  merge_strategy = "deep"
}

locals {
  env_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
}

dependency "resource_group" {
  config_path = "../resource-group"
}

dependency "networking" {
  config_path = "../networking"
}

dependency "networking_secondary" {
  config_path = "../networking-secondary"

  mock_outputs = {
    subnet_ids = {
      "snet-apim" = "/subscriptions/00000000/resourceGroups/mock/providers/Microsoft.Network/virtualNetworks/mock/subnets/snet-apim"
    }
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

dependency "monitoring" {
  config_path = "../monitoring"
}

inputs = {
  name                       = "apim-${local.env_vars.locals.name_prefix}"
  resource_group_name        = dependency.resource_group.outputs.name
  location                   = dependency.resource_group.outputs.location
  publisher_name             = "RAD Showcase"
  publisher_email            = "radshow-dev@contoso.com"
  sku_capacity               = local.env_vars.locals.apim_sku_capacity
  subnet_id                  = dependency.networking.outputs.subnet_ids["snet-apim"]
  log_analytics_workspace_id = dependency.monitoring.outputs.log_analytics_workspace_id

  additional_locations = local.env_vars.locals.enable_dr ? [{
    location         = local.env_vars.locals.secondary_location
    subnet_id        = dependency.networking_secondary.outputs.subnet_ids["snet-apim"]
    zones            = []
    capacity         = 1
    gateway_disabled = false
  }] : []
}
