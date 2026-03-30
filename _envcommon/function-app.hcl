# -----------------------------------------------------
# Common: Function App
# .NET 8 Isolated, Elastic Premium
# -----------------------------------------------------
terraform {
  source = "git::https://github.com/DeepMalh44/radshow-def.git//modules/function-app?ref=${local.env_vars.locals.environment == "PRD01" ? "v1.0.0" : "main"}"
}

locals {
  env_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
}

inputs = {
  os_type                                 = "Linux"
  dotnet_version                          = "8.0"
  use_dotnet_isolated_runtime             = true
  always_on                               = true
  health_check_path                       = "/api/healthz"
  identity_type                           = "SystemAssigned"
  container_registry_use_managed_identity = true
  enable_diagnostics                      = true
}
