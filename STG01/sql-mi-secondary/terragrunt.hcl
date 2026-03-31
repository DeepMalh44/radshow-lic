# STG01 / sql-mi-secondary
# Secondary region SQL Managed Instance for failover group
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
  name                       = "sqlmi-${local.env_vars.locals.name_prefix}-${local.env_vars.locals.secondary_short}"
  resource_group_name        = dependency.resource_group_secondary.outputs.name
  location                   = local.env_vars.locals.secondary_location
  subnet_id                  = dependency.networking_secondary.outputs.subnet_ids["snet-sqlmi"]
  entra_only_auth            = true
  entra_admin_login          = "admin@MngEnvMCAP245137.onmicrosoft.com"
  entra_admin_object_id      = "941f59fd-aeb5-4ba2-9fb9-2f5132d15500"
  entra_admin_tenant_id      = local.env_vars.locals.tenant_id
  vcores                     = local.env_vars.locals.sql_mi_vcores
  storage_size_in_gb         = local.env_vars.locals.sql_mi_storage_gb
  log_analytics_workspace_id = dependency.monitoring.outputs.log_analytics_workspace_id

  # Failover group is created by the PRIMARY instance, not the secondary
  enable_failover_group = false
}
