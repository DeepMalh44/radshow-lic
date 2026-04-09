# PRD01 / application-gateway (primary — southcentralus)
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

dependency "resource_group" {
  config_path = "../resource-group"
}

dependency "networking" {
  config_path = "../networking"

  mock_outputs = {
    subnet_ids = { "snet-appgw" = "/subscriptions/00000000/resourceGroups/mock/providers/Microsoft.Network/virtualNetworks/mock/subnets/snet-appgw" }
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

dependency "key_vault" {
  config_path = "../key-vault"

  mock_outputs = {
    id                    = "/subscriptions/00000000/resourceGroups/mock/providers/Microsoft.KeyVault/vaults/mock-kv"
    appgw_cert_secret_id  = "https://mock-kv.vault.azure.net/secrets/appgw-ssl-cert"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

dependency "front_door" {
  config_path = "../front-door"

  mock_outputs = {
    front_door_id = "00000000-0000-0000-0000-000000000000"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

dependency "apim" {
  config_path = "../apim"

  mock_outputs = {
    gateway_url = "https://apim-radshow-prd01-scus.azure-api.net"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

dependency "storage" {
  config_path = "../storage"

  mock_outputs = {
    primary_web_host = "stradshowprd01scus.z21.web.core.windows.net"
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
  name                       = "appgw-${local.env_vars.locals.name_prefix}-${local.env_vars.locals.primary_short}"
  resource_group_name        = dependency.resource_group.outputs.name
  location                   = local.env_vars.locals.primary_location
  subnet_id                  = dependency.networking.outputs.subnet_ids["snet-appgw"]
  key_vault_id               = dependency.key_vault.outputs.id
  key_vault_secret_id        = dependency.key_vault.outputs.appgw_cert_secret_id
  front_door_id              = dependency.front_door.outputs.front_door_id
  apim_fqdn                  = replace(dependency.apim.outputs.gateway_url, "https://", "")
  storage_web_fqdn           = dependency.storage.outputs.primary_web_host
  log_analytics_workspace_id = dependency.monitoring.outputs.log_analytics_workspace_id
}
