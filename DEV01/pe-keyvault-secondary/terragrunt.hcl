# DEV01 / pe-keyvault-secondary
# Private endpoint for secondary Key Vault
include "root" {
  path = find_in_parent_folders()
}

include "env" {
  path           = "${get_terragrunt_dir()}/../../_envcommon/private-endpoint.hcl"
  merge_strategy = "deep"
}

locals {
  env_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
}

dependency "networking" {
  config_path = "../networking"
}

dependency "networking_secondary" {
  config_path = "../networking-secondary"
}

dependency "key_vault_secondary" {
  config_path = "../key-vault-secondary"
}

inputs = {
  name                           = "pe-kv-${local.env_vars.locals.name_prefix}-${local.env_vars.locals.secondary_short}"
  location                       = local.env_vars.locals.secondary_location
  resource_group_name            = "rg-${local.env_vars.locals.name_prefix}-${local.env_vars.locals.secondary_short}"
  subnet_id                      = dependency.networking_secondary.outputs.subnet_ids["snet-pe"]
  private_connection_resource_id = dependency.key_vault_secondary.outputs.id
  subresource_names              = ["vault"]
  private_dns_zone_ids           = [dependency.networking.outputs.private_dns_zone_ids["vault"]]
}
