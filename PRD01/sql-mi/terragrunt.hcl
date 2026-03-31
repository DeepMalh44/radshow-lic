# PRD01 / sql-mi
include "root" {
  path = find_in_parent_folders()
}

include "env" {
  path           = "${get_terragrunt_dir()}/../../_envcommon/sql-mi.hcl"
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

dependency "sql_mi_secondary" {
  config_path = "../sql-mi-secondary"

  mock_outputs = {
    id   = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/mock-rg/providers/Microsoft.Sql/managedInstances/mock-sqlmi"
    name = "mock-sqlmi"
    fqdn = "mock-sqlmi.database.windows.net"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

inputs = {
  name                         = "sqlmi-${local.env_vars.locals.name_prefix}-${local.env_vars.locals.primary_short}"
  resource_group_name          = dependency.resource_group.outputs.name
  location                     = dependency.resource_group.outputs.location
  subnet_id                    = dependency.networking.outputs.subnet_ids["snet-sqlmi"]
  administrator_login          = "sqladmin"
  administrator_login_password = "REPLACE_VIA_CI_CD_SECRET"
  vcores                       = local.env_vars.locals.sql_mi_vcores
  storage_size_in_gb           = local.env_vars.locals.sql_mi_storage_gb
  log_analytics_workspace_id   = dependency.monitoring.outputs.log_analytics_workspace_id
  enable_failover_group        = local.env_vars.locals.enable_dr
  failover_group_name          = "fog-${local.env_vars.locals.name_prefix}"
  secondary_instance_id        = dependency.sql_mi_secondary.outputs.id
}
