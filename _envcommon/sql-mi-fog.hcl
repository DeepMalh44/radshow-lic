# -----------------------------------------------------
# Common: SQL MI Failover Group
# Standalone module to avoid circular dependency
# -----------------------------------------------------
terraform {
  source = "git::https://github.com/DeepMalh44/radshow-def.git//modules/sql-mi-fog?ref=${local.env_vars.locals.environment == "PRD01" ? "v1.0.0" : "main"}"
}

locals {
  env_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
}

inputs = {
  failover_grace_minutes = 60
}
