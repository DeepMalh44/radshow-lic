# DEV01 / storage-secondary
# Secondary region storage account with $web for SPA failover
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

  mock_outputs = { name = "mock-rg-secondary", location = "northcentralus" }
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
  name                       = "st${replace(local.env_vars.locals.name_prefix, "-", "")}${local.env_vars.locals.secondary_short}"
  resource_group_name        = dependency.resource_group_secondary.outputs.name
  location                   = local.env_vars.locals.secondary_location
  account_replication_type   = "LRS"
  log_analytics_workspace_id = dependency.monitoring.outputs.log_analytics_workspace_id
}
