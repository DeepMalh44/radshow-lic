# -----------------------------------------------------
# Common: Automation Account
# DR Runbooks for failover/failback
# -----------------------------------------------------
terraform {
  source = "git::https://github.com/DeepMalh44/radshow-def.git//modules/automation?ref=${include.root.locals.env_vars.locals.environment == "PRD01" ? "v1.0.0" : "main"}"
}

inputs = {
  sku_name           = "Basic"
  identity_type      = "SystemAssigned"
  enable_diagnostics = true
}
