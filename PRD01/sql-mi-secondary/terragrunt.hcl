# PRD01 / sql-mi-secondary
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
  name                         = "sqlmi-${local.env_vars.locals.name_prefix}-${local.env_vars.locals.secondary_short}"
  resource_group_name          = dependency.resource_group_secondary.outputs.name
  location                     = local.env_vars.locals.secondary_location
  subnet_id                    = dependency.networking_secondary.outputs.subnet_ids["snet-sqlmi"]
  entra_only_auth              = true
  entra_admin_login            = "sp-radshow-cicd"
  entra_admin_object_id        = "6952ac03-12b8-4bd2-8697-9b624583b14f"
  entra_admin_tenant_id        = local.env_vars.locals.tenant_id
  entra_admin_principal_type   = "Application"
  vcores                       = local.env_vars.locals.sql_mi_vcores
  storage_size_in_gb           = local.env_vars.locals.sql_mi_storage_gb
  enable_failover_group = false
}
