# -----------------------------------------------------
# Common: Automation Account
# DR Runbooks for failover/failback
# -----------------------------------------------------
terraform {
  source = "git::https://github.com/DeepMalh44/radshow-def.git//modules/automation?ref=${local.env_vars.locals.environment == "PRD01" ? "v1.0.0" : "main"}"
}

locals {
  env_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
}

inputs = {
  sku_name           = "Basic"
  identity_type      = "SystemAssigned"
  enable_diagnostics = true
}
