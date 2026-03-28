# PRD01 / function-app-secondary
# Secondary region Function App for DR
include "root" {
  path = find_in_parent_folders()
}

include "env" {
  path           = "${get_terragrunt_dir()}/../../_envcommon/function-app.hcl"
  merge_strategy = "deep"
}

locals {
  env_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
}

dependency "resource_group_secondary" {
  config_path = "../resource-group-secondary"
}

dependency "networking_secondary" {
  config_path = "../networking-secondary"
}

dependency "monitoring" {
  config_path = "../monitoring"
}

dependency "storage_secondary" {
  config_path = "../storage-secondary"
}

inputs = {
  name                          = "func-${local.env_vars.locals.name_prefix}-${local.env_vars.locals.secondary_short}"
  resource_group_name           = dependency.resource_group_secondary.outputs.name
  location                      = local.env_vars.locals.secondary_location
  service_plan_name             = "asp-func-${local.env_vars.locals.name_prefix}-${local.env_vars.locals.secondary_short}"
  service_plan_sku_name         = local.env_vars.locals.function_app_sku
  storage_account_name          = dependency.storage_secondary.outputs.name
  storage_account_access_key    = dependency.storage_secondary.outputs.primary_access_key
  vnet_integration_subnet_id    = dependency.networking_secondary.outputs.subnet_ids["snet-func"]
  log_analytics_workspace_id    = dependency.monitoring.outputs.log_analytics_workspace_id
  application_insights_connection_string = dependency.monitoring.outputs.secondary_app_insights_connection_string
}
