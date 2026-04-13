# STG01 / container-apps
include "root" {
  path = find_in_parent_folders()
}

include "env" {
  path           = "${get_terragrunt_dir()}/../../_envcommon/container-apps.hcl"
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

dependency "container_registry" {
  config_path = "../container-registry"

  mock_outputs = {
    login_server = "mockacr.azurecr.io"
    id           = "/subscriptions/00000000/resourceGroups/mock-rg/providers/Microsoft.ContainerRegistry/registries/mockacr"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

dependency "sql_mi_fog" {
  config_path = "../sql-mi-fog"

  mock_outputs = {
    listener_fqdn = "mock-fog.database.windows.net"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

dependency "networking_secondary" {
  config_path = "../networking-secondary"

  mock_outputs = {
    vnet_id = "mock-secondary-vnet-id"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

inputs = {
  acr_id = dependency.container_registry.outputs.id
  vnet_ids_for_dns_link = [
    dependency.networking.outputs.vnet_id,
    dependency.networking_secondary.outputs.vnet_id,
  ]
  environment_name           = "cae-${local.env_vars.locals.name_prefix}-${local.env_vars.locals.primary_short}"
  resource_group_name        = dependency.resource_group.outputs.name
  location                   = dependency.resource_group.outputs.location
  log_analytics_workspace_id = dependency.monitoring.outputs.log_analytics_workspace_id
  infrastructure_subnet_id   = dependency.networking.outputs.subnet_ids["snet-aca"]

  container_apps = {
    "products" = {
      name          = "ca-products-${local.env_vars.locals.name_prefix}-${local.env_vars.locals.primary_short}"
      revision_mode = "Single"

      ingress = {
        external_enabled = true
        target_port      = 8080
        transport        = "http"
      }

      template = {
        containers = [
          {
            name   = "products-api"
            image  = "${dependency.container_registry.outputs.login_server}/radshow-products-api:latest"
            cpu    = 0.5
            memory = "1Gi"
            env = [
              { name = "ASPNETCORE_ENVIRONMENT", value = "Staging" },
              { name = "AZURE_REGION", value = local.env_vars.locals.primary_location },
              { name = "SqlConnection", value = "Server=${dependency.sql_mi_fog.outputs.listener_fqdn};Database=radshow;Authentication=Active Directory Managed Identity;Encrypt=true;TrustServerCertificate=false" },
              { name = "APPLICATIONINSIGHTS_CONNECTION_STRING", value = dependency.monitoring.outputs.app_insights_connection_string }
            ]
          }
        ]
        min_replicas = 1
        max_replicas = 5
      }

      registry = {
        server   = dependency.container_registry.outputs.login_server
        identity = "system"
      }

      identity = {
        type = "SystemAssigned"
      }

      secrets = []
    }
  }
}
