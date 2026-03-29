# -----------------------------------------------------
# Common: Key Vault
# RBAC auth, purge protection, private access only
# -----------------------------------------------------
terraform {
  source = "git::https://github.com/DeepMalh44/radshow-def.git//modules/key-vault?ref=${local.env_vars.locals.environment == "PRD01" ? "v1.0.0" : "main"}"
}

locals {
  env_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
}

inputs = {
  sku_name                        = "standard"
  enable_rbac_authorization       = true
  purge_protection_enabled        = true
  soft_delete_retention_days      = 90
  public_network_access_enabled   = false
  enable_diagnostics              = true
}
