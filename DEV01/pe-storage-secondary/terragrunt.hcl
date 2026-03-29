# DEV01 / pe-storage-secondary
# Private endpoint for secondary Storage Account (blob)
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

dependency "networking_secondary" {
  config_path = "../networking-secondary"


  mock_outputs = {
    resource_group_name = "mock-rg-secondary"
    vnet_id             = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/mock-rg-secondary/providers/Microsoft.Network/virtualNetworks/mock-vnet-secondary"
    vnet_name           = "mock-vnet-secondary"
    subnet_ids          = { "snet-apim" = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/mock-rg-secondary/providers/Microsoft.Network/virtualNetworks/mock-vnet-secondary/subnets/snet-apim", "snet-app" = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/mock-rg-secondary/providers/Microsoft.Network/virtualNetworks/mock-vnet-secondary/subnets/snet-app", "snet-func" = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/mock-rg-secondary/providers/Microsoft.Network/virtualNetworks/mock-vnet-secondary/subnets/snet-func", "snet-pe" = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/mock-rg-secondary/providers/Microsoft.Network/virtualNetworks/mock-vnet-secondary/subnets/snet-pe" }
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

dependency "storage_secondary" {
  config_path = "../storage-secondary"


  mock_outputs = {
    id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/mock-rg-secondary/providers/Microsoft.Storage/storageAccounts/mockstorage2"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

inputs = {
  name                           = "pe-st-${local.env_vars.locals.name_prefix}-${local.env_vars.locals.secondary_short}"
  location                       = local.env_vars.locals.secondary_location
  resource_group_name            = dependency.networking_secondary.outputs.resource_group_name
  subnet_id                      = dependency.networking_secondary.outputs.subnet_ids["snet-pe"]
  private_connection_resource_id = dependency.storage_secondary.outputs.id
  subresource_names              = ["blob"]
  private_dns_zone_ids           = [dependency.networking.outputs.private_dns_zone_ids["blob"]]
}
