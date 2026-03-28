# STG01 / container-instances
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

dependency "resource_group" {
  config_path = "../resource-group"
}

dependency "networking" {
  config_path = "../networking"
}

inputs = {
  name                = "aci-${local.env_vars.locals.name_prefix}"
  resource_group_name = dependency.resource_group.outputs.name
  location            = dependency.resource_group.outputs.location
  subnet_ids          = [dependency.networking.outputs.subnet_ids["snet-pe"]]
  containers          = [] # Containers defined at deployment time
}
