# PRD01 / front-door
include "root" {
  path = find_in_parent_folders()
}

include "env" {
  path           = "${get_terragrunt_dir()}/../../_envcommon/front-door.hcl"
  merge_strategy = "deep"
}

locals {
  env_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
}

dependency "resource_group" {
  config_path = "../resource-group"
}

inputs = {
  profile_name        = "afd-${local.env_vars.locals.name_prefix}"
  resource_group_name = dependency.resource_group.outputs.name
  waf_policy_name     = "wafafd${replace(local.env_vars.locals.name_prefix, "-", "")}"

  origin_groups = {}  # Configured after backend services are deployed
  origins       = {}
  endpoints     = {}
  routes        = {}
}
