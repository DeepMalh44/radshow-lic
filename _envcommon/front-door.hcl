# -----------------------------------------------------
# Common: Front Door
# Active-Passive with WAF (Premium)
# -----------------------------------------------------
terraform {
  source = "git::https://github.com/DeepMalh44/radshow-def.git//modules/front-door?ref=${local.env_vars.locals.environment == "PRD01" ? "v1.0.0" : "main"}"
}

locals {
  env_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
}

inputs = {
  sku_name                 = "Premium_AzureFrontDoor"
  response_timeout_seconds = 60
  enable_waf               = local.env_vars.locals.enable_waf
  waf_mode                 = "Prevention"

  waf_managed_rules = local.env_vars.locals.enable_waf ? [
    {
      type    = "Microsoft_DefaultRuleSet"
      version = "2.1"
      action  = "Block"
    },
    {
      type    = "Microsoft_BotManagerRuleSet"
      version = "1.0"
      action  = "Block"
    }
  ] : []
}
