# STG01 / sql-mi (primary)
# FOG moved to sql-mi-fog to break circular dependency with dnsZonePartner
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

inputs = {
  name                       = "sqlmi-${local.env_vars.locals.name_prefix}-${local.env_vars.locals.primary_short}"
  resource_group_name        = dependency.resource_group.outputs.name
  location                   = dependency.resource_group.outputs.location
  subnet_id                  = dependency.networking.outputs.subnet_ids["snet-sqlmi"]
  entra_only_auth            = true
  entra_admin_login          = "sg-radshow-sqladmin"
  entra_admin_object_id      = "1e808511-e2db-42a4-9fcb-fb4ded6f4989"
  entra_admin_tenant_id      = local.env_vars.locals.tenant_id
  public_data_endpoint_enabled = true  # CI/CD access from GitHub runners
  vcores                     = local.env_vars.locals.sql_mi_vcores
  storage_size_in_gb         = local.env_vars.locals.sql_mi_storage_gb
  log_analytics_workspace_id = dependency.monitoring.outputs.log_analytics_workspace_id
  enable_failover_group      = false
}
