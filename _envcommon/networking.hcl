# -----------------------------------------------------
# Common: Networking
# VNet, Subnets, NSGs, Private DNS Zones
# -----------------------------------------------------
terraform {
  source = "git::https://github.com/DeepMalh44/radshow-def.git//modules/networking?ref=${include.root.locals.env_vars.locals.environment == "PRD01" ? "v1.0.0" : "main"}"
}

locals {
  env_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
}

inputs = {
  enable_private_dns_zones = true

  private_dns_zones = {
    blob      = "privatelink.blob.core.windows.net"
    vault     = "privatelink.vaultcore.azure.net"
    redis     = "privatelink.redis.cache.windows.net"
    sql       = "privatelink.database.windows.net"
    acr       = "privatelink.azurecr.io"
    sites     = "privatelink.azurewebsites.net"
    servicebus = "privatelink.servicebus.windows.net"
  }
}
