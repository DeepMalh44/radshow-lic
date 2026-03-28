# PRD01 / redis-secondary
# Secondary region Redis Cache for geo-replication
include "root" {
  path = find_in_parent_folders()
}

include "env" {
  path           = "${get_terragrunt_dir()}/../../_envcommon/redis.hcl"
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

inputs = {
  name                       = "redis-${local.env_vars.locals.name_prefix}-${local.env_vars.locals.secondary_short}"
  resource_group_name        = dependency.resource_group_secondary.outputs.name
  location                   = local.env_vars.locals.secondary_location
  capacity                   = local.env_vars.locals.redis_capacity
  subnet_id                  = dependency.networking_secondary.outputs.subnet_ids["snet-redis"]
  log_analytics_workspace_id = dependency.monitoring.outputs.log_analytics_workspace_id

  # Geo-replication link is created by the PRIMARY cache, not the secondary
  enable_geo_replication = false
}
