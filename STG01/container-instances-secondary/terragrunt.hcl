# STG01 / container-instances-secondary
# Secondary region ACI for DR
include "root" {
  path = find_in_parent_folders()
}

include "env" {
  path           = "${get_terragrunt_dir()}/../../_envcommon/container-instances.hcl"
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

inputs = {
  name                = "aci-${local.env_vars.locals.name_prefix}-${local.env_vars.locals.secondary_short}"
  resource_group_name = dependency.resource_group_secondary.outputs.name
  location            = local.env_vars.locals.secondary_location
  subnet_ids          = [dependency.networking_secondary.outputs.subnet_ids["snet-aci"]]
  containers          = [] # Containers defined at deployment time
}
