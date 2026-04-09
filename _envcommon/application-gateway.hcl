# -----------------------------------------------------
# Common: Application Gateway
# WAF_v2 with URL path routing (FD → AppGW → APIM / SPA)
# -----------------------------------------------------
terraform {
  source = "git::https://github.com/DeepMalh44/radshow-def.git//modules/application-gateway?ref=${local.env_vars.locals.environment == "PRD01" ? "v1.0.0" : "main"}"
}

locals {
  env_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
}

inputs = {
  sku_name     = "WAF_v2"
  sku_tier     = "WAF_v2"
  min_capacity = 1
  max_capacity = 2
  enable_waf   = true
  waf_mode     = "Prevention"
}
