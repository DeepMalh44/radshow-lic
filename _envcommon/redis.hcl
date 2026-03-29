# -----------------------------------------------------
# Common: Redis Cache
# Premium with geo-replication for DR
# -----------------------------------------------------
terraform {
  source = "git::https://github.com/DeepMalh44/radshow-def.git//modules/redis?ref=${include.root.locals.env_vars.locals.environment == "PRD01" ? "v1.0.0" : "main"}"
}

locals {
  env_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
}

inputs = {
  family               = "P"
  sku_name             = "Premium"
  non_ssl_port_enabled = false
  minimum_tls_version  = "1.2"
  replicas_per_primary = 1
  enable_diagnostics   = true

  redis_configuration = {
    maxmemory_policy = "volatile-lru"
  }
}
