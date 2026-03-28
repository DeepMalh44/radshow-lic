# -----------------------------------------------------
# Common: SQL Managed Instance
# GP_Gen5, failover group with 5-min grace period
# -----------------------------------------------------
terraform {
  source = "git::https://github.com/DeepMalh44/radshow-def.git//modules/sql-mi?ref=${include.root.locals.env_vars.locals.environment == "PRD01" ? "v1.0.0" : "main"}"
}

locals {
  env_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
}

inputs = {
  sku_name                    = "GP_Gen5"
  license_type                = "BasePrice"
  timezone_id                 = "UTC"
  collation                   = "SQL_Latin1_General_CP1_CI_AS"
  minimum_tls_version         = "1.2"
  public_data_endpoint_enabled = false
  proxy_override              = "Redirect"
  identity_type               = "SystemAssigned"
  failover_grace_minutes      = 5  # Tier 1: RPO ≤ 5 min
  enable_diagnostics          = true
}
