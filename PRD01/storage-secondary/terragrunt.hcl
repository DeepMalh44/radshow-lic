# PRD01 / storage-secondary
include "root" {
  path = find_in_parent_folders()
}

include "env" {
  path           = "${get_terragrunt_dir()}/../../_envcommon/storage.hcl"
  merge_strategy = "deep"
}

locals {
  env_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
}

dependency "resource_group_secondary" {
  config_path = "../resource-group-secondary"
}

dependency "monitoring" {
  config_path = "../monitoring"
}

inputs = {
  name                       = "st${replace(local.env_vars.locals.name_prefix, "-", "")}${local.env_vars.locals.secondary_short}"
  resource_group_name        = dependency.resource_group_secondary.outputs.name
  location                   = local.env_vars.locals.secondary_location
  log_analytics_workspace_id = dependency.monitoring.outputs.log_analytics_workspace_id
}
