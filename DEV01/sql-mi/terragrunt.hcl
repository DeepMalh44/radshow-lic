# DEV01 / sql-mi
include "root" {
  path = find_in_parent_folders()
}

include "env" {
  path           = "${get_terragrunt_dir()}/../../_envcommon/sql-mi.hcl"
  merge_strategy = "deep"
}

locals {
  env_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
}

dependency "resource_group" {
  config_path = "../resource-group"

  mock_outputs = { name = "mock-rg", location = "southcentralus" }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

dependency "networking" {
  config_path = "../networking"

  mock_outputs = { resource_group_name = "mock-rg", vnet_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/mock-rg/providers/Microsoft.Network/virtualNetworks/mock-vnet", vnet_name = "mock-vnet", subnet_ids = { "snet-apim" = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/mock-rg/providers/Microsoft.Network/virtualNetworks/mock-vnet/subnets/snet-apim", "snet-app" = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/mock-rg/providers/Microsoft.Network/virtualNetworks/mock-vnet/subnets/snet-app", "snet-func" = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/mock-rg/providers/Microsoft.Network/virtualNetworks/mock-vnet/subnets/snet-func", "snet-aca" = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/mock-rg/providers/Microsoft.Network/virtualNetworks/mock-vnet/subnets/snet-aca", "snet-aci" = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/mock-rg/providers/Microsoft.Network/virtualNetworks/mock-vnet/subnets/snet-aci", "snet-redis" = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/mock-rg/providers/Microsoft.Network/virtualNetworks/mock-vnet/subnets/snet-redis", "snet-sqlmi" = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/mock-rg/providers/Microsoft.Network/virtualNetworks/mock-vnet/subnets/snet-sqlmi", "snet-pe" = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/mock-rg/providers/Microsoft.Network/virtualNetworks/mock-vnet/subnets/snet-pe" }, private_dns_zone_ids = { "acr" = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/mock-rg/providers/Microsoft.Network/privateDnsZones/privatelink.azurecr.io", "sites" = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/mock-rg/providers/Microsoft.Network/privateDnsZones/privatelink.azurewebsites.net", "vault" = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/mock-rg/providers/Microsoft.Network/privateDnsZones/privatelink.vaultcore.azure.net", "blob" = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/mock-rg/providers/Microsoft.Network/privateDnsZones/privatelink.blob.core.windows.net" } }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

dependency "monitoring" {
  config_path = "../monitoring"


  mock_outputs = {
    log_analytics_workspace_id    = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/mock-rg/providers/Microsoft.OperationalInsights/workspaces/mock-la"
    app_insights_connection_string = "InstrumentationKey=00000000-0000-0000-0000-000000000000"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

inputs = {
  name                       = "sqlmi-${local.env_vars.locals.name_prefix}"
  resource_group_name        = dependency.resource_group.outputs.name
  location                   = dependency.resource_group.outputs.location
  subnet_id                  = dependency.networking.outputs.subnet_ids["snet-sqlmi"]
  administrator_login        = "sqladmin"
  administrator_login_password = "REPLACE_VIA_CI_CD_SECRET"
  vcores                     = local.env_vars.locals.sql_mi_vcores
  storage_size_in_gb         = local.env_vars.locals.sql_mi_storage_gb
  log_analytics_workspace_id = dependency.monitoring.outputs.log_analytics_workspace_id
  enable_failover_group      = local.env_vars.locals.enable_dr
}
