# STG01 / app-service
include "root" {
  path = find_in_parent_folders()
}

include "env" {
  path           = "${get_terragrunt_dir()}/../../_envcommon/app-service.hcl"
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

dependency "sql_mi" {
  config_path = "../sql-mi"

  mock_outputs = {
    fqdn = "mock-sqlmi.database.windows.net"
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

dependency "storage" {
  config_path = "../storage"

  mock_outputs = {
    name                  = "mockstorage"
    primary_blob_endpoint = "https://mockstorage.blob.core.windows.net/"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

inputs = {
  name                          = "app-${local.env_vars.locals.name_prefix}-${local.env_vars.locals.primary_short}"
  resource_group_name           = dependency.resource_group.outputs.name
  location                      = dependency.resource_group.outputs.location
  service_plan_name             = "asp-${local.env_vars.locals.name_prefix}-${local.env_vars.locals.primary_short}"
  service_plan_sku_name         = local.env_vars.locals.app_service_sku
  vnet_integration_subnet_id    = dependency.networking.outputs.subnet_ids["snet-app"]
  log_analytics_workspace_id    = dependency.monitoring.outputs.log_analytics_workspace_id

  app_settings = {
    "APPLICATIONINSIGHTS_CONNECTION_STRING" = dependency.monitoring.outputs.app_insights_connection_string
    "ASPNETCORE_ENVIRONMENT"                = "Staging"
    "KeyVault__VaultUri"                    = dependency.key_vault.outputs.vault_uri
    "Storage__AccountName"                  = dependency.storage.outputs.name
    "Storage__BlobEndpoint"                 = dependency.storage.outputs.primary_blob_endpoint
    "Redis__ConnectionString"               = "${dependency.redis.outputs.hostname}:${dependency.redis.outputs.ssl_port},password=${dependency.redis.outputs.primary_access_key},ssl=True,abortConnect=False"
  }

  connection_strings = {
    "DefaultConnection" = {
      type  = "SQLAzure"
      value = "Server=${dependency.sql_mi.outputs.fqdn};Database=radshow;Authentication=Active Directory Managed Identity;Encrypt=true;TrustServerCertificate=false"
    }
  }
}
