# PRD01 / function-app
include "root" {
  path = find_in_parent_folders()
}

include "env" {
  path           = "${get_terragrunt_dir()}/../../_envcommon/function-app.hcl"
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
}

dependency "monitoring" {
  config_path = "../monitoring"
}

dependency "storage" {
  config_path = "../storage"
}

dependency "resource_group_secondary" {
  config_path = "../resource-group-secondary"

  mock_outputs = {
    name = "mock-rg-sec"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

dependency "sql_mi" {
  config_path = "../sql-mi"

  mock_outputs = {
    fqdn                = "mock-sqlmi.database.windows.net"
    failover_group_name = "mock-fog"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

dependency "sql_mi_fog" {
  config_path = "../sql-mi-fog"

  mock_outputs = {
    name          = "mock-fog"
    listener_fqdn = "mock-fog.database.windows.net"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

dependency "front_door" {
  config_path = "../front-door"

  mock_outputs = {
    profile_name = "mock-afd"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

dependency "redis" {
  config_path = "../redis"

  mock_outputs = {
    hostname           = "mock-redis.redis.cache.windows.net"
    ssl_port           = 6380
    primary_access_key = "mockkey=="
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

dependency "key_vault" {
  config_path = "../key-vault"

  mock_outputs = {
    vault_uri = "https://mock-kv.vault.azure.net/"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

dependency "key_vault_secondary" {
  config_path = "../key-vault-secondary"

  mock_outputs = {
    vault_uri = "https://mock-kv-sec.vault.azure.net/"
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

inputs = {
  name                          = "func-${local.env_vars.locals.name_prefix}-${local.env_vars.locals.primary_short}"
  resource_group_name           = dependency.resource_group.outputs.name
  location                      = dependency.resource_group.outputs.location
  service_plan_name             = "asp-func-${local.env_vars.locals.name_prefix}-${local.env_vars.locals.primary_short}"
  service_plan_sku_name         = local.env_vars.locals.function_app_sku
  storage_account_name          = dependency.storage.outputs.name
  storage_uses_managed_identity = true
  storage_account_id            = dependency.storage.outputs.id
  vnet_integration_subnet_id    = dependency.networking.outputs.subnet_ids["snet-func"]
  log_analytics_workspace_id    = dependency.monitoring.outputs.log_analytics_workspace_id
  application_insights_connection_string = dependency.monitoring.outputs.app_insights_connection_string

  app_settings = {
    "SqlConnection"              = "Server=${dependency.sql_mi_fog.outputs.listener_fqdn};Database=radshow;Authentication=Active Directory Managed Identity;Encrypt=true;TrustServerCertificate=false"
    "KeyVault__VaultUri"         = dependency.key_vault.outputs.vault_uri
    "KeyVault__PeerVaultUri"     = dependency.key_vault_secondary.outputs.vault_uri
    "Storage__AccountName"       = dependency.storage.outputs.name
    "Storage__BlobEndpoint"      = dependency.storage.outputs.primary_blob_endpoint
    "Redis__ConnectionString"    = "${dependency.redis.outputs.hostname}:${dependency.redis.outputs.ssl_port},password=${dependency.redis.outputs.primary_access_key},ssl=True,abortConnect=False"
    "SUBSCRIPTION_ID"            = local.env_vars.locals.subscription_id
    "RESOURCE_GROUP_PRIMARY"     = dependency.resource_group.outputs.name
    "RESOURCE_GROUP_SECONDARY"   = dependency.resource_group_secondary.outputs.name
    "SQL_MI_FOG_NAME"            = dependency.sql_mi_fog.outputs.name
    "FRONT_DOOR_PROFILE_NAME"    = dependency.front_door.outputs.profile_name
    "FRONT_DOOR_ORIGIN_GROUP_NAME" = "og-appgw"
    "PRIMARY_LOCATION"           = local.env_vars.locals.primary_location
    "SECONDARY_LOCATION"         = local.env_vars.locals.secondary_location
    "APIM_GATEWAY_URL"           = dependency.apim.outputs.gateway_url
  }
}
