# -----------------------------------------------------
# Common: Private Endpoint
# Reusable PE configuration for PaaS services
# Each invocation creates one PE + DNS zone group
# -----------------------------------------------------
terraform {
  source = "git::https://github.com/DeepMalh44/radshow-def.git//modules/private-endpoint?ref=${local.env_vars.locals.environment == "PRD01" ? "v1.0.0" : "main"}"
}

locals {
  env_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
}

inputs = {
  is_manual_connection        = false
  private_dns_zone_group_name = "default"
}
