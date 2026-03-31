# STG01 / sql-mi
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
  name                       = "sqlmi-${local.env_vars.locals.name_prefix}"
  resource_group_name        = dependency.resource_group.outputs.name
  location                   = dependency.resource_group.outputs.location
  subnet_id                  = dependency.networking.outputs.subnet_ids["snet-sqlmi"]
  entra_only_auth            = true
  entra_admin_login          = "admin@MngEnvMCAP245137.onmicrosoft.com"
  entra_admin_object_id      = "941f59fd-aeb5-4ba2-9fb9-2f5132d15500"
  entra_admin_tenant_id      = local.env_vars.locals.tenant_id
  vcores                     = local.env_vars.locals.sql_mi_vcores
  storage_size_in_gb         = local.env_vars.locals.sql_mi_storage_gb
  log_analytics_workspace_id = dependency.monitoring.outputs.log_analytics_workspace_id
  enable_failover_group      = local.env_vars.locals.enable_dr
  failover_group_name        = "fog-${local.env_vars.locals.name_prefix}"
  secondary_instance_id      = dependency.sql_mi_secondary.outputs.id
}
