# PRD01 / apim
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
  additional_locations       = [] # Sprint 5: wire secondary region via networking-secondary
}
