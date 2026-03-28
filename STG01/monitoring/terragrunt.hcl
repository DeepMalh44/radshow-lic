# STG01 / monitoring
include "root" {
  path = find_in_parent_folders()
}

include "env" {
  path           = "${get_terragrunt_dir()}/../../_envcommon/monitoring.hcl"
  merge_strategy = "deep"
}

locals {
  env_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
}

dependency "resource_group" {
  config_path = "../resource-group"
}

inputs = {
  resource_group_name          = dependency.resource_group.outputs.name
  location                     = dependency.resource_group.outputs.location
  log_analytics_workspace_name = "log-${local.env_vars.locals.name_prefix}"
  app_insights_name            = "appi-${local.env_vars.locals.name_prefix}"
}
