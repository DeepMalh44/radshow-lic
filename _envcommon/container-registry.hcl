# -----------------------------------------------------
# Common: Container Registry (ACR)
# Premium with geo-replication for DR
# -----------------------------------------------------
terraform {
  source = "git::https://github.com/DeepMalh44/radshow-def.git//modules/container-registry?ref=${local.env_vars.locals.environment == "PRD01" ? "v1.0.0" : "main"}"
}

locals {
  env_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
}

inputs = {
  sku                           = "Premium"
  admin_enabled                 = false
  public_network_access_enabled = true
  identity_type                 = "SystemAssigned"
  enable_diagnostics            = true
}
