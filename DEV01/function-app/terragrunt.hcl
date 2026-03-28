# DEV01 / function-app
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

dependency "resource_group" {
  config_path = "../resource-group"
}

dependency "networking" {
  config_path = "../networking"
}

dependency "monitoring" {
  config_path = "../monitoring"
}

dependency "storage" {
  config_path = "../storage"
}

inputs = {
  name                          = "func-${local.env_vars.locals.name_prefix}"
  resource_group_name           = dependency.resource_group.outputs.name
  location                      = dependency.resource_group.outputs.location
  service_plan_name             = "asp-func-${local.env_vars.locals.name_prefix}"
  service_plan_sku_name         = local.env_vars.locals.function_app_sku
  storage_account_name          = dependency.storage.outputs.name
  storage_account_access_key    = dependency.storage.outputs.primary_access_key
  vnet_integration_subnet_id    = dependency.networking.outputs.subnet_ids["snet-func"]
  log_analytics_workspace_id    = dependency.monitoring.outputs.log_analytics_workspace_id
  application_insights_connection_string = dependency.monitoring.outputs.app_insights_connection_string
}
