# PRD01 / pe-acr-secondary
# Private endpoint for ACR in secondary region VNet
# ACR is a single resource with geo-replication; this PE enables
# private pulls from the secondary region's replica endpoint
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

dependency "networking_secondary" {
  config_path = "../networking-secondary"
}

dependency "container_registry" {
  config_path = "../container-registry"
}

inputs = {
  name                           = "pe-acr-${local.env_vars.locals.name_prefix}-${local.env_vars.locals.secondary_short}"
  location                       = local.env_vars.locals.secondary_location
  resource_group_name            = dependency.networking_secondary.outputs.resource_group_name
  subnet_id                      = dependency.networking_secondary.outputs.subnet_ids["snet-pe"]
  private_connection_resource_id = dependency.container_registry.outputs.id
  subresource_names              = ["registry"]
  private_dns_zone_ids           = [dependency.networking.outputs.private_dns_zone_ids["acr"]]
}
