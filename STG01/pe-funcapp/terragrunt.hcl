# STG01 / pe-funcapp
# Private endpoint for primary Function App
include "root" {
  path = find_in_parent_folders()
}

include "env" {
  path           = "${get_terragrunt_dir()}/../../_envcommon/private-endpoint.hcl"
  merge_strategy = "deep"
}

locals {
  env_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
}

dependency "networking" {
  config_path = "../networking"
}

dependency "function_app" {
  config_path = "../function-app"
}

inputs = {
  name                           = "pe-func-${local.env_vars.locals.name_prefix}-${local.env_vars.locals.primary_short}"
  location                       = local.env_vars.locals.primary_location
  resource_group_name            = dependency.networking.outputs.resource_group_name
  subnet_id                      = dependency.networking.outputs.subnet_ids["snet-pe"]
  private_connection_resource_id = dependency.function_app.outputs.function_app_id
  subresource_names              = ["sites"]
  private_dns_zone_ids           = [dependency.networking.outputs.private_dns_zone_ids["sites"]]
}
