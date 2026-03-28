# STG01 / key-vault-secondary
include "root" {
  path = find_in_parent_folders()
}

include "env" {
  path           = "${get_terragrunt_dir()}/../../_envcommon/key-vault.hcl"
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
  name                       = "kv-${local.env_vars.locals.name_prefix}-sec"
  resource_group_name        = dependency.resource_group_secondary.outputs.name
  location                   = local.env_vars.locals.secondary_location
  tenant_id                  = local.env_vars.locals.tenant_id
  log_analytics_workspace_id = dependency.monitoring.outputs.log_analytics_workspace_id
}
