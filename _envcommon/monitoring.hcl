# -----------------------------------------------------
# Common: Monitoring
# Log Analytics + App Insights + DR Alerts
# -----------------------------------------------------
terraform {
  source = "git::https://github.com/DeepMalh44/radshow-def.git//modules/monitoring?ref=${local.env_vars.locals.environment == "PRD01" ? "v1.0.0" : "main"}"
}

locals {
  env_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
}

inputs = {
  log_analytics_sku            = "PerGB2018"
  retention_in_days            = local.env_vars.locals.environment == "PRD01" ? 90 : 30
  app_insights_application_type = "web"
  enable_dr_alerts             = local.env_vars.locals.enable_dr
}
