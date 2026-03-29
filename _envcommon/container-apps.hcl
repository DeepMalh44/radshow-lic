# -----------------------------------------------------
# Common: Container Apps
# ACA Environment + Container Apps
# -----------------------------------------------------
terraform {
  source = "git::https://github.com/DeepMalh44/radshow-def.git//modules/container-apps?ref=${local.env_vars.locals.environment == "PRD01" ? "v1.0.0" : "main"}"
}

locals {
  env_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
}

inputs = {
  internal_load_balancer_enabled = true
  zone_redundancy_enabled        = local.env_vars.locals.environment == "PRD01" ? true : false
}
