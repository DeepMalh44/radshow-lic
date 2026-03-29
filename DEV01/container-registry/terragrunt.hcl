# DEV01 / container-registry
include "root" {
  path = find_in_parent_folders()
}

include "env" {
  path           = "${get_terragrunt_dir()}/../../_envcommon/container-registry.hcl"
  merge_strategy = "deep"
}

locals {
  env_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
}

dependency "resource_group" {
  config_path = "../resource-group"

  mock_outputs = { name = "mock-rg", location = "swedencentral" }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

dependency "monitoring" {
  config_path = "../monitoring"


  mock_outputs = {
    log_analytics_workspace_id    = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/mock-rg/providers/Microsoft.OperationalInsights/workspaces/mock-la"
    app_insights_connection_string = "InstrumentationKey=00000000-0000-0000-0000-000000000000"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

inputs = {
  name                       = "acr${replace(local.env_vars.locals.name_prefix, "-", "")}"
  resource_group_name        = dependency.resource_group.outputs.name
  location                   = dependency.resource_group.outputs.location
  log_analytics_workspace_id = dependency.monitoring.outputs.log_analytics_workspace_id
  georeplications            = local.env_vars.locals.enable_geo_replication ? [{
    location                  = local.env_vars.locals.secondary_location
    zone_redundancy_enabled   = false
    regional_endpoint_enabled = true
  }] : []
}
