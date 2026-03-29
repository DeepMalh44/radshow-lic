# -----------------------------------------------------
# Common: Container Instances (ACI)
# Private, Linux containers
# -----------------------------------------------------
terraform {
  source = "git::https://github.com/DeepMalh44/radshow-def.git//modules/container-instances?ref=${local.env_vars.locals.environment == "PRD01" ? "v1.0.0" : "main"}"
}

locals {
  env_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
}

inputs = {
  os_type          = "Linux"
  restart_policy   = "Always"
  ip_address_type  = "Private"
  identity_type    = "SystemAssigned"
}
