# DEV01 / role-assignments
# RBAC: App Service & Function App managed identities → Key Vault, Storage
include "root" {
  path = find_in_parent_folders()
}

include "env" {
  path           = "${get_terragrunt_dir()}/../../_envcommon/role-assignments.hcl"
  merge_strategy = "deep"
}

locals {
  env_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
}

dependency "app_service" {
  config_path = "../app-service"

  mock_outputs = {
    identity_principal_id = "00000000-0000-0000-0000-000000000001"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

dependency "function_app" {
  config_path = "../function-app"

  mock_outputs = {
    identity_principal_id = "00000000-0000-0000-0000-000000000002"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

dependency "key_vault" {
  config_path = "../key-vault"

  mock_outputs = {
    id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/mock-rg/providers/Microsoft.KeyVault/vaults/mock-kv"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

dependency "storage" {
  config_path = "../storage"

  mock_outputs = {
    id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/mock-rg/providers/Microsoft.Storage/storageAccounts/mockstorage"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

dependency "container_registry" {
  config_path = "../container-registry"

  mock_outputs = {
    id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/mock-rg/providers/Microsoft.ContainerRegistry/registries/mockacr"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

inputs = {
  role_assignments = {
    # App Service → Key Vault Secrets User (read secrets via MI)
    "app-kv-secrets" = {
      scope                = dependency.key_vault.outputs.id
      role_definition_name = "Key Vault Secrets User"
      principal_id         = dependency.app_service.outputs.identity_principal_id
      description          = "App Service MI reads Key Vault secrets"
    }

    # App Service → Storage Blob Data Contributor (MI-based blob access)
    "app-storage-blob" = {
      scope                = dependency.storage.outputs.id
      role_definition_name = "Storage Blob Data Contributor"
      principal_id         = dependency.app_service.outputs.identity_principal_id
      description          = "App Service MI accesses Storage blobs"
    }

    # Function App → Key Vault Secrets User (read secrets via MI)
    "func-kv-secrets" = {
      scope                = dependency.key_vault.outputs.id
      role_definition_name = "Key Vault Secrets User"
      principal_id         = dependency.function_app.outputs.identity_principal_id
      description          = "Function App MI reads Key Vault secrets"
    }

    # Function App → Storage Blob Data Contributor (app-level blob access)
    "func-storage-blob-contributor" = {
      scope                = dependency.storage.outputs.id
      role_definition_name = "Storage Blob Data Contributor"
      principal_id         = dependency.function_app.outputs.identity_principal_id
      description          = "Function App MI accesses Storage blobs (app-level)"
    }

    # Function App → AcrPull (pull container images from ACR via MI)
    "func-acr-pull" = {
      scope                = dependency.container_registry.outputs.id
      role_definition_name = "AcrPull"
      principal_id         = dependency.function_app.outputs.identity_principal_id
      description          = "Function App MI pulls container images from ACR"
    }

    # --- CI/CD Service Principal → Storage (SPA deploy) ---

    # SP → Primary Storage Blob Data Contributor (SPA upload)
    "cicd-sp-storage-blob" = {
      scope                = dependency.storage.outputs.id
      role_definition_name = "Storage Blob Data Contributor"
      principal_id         = local.env_vars.locals.cicd_sp_object_id
      description          = "CI/CD SP uploads SPA to primary Storage $web"
    }
  }
}
