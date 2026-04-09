# STG01 / application-gateway-secondary (southindia)
include "root" {
  path = find_in_parent_folders()
}

include "env" {
  path           = "${get_terragrunt_dir()}/../../_envcommon/application-gateway.hcl"
  merge_strategy = "deep"
}

locals {
  env_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
}

dependency "resource_group_secondary" {
  config_path = "../resource-group-secondary"
}

dependency "networking_secondary" {
  config_path = "../networking-secondary"

  mock_outputs = {
    subnet_ids = { "snet-appgw" = "/subscriptions/00000000/resourceGroups/mock/providers/Microsoft.Network/virtualNetworks/mock/subnets/snet-appgw" }
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

dependency "key_vault_secondary" {
  config_path = "../key-vault-secondary"

  mock_outputs = {
    id                    = "/subscriptions/00000000/resourceGroups/mock/providers/Microsoft.KeyVault/vaults/mock-kv"
    appgw_cert_secret_id  = "https://mock-kv.vault.azure.net/secrets/appgw-ssl-cert"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

# NOTE: FD dependency removed to break cycle (AppGW↔FD).
# FD profile already exists; resource_guid is stable.

dependency "apim" {
  config_path = "../apim"

  mock_outputs = {
    gateway_secondary_regional_url = "https://apim-radshow-stg01-cin-southindia-01.regional.azure-api.net"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

dependency "storage_secondary" {
  config_path = "../storage-secondary"

  mock_outputs = {
    primary_web_host = "stradshowstg01sin.z30.web.core.windows.net"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

dependency "monitoring" {
  config_path = "../monitoring"

  mock_outputs = {
    log_analytics_workspace_id = "/subscriptions/00000000/resourceGroups/mock/providers/Microsoft.OperationalInsights/workspaces/mock-la"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

inputs = {
  name                       = "appgw-${local.env_vars.locals.name_prefix}-${local.env_vars.locals.secondary_short}"
  resource_group_name        = dependency.resource_group_secondary.outputs.name
  location                   = local.env_vars.locals.secondary_location
  subnet_id                  = dependency.networking_secondary.outputs.subnet_ids["snet-appgw"]
  key_vault_id               = dependency.key_vault_secondary.outputs.id
  key_vault_secret_id        = dependency.key_vault_secondary.outputs.appgw_cert_secret_id
  front_door_id              = "d6f9998e-db6a-4143-9ba7-71d17c486ece" # afd-radshow-stg01 resource_guid
  apim_fqdn                  = replace(dependency.apim.outputs.gateway_secondary_regional_url, "https://", "")
  storage_web_fqdn           = dependency.storage_secondary.outputs.primary_web_host
  log_analytics_workspace_id = dependency.monitoring.outputs.log_analytics_workspace_id
}
