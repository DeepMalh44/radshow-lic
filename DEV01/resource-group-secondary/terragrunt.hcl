# DEV01 / resource-group-secondary
# Secondary region resource group (only deployed when DR is enabled in future)
include "root" {
  path = find_in_parent_folders()
}

include "env" {
  path           = "${get_terragrunt_dir()}/../../_envcommon/resource-group.hcl"
  merge_strategy = "deep"
}

locals {
  env_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
}

inputs = {
  name     = "rg-${local.env_vars.locals.name_prefix}-${local.env_vars.locals.secondary_short}"
  location = local.env_vars.locals.secondary_location
}
