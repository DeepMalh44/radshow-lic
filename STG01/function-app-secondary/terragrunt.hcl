# STG01 / function-app-secondary
# Secondary region Function App for DR
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

dependency "resource_group_secondary" {
  config_path = "../resource-group-secondary"
}

dependency "networking_secondary" {
  config_path = "../networking-secondary"
}

dependency "monitoring" {
  config_path = "../monitoring"
}

dependency "storage_secondary" {
  config_path = "../storage-secondary"
}

dependency "sql_mi" {
  config_path = "../sql-mi"

  mock_outputs = {
    fqdn = "mock-sqlmi.database.windows.net"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

dependency "redis_secondary" {
  config_path = "../redis-secondary"

  mock_outputs = {
    hostname           = "mock-redis.redis.cache.windows.net"
    ssl_port           = 6380
    primary_access_key = "mockkey=="
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

dependency "key_vault_secondary" {
  config_path = "../key-vault-secondary"

  mock_outputs = {
    vault_uri = "https://mock-kv.vault.azure.net/"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

inputs = {
  name                          = "func-${local.env_vars.locals.name_prefix}-${local.env_vars.locals.secondary_short}"
  resource_group_name           = dependency.resource_group_secondary.outputs.name
  location                      = local.env_vars.locals.secondary_location
  service_plan_name             = "asp-func-${local.env_vars.locals.name_prefix}-${local.env_vars.locals.secondary_short}"
  service_plan_sku_name         = local.env_vars.locals.function_app_sku
  storage_account_name          = dependency.storage_secondary.outputs.name
  storage_uses_managed_identity = true
  storage_account_id            = dependency.storage_secondary.outputs.id
  vnet_integration_subnet_id    = dependency.networking_secondary.outputs.subnet_ids["snet-func"]
  log_analytics_workspace_id    = dependency.monitoring.outputs.log_analytics_workspace_id
  application_insights_connection_string = dependency.monitoring.outputs.secondary_app_insights_connection_string

  app_settings = {
    "SqlConnection"           = "Server=${dependency.sql_mi.outputs.fqdn};Database=radshowdb;Authentication=Active Directory Managed Identity;Encrypt=true;TrustServerCertificate=false"
    "KeyVault__VaultUri"      = dependency.key_vault_secondary.outputs.vault_uri
    "Storage__AccountName"    = dependency.storage_secondary.outputs.name
    "Storage__BlobEndpoint"   = dependency.storage_secondary.outputs.primary_blob_endpoint
    "Redis__ConnectionString" = "${dependency.redis_secondary.outputs.hostname}:${dependency.redis_secondary.outputs.ssl_port},password=${dependency.redis_secondary.outputs.primary_access_key},ssl=True,abortConnect=False"
  }
}
