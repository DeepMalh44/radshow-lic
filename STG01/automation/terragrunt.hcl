# STG01 / automation
include "root" {
  path = find_in_parent_folders()
}

include "env" {
  path           = "${get_terragrunt_dir()}/../../_envcommon/automation.hcl"
  merge_strategy = "deep"
}

locals {
  env_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
}

dependency "resource_group" {
  config_path = "../resource-group"
}

dependency "monitoring" {
  config_path = "../monitoring"
}

inputs = {
  name                       = "aa-${local.env_vars.locals.name_prefix}-${local.env_vars.locals.primary_short}"
  resource_group_name        = dependency.resource_group.outputs.name
  location                   = dependency.resource_group.outputs.location
  log_analytics_workspace_id = dependency.monitoring.outputs.log_analytics_workspace_id
  enable_dr_runbooks         = true
  runbooks                   = {}
}
