# DEV01 / pe-storage
# Private endpoint for primary Storage Account (blob)
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

  mock_outputs = { resource_group_name = "mock-rg", vnet_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/mock-rg/providers/Microsoft.Network/virtualNetworks/mock-vnet", vnet_name = "mock-vnet", subnet_ids = { "snet-apim" = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/mock-rg/providers/Microsoft.Network/virtualNetworks/mock-vnet/subnets/snet-apim", "snet-app" = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/mock-rg/providers/Microsoft.Network/virtualNetworks/mock-vnet/subnets/snet-app", "snet-func" = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/mock-rg/providers/Microsoft.Network/virtualNetworks/mock-vnet/subnets/snet-func", "snet-aca" = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/mock-rg/providers/Microsoft.Network/virtualNetworks/mock-vnet/subnets/snet-aca", "snet-aci" = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/mock-rg/providers/Microsoft.Network/virtualNetworks/mock-vnet/subnets/snet-aci", "snet-redis" = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/mock-rg/providers/Microsoft.Network/virtualNetworks/mock-vnet/subnets/snet-redis", "snet-sqlmi" = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/mock-rg/providers/Microsoft.Network/virtualNetworks/mock-vnet/subnets/snet-sqlmi", "snet-pe" = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/mock-rg/providers/Microsoft.Network/virtualNetworks/mock-vnet/subnets/snet-pe" }, private_dns_zone_ids = { "acr" = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/mock-rg/providers/Microsoft.Network/privateDnsZones/privatelink.azurecr.io", "sites" = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/mock-rg/providers/Microsoft.Network/privateDnsZones/privatelink.azurewebsites.net", "vault" = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/mock-rg/providers/Microsoft.Network/privateDnsZones/privatelink.vaultcore.azure.net", "blob" = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/mock-rg/providers/Microsoft.Network/privateDnsZones/privatelink.blob.core.windows.net" } }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

dependency "storage" {
  config_path = "../storage"


  mock_outputs = {
    name               = "mockstorage"
    primary_access_key  = "mockkey=="
    id                 = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/mock-rg/providers/Microsoft.Storage/storageAccounts/mockstorage"
    primary_web_host   = "mockstorage.z21.web.core.windows.net"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

inputs = {
  name                           = "pe-st-${local.env_vars.locals.name_prefix}-${local.env_vars.locals.primary_short}"
  location                       = local.env_vars.locals.primary_location
  resource_group_name            = dependency.networking.outputs.resource_group_name
  subnet_id                      = dependency.networking.outputs.subnet_ids["snet-pe"]
  private_connection_resource_id = dependency.storage.outputs.id
  subresource_names              = ["blob"]
  private_dns_zone_ids           = [dependency.networking.outputs.private_dns_zone_ids["blob"]]
}
