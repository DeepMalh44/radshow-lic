# STG01 / container-apps
include "root" {
  path = find_in_parent_folders()
}

include "env" {
  path           = "${get_terragrunt_dir()}/../../_envcommon/container-apps.hcl"
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
  environment_name       = "cae-${local.env_vars.locals.name_prefix}-${local.env_vars.locals.primary_short}"
  resource_group_name    = dependency.resource_group.outputs.name
  location               = dependency.resource_group.outputs.location
  log_analytics_workspace_id = dependency.monitoring.outputs.log_analytics_workspace_id
  infrastructure_subnet_id   = dependency.networking.outputs.subnet_ids["snet-aca"]
  container_apps         = {} # Apps defined at deployment time
}
