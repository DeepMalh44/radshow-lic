# STG01 / vnet-peering
# Bidirectional peering between primary (SCUS) and secondary (NCUS) VNets
include "root" {
  path = find_in_parent_folders()
}

include "env" {
  path           = "${get_terragrunt_dir()}/../../_envcommon/vnet-peering.hcl"
  merge_strategy = "deep"
}

locals {
  env_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
}

dependency "networking" {
  config_path = "../networking"
}

dependency "networking_secondary" {
  config_path = "../networking-secondary"
}

inputs = {
  peering_name_1_to_2        = "peer-${local.env_vars.locals.primary_short}-to-${local.env_vars.locals.secondary_short}"
  peering_name_2_to_1        = "peer-${local.env_vars.locals.secondary_short}-to-${local.env_vars.locals.primary_short}"
  vnet_1_id                  = dependency.networking.outputs.vnet_id
  vnet_1_name                = dependency.networking.outputs.vnet_name
  vnet_1_resource_group_name = dependency.networking.outputs.resource_group_name
  vnet_2_id                  = dependency.networking_secondary.outputs.vnet_id
  vnet_2_name                = dependency.networking_secondary.outputs.vnet_name
  vnet_2_resource_group_name = dependency.networking_secondary.outputs.resource_group_name
}
