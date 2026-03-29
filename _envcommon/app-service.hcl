# -----------------------------------------------------
# Common: App Service
# .NET 8 Linux, staging slot for blue-green
# -----------------------------------------------------
terraform {
  source = "git::https://github.com/DeepMalh44/radshow-def.git//modules/app-service?ref=${local.env_vars.locals.environment == "PRD01" ? "v1.0.0" : "main"}"
}

locals {
  env_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
}

inputs = {
  os_type            = "Linux"
  dotnet_version     = "8.0"
  always_on          = true
  health_check_path  = "/healthz"
  identity_type      = "SystemAssigned"
  enable_slot        = true
  slot_name          = "staging"
  enable_diagnostics = true
}
