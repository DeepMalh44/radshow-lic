# STG01 / role-assignments
# RBAC: App Service & Function App managed identities → Key Vault, Storage, ACR
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

dependency "app_service_secondary" {
  config_path = "../app-service-secondary"

  mock_outputs = {
    identity_principal_id = "00000000-0000-0000-0000-000000000005"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

dependency "container_apps" {
  config_path = "../container-apps"

  mock_outputs = {
    container_app_identity_principal_ids = { "products" = "00000000-0000-0000-0000-000000000010" }
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

dependency "container_apps_secondary" {
  config_path = "../container-apps-secondary"

  mock_outputs = {
    container_app_identity_principal_ids = { "products" = "00000000-0000-0000-0000-000000000011" }
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

dependency "function_app_secondary" {
  config_path = "../function-app-secondary"

  mock_outputs = {
    identity_principal_id = "00000000-0000-0000-0000-000000000006"
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

dependency "key_vault_secondary" {
  config_path = "../key-vault-secondary"

  mock_outputs = {
    id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/mock-rg/providers/Microsoft.KeyVault/vaults/mock-kv-sec"
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

dependency "storage_secondary" {
  config_path = "../storage-secondary"

  mock_outputs = {
    id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/mock-rg/providers/Microsoft.Storage/storageAccounts/mockstoragesec"
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

dependency "resource_group" {
  config_path = "../resource-group"

  mock_outputs = {
    id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/mock-rg"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

dependency "resource_group_secondary" {
  config_path = "../resource-group-secondary"

  mock_outputs = {
    id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/mock-rg-sec"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

dependency "front_door" {
  config_path = "../front-door"

  mock_outputs = {
    profile_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/mock-rg/providers/Microsoft.Cdn/profiles/mock-afd"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

inputs = {
  role_assignments = {
    # --- Primary Region ---

    # App Service → Key Vault Secrets User
    "app-kv-secrets" = {
      scope                = dependency.key_vault.outputs.id
      role_definition_name = "Key Vault Secrets User"
      principal_id         = dependency.app_service.outputs.identity_principal_id
      description          = "App Service MI reads Key Vault secrets"
    }

    # App Service → Storage Blob Data Contributor
    "app-storage-blob" = {
      scope                = dependency.storage.outputs.id
      role_definition_name = "Storage Blob Data Contributor"
      principal_id         = dependency.app_service.outputs.identity_principal_id
      description          = "App Service MI accesses Storage blobs"
    }

    # App Service → AcrPull (pull container images from ACR via MI)
    "app-acr-pull" = {
      scope                = dependency.container_registry.outputs.id
      role_definition_name = "AcrPull"
      principal_id         = dependency.app_service.outputs.identity_principal_id
      description          = "App Service MI pulls container images from ACR"
    }

    # Function App → Key Vault Secrets Officer (reads + writes for failover active-region)
    "func-kv-secrets" = {
      scope                = dependency.key_vault.outputs.id
      role_definition_name = "Key Vault Secrets Officer"
      principal_id         = dependency.function_app.outputs.identity_principal_id
      description          = "Function App MI reads/writes Key Vault secrets (failover active-region)"
    }

    # Function App → SQL MI Contributor on primary RG (failover group management)
    "func-sqlmi-contributor-primary" = {
      scope                = dependency.resource_group.outputs.id
      role_definition_name = "SQL Managed Instance Contributor"
      principal_id         = dependency.function_app.outputs.identity_principal_id
      description          = "Function App MI manages SQL MI failover group in primary RG"
    }

    # Function App → SQL MI Contributor on secondary RG (failover group management)
    "func-sqlmi-contributor-secondary" = {
      scope                = dependency.resource_group_secondary.outputs.id
      role_definition_name = "SQL Managed Instance Contributor"
      principal_id         = dependency.function_app.outputs.identity_principal_id
      description          = "Function App MI manages SQL MI failover group in secondary RG"
    }

    # Function App → CDN Profile Contributor (Front Door origin priority swap)
    "func-cdn-contributor" = {
      scope                = dependency.front_door.outputs.profile_id
      role_definition_name = "CDN Profile Contributor"
      principal_id         = dependency.function_app.outputs.identity_principal_id
      description          = "Function App MI swaps Front Door origin priorities during failover"
    }

    # Function App → Storage Blob Data Contributor
    "func-storage-blob-contributor" = {
      scope                = dependency.storage.outputs.id
      role_definition_name = "Storage Blob Data Contributor"
      principal_id         = dependency.function_app.outputs.identity_principal_id
      description          = "Function App MI accesses Storage blobs (app-level)"
    }

    # Function App Primary → Key Vault Secondary Secrets Officer (dual KV write during failover)
    "func-kv-secrets-peer" = {
      scope                = dependency.key_vault_secondary.outputs.id
      role_definition_name = "Key Vault Secrets Officer"
      principal_id         = dependency.function_app.outputs.identity_principal_id
      description          = "Function App MI writes active-region to peer KV during failover"
    }

    # Function App → AcrPull (pull container images from ACR via MI)
    "func-acr-pull" = {
      scope                = dependency.container_registry.outputs.id
      role_definition_name = "AcrPull"
      principal_id         = dependency.function_app.outputs.identity_principal_id
      description          = "Function App MI pulls container images from ACR"
    }

    # --- Secondary Region ---

    # App Service Secondary → Key Vault Secondary Secrets User
    "app-sec-kv-secrets" = {
      scope                = dependency.key_vault_secondary.outputs.id
      role_definition_name = "Key Vault Secrets User"
      principal_id         = dependency.app_service_secondary.outputs.identity_principal_id
      description          = "App Service Secondary MI reads Key Vault secrets"
    }

    # App Service Secondary → Storage Secondary Blob Data Contributor
    "app-sec-storage-blob" = {
      scope                = dependency.storage_secondary.outputs.id
      role_definition_name = "Storage Blob Data Contributor"
      principal_id         = dependency.app_service_secondary.outputs.identity_principal_id
      description          = "App Service Secondary MI accesses Storage blobs"
    }

    # App Service Secondary → AcrPull (same ACR, geo-replicated)
    "app-sec-acr-pull" = {
      scope                = dependency.container_registry.outputs.id
      role_definition_name = "AcrPull"
      principal_id         = dependency.app_service_secondary.outputs.identity_principal_id
      description          = "App Service Secondary MI pulls container images from ACR"
    }

    # Function App Secondary → Key Vault Secondary Secrets Officer (reads + writes for failover)
    "func-sec-kv-secrets" = {
      scope                = dependency.key_vault_secondary.outputs.id
      role_definition_name = "Key Vault Secrets Officer"
      principal_id         = dependency.function_app_secondary.outputs.identity_principal_id
      description          = "Function App Secondary MI reads/writes Key Vault secrets (failover active-region)"
    }

    # Function App Secondary → SQL MI Contributor on primary RG (failover group management)
    "func-sec-sqlmi-contributor-primary" = {
      scope                = dependency.resource_group.outputs.id
      role_definition_name = "SQL Managed Instance Contributor"
      principal_id         = dependency.function_app_secondary.outputs.identity_principal_id
      description          = "Function App Secondary MI manages SQL MI failover group in primary RG"
    }

    # Function App Secondary → SQL MI Contributor on secondary RG (failover group management)
    "func-sec-sqlmi-contributor-secondary" = {
      scope                = dependency.resource_group_secondary.outputs.id
      role_definition_name = "SQL Managed Instance Contributor"
      principal_id         = dependency.function_app_secondary.outputs.identity_principal_id
      description          = "Function App Secondary MI manages SQL MI failover group in secondary RG"
    }

    # Function App Secondary → CDN Profile Contributor (Front Door origin priority swap)
    "func-sec-cdn-contributor" = {
      scope                = dependency.front_door.outputs.profile_id
      role_definition_name = "CDN Profile Contributor"
      principal_id         = dependency.function_app_secondary.outputs.identity_principal_id
      description          = "Function App Secondary MI swaps Front Door origin priorities during failover"
    }

    # Function App Secondary → Storage Secondary Blob Data Contributor
    "func-sec-storage-blob-contributor" = {
      scope                = dependency.storage_secondary.outputs.id
      role_definition_name = "Storage Blob Data Contributor"
      principal_id         = dependency.function_app_secondary.outputs.identity_principal_id
      description          = "Function App Secondary MI accesses Storage blobs"
    }

    # Function App Secondary → Key Vault Primary Secrets Officer (dual KV write during failover)
    "func-sec-kv-secrets-peer" = {
      scope                = dependency.key_vault.outputs.id
      role_definition_name = "Key Vault Secrets Officer"
      principal_id         = dependency.function_app_secondary.outputs.identity_principal_id
      description          = "Function App Secondary MI writes active-region to peer KV during failover"
    }

    # Function App Secondary → AcrPull (same ACR, geo-replicated)
    "func-sec-acr-pull" = {
      scope                = dependency.container_registry.outputs.id
      role_definition_name = "AcrPull"
      principal_id         = dependency.function_app_secondary.outputs.identity_principal_id
      description          = "Function App Secondary MI pulls container images from ACR"
    }

    # --- CI/CD Service Principal → Storage (SPA deploy) ---

    # SP → Primary Storage Blob Data Contributor (SPA upload)
    "cicd-sp-storage-blob" = {
      scope                = dependency.storage.outputs.id
      role_definition_name = "Storage Blob Data Contributor"
      principal_id         = "6952ac03-12b8-4bd2-8697-9b624583b14f"
      description          = "CI/CD SP uploads SPA to primary Storage $web"
    }

    # SP → Secondary Storage Blob Data Contributor (SPA upload)
    "cicd-sp-storage-blob-sec" = {
      scope                = dependency.storage_secondary.outputs.id
      role_definition_name = "Storage Blob Data Contributor"
      principal_id         = "6952ac03-12b8-4bd2-8697-9b624583b14f"
      description          = "CI/CD SP uploads SPA to secondary Storage $web"
    }

    # --- Container Apps (Products API) ---

    # Container App Primary → AcrPull
    "ca-products-acr-pull" = {
      scope                = dependency.container_registry.outputs.id
      role_definition_name = "AcrPull"
      principal_id         = dependency.container_apps.outputs.container_app_identity_principal_ids["products"]
      description          = "Container App Products MI pulls images from ACR"
    }

    # Container App Primary → Key Vault Secrets User
    "ca-products-kv-secrets" = {
      scope                = dependency.key_vault.outputs.id
      role_definition_name = "Key Vault Secrets User"
      principal_id         = dependency.container_apps.outputs.container_app_identity_principal_ids["products"]
      description          = "Container App Products MI reads Key Vault secrets"
    }

    # Container App Secondary → AcrPull
    "ca-products-sec-acr-pull" = {
      scope                = dependency.container_registry.outputs.id
      role_definition_name = "AcrPull"
      principal_id         = dependency.container_apps_secondary.outputs.container_app_identity_principal_ids["products"]
      description          = "Container App Products Secondary MI pulls images from ACR"
    }

    # Container App Secondary → Key Vault Secondary Secrets User
    "ca-products-sec-kv-secrets" = {
      scope                = dependency.key_vault_secondary.outputs.id
      role_definition_name = "Key Vault Secrets User"
      principal_id         = dependency.container_apps_secondary.outputs.container_app_identity_principal_ids["products"]
      description          = "Container App Products Secondary MI reads Key Vault secrets"
    }
  }
}
