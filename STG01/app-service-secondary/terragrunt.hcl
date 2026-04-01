# STG01 / app-service-secondary
# Secondary region App Service for DR
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

dependency "resource_group_secondary" {
  config_path = "../resource-group-secondary"
}

dependency "networking_secondary" {
  config_path = "../networking-secondary"
}

dependency "monitoring" {
  config_path = "../monitoring"
}

inputs = {
  name                          = "app-${local.env_vars.locals.name_prefix}-${local.env_vars.locals.secondary_short}"
  resource_group_name           = dependency.resource_group_secondary.outputs.name
  location                      = local.env_vars.locals.secondary_location
  service_plan_name             = "asp-${local.env_vars.locals.name_prefix}-${local.env_vars.locals.secondary_short}"
  service_plan_sku_name         = local.env_vars.locals.app_service_sku  # South India has Standard VM quota
  vnet_integration_subnet_id    = dependency.networking_secondary.outputs.subnet_ids["snet-app"]
  log_analytics_workspace_id    = dependency.monitoring.outputs.log_analytics_workspace_id

  app_settings = {
    "APPLICATIONINSIGHTS_CONNECTION_STRING" = dependency.monitoring.outputs.secondary_app_insights_connection_string
  }
}
