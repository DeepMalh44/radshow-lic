# DEV01 / vnet-peering
# Bidirectional peering between primary and secondary VNets
# Note: DEV01 has enable_dr=false; this config exists for structure parity
include "root" {
  path = find_in_parent_folders()
}

include "env" {
  path           = "${get_terragrunt_dir()}/../../_envcommon/vnet-peering.hcl"
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
    vnet_id             = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/mock-rg-secondary/providers/Microsoft.Network/virtualNetworks/mock-vnet-s"
    vnet_name           = "mock-secondary-vnet"
    resource_group_name = "mock-secondary-rg"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
  skip_outputs = !fileexists("${get_terragrunt_dir()}/../networking-secondary/terragrunt.hcl")
}

inputs = {
  peering_name_1_to_2        = "peer-${local.env_vars.locals.primary_short}-to-${local.env_vars.locals.secondary_short}"
  peering_name_2_to_1        = "peer-${local.env_vars.locals.secondary_short}-to-${local.env_vars.locals.primary_short}"
  vnet_1_id                  = dependency.networking.outputs.vnet_id
  vnet_1_name                = dependency.networking.outputs.vnet_name
  vnet_1_resource_group_name = dependency.networking.outputs.resource_group_name
  vnet_2_id                  = dependency.networking_secondary.outputs.vnet_id
  vnet_2_name                = dependency.networking_secondary.outputs.vnet_name
  vnet_2_resource_group_name = dependency.networking_secondary.outputs.resource_group_name
}
