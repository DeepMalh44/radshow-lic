# PRD01 / app-service
include "root" {
  path = find_in_parent_folders()
}

include "env" {
  path           = "${get_terragrunt_dir()}/../../_envcommon/app-service.hcl"
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
  name                          = "app-${local.env_vars.locals.name_prefix}"
  resource_group_name           = dependency.resource_group.outputs.name
  location                      = dependency.resource_group.outputs.location
  service_plan_name             = "asp-${local.env_vars.locals.name_prefix}"
  service_plan_sku_name         = local.env_vars.locals.app_service_sku
  vnet_integration_subnet_id    = dependency.networking.outputs.subnet_ids["snet-app"]
  log_analytics_workspace_id    = dependency.monitoring.outputs.log_analytics_workspace_id

  app_settings = {
    "APPLICATIONINSIGHTS_CONNECTION_STRING" = dependency.monitoring.outputs.app_insights_connection_string
  }
}
