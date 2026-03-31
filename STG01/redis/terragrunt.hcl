# STG01 / redis
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

dependency "resource_group" {
  config_path = "../resource-group"
}

dependency "networking" {
  config_path = "../networking"
}

dependency "monitoring" {
  config_path = "../monitoring"
}

dependency "redis_secondary" {
  config_path = "../redis-secondary"

  mock_outputs = {
    id       = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/mock-rg/providers/Microsoft.Cache/Redis/mock-redis"
    name     = "mock-redis"
    hostname = "mock-redis.redis.cache.windows.net"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

inputs = {
  name                       = "redis-${local.env_vars.locals.name_prefix}-${local.env_vars.locals.primary_short}"
  resource_group_name        = dependency.resource_group.outputs.name
  location                   = dependency.resource_group.outputs.location
  capacity                   = local.env_vars.locals.redis_capacity
  subnet_id                  = dependency.networking.outputs.subnet_ids["snet-redis"]
  log_analytics_workspace_id = dependency.monitoring.outputs.log_analytics_workspace_id
  enable_geo_replication     = local.env_vars.locals.enable_geo_replication
  linked_cache_id            = dependency.redis_secondary.outputs.id
  linked_cache_location      = local.env_vars.locals.secondary_location
}
