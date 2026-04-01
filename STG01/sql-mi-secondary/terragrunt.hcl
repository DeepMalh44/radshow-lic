# STG01 / sql-mi-secondary
# Secondary region SQL Managed Instance — uses dnsZonePartner from primary
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

dependency "sql_mi_primary" {
  config_path = "../sql-mi"

  mock_outputs = {
    id   = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/mock-rg/providers/Microsoft.Sql/managedInstances/mock-sqlmi-primary"
    name = "mock-sqlmi-primary"
    fqdn = "mock-sqlmi-primary.database.windows.net"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

inputs = {
  name                       = "sqlmi-${local.env_vars.locals.name_prefix}-${local.env_vars.locals.secondary_short}"
  resource_group_name        = dependency.resource_group_secondary.outputs.name
  location                   = local.env_vars.locals.secondary_location
  subnet_id                  = dependency.networking_secondary.outputs.subnet_ids["snet-sqlmi"]
  entra_only_auth            = true
  entra_admin_login          = "sg-radshow-sqladmin"
  entra_admin_object_id      = "1e808511-e2db-42a4-9fcb-fb4ded6f4989"
  entra_admin_tenant_id      = local.env_vars.locals.tenant_id
  vcores                     = local.env_vars.locals.sql_mi_vcores
  storage_size_in_gb         = local.env_vars.locals.sql_mi_storage_gb
  log_analytics_workspace_id = dependency.monitoring.outputs.log_analytics_workspace_id
  dns_zone_partner_id        = dependency.sql_mi_primary.outputs.id

  # Failover group is created by sql-mi-fog, not here
  enable_failover_group = false
}
