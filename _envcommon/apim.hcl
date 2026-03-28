# -----------------------------------------------------
# Common: APIM
# Premium Classic, multi-region with gateway in secondary
# -----------------------------------------------------
terraform {
  source = "git::https://github.com/DeepMalh44/radshow-def.git//modules/apim?ref=${include.root.locals.env_vars.locals.environment == "PRD01" ? "v1.0.0" : "main"}"
}

locals {
  env_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
}

inputs = {
  sku_name             = "Premium"
  virtual_network_type = "Internal"
  enable_http2         = true
  sign_up_enabled      = false
  enable_diagnostics   = true
}
