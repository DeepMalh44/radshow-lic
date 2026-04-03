# STG01 / sql-mi-fog
# Failover group — depends on both primary and secondary SQL MI
include "root" {
  path = find_in_parent_folders()
}

include "env" {
  path           = "${get_terragrunt_dir()}/../../_envcommon/sql-mi-fog.hcl"
  merge_strategy = "deep"
}

locals {
  env_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
}

dependency "resource_group" {
  config_path = "../resource-group"
}

dependency "sql_mi_primary" {
  config_path = "../sql-mi"
}

dependency "sql_mi_secondary" {
  config_path = "../sql-mi-secondary"
}

inputs = {
  failover_group_name   = "fog-${local.env_vars.locals.name_prefix}"
  location              = dependency.resource_group.outputs.location
  primary_instance_id   = dependency.sql_mi_primary.outputs.id
  secondary_instance_id = dependency.sql_mi_secondary.outputs.id
  primary_instance_fqdn = dependency.sql_mi_primary.outputs.fqdn
}
