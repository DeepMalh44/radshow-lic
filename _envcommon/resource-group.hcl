# -----------------------------------------------------
# Common: Resource Group
# Shared module configuration inherited by all environments
# -----------------------------------------------------
terraform {
  source = "git::https://github.com/DeepMalh44/radshow-def.git//modules/resource-group?ref=${local.env_vars.locals.environment == "PRD01" ? "v1.0.0" : "main"}"
}

locals {
  env_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  env      = local.env_vars.locals.environment
  prefix   = local.env_vars.locals.name_prefix
}

inputs = {
  enable_delete_lock = local.env_vars.locals.enable_delete_lock
}
