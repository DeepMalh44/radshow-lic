# -----------------------------------------------------
# Root Terragrunt Configuration - radshow-lic
# This is the top-level configuration inherited by all environments.
# -----------------------------------------------------

locals {
  # Parse the environment from the folder structure
  env_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  env      = local.env_vars.locals.environment
  # Azure subscription and tenant
  subscription_id = local.env_vars.locals.subscription_id
  tenant_id       = local.env_vars.locals.tenant_id
}

# Generate the provider block
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<-EOF
    terraform {
      required_version = ">= 1.5.0"
      required_providers {
        azurerm = {
          source  = "hashicorp/azurerm"
          version = "~> 3.80"
        }
        azapi = {
          source  = "Azure/azapi"
          version = ">= 2.0"
        }
      }
    }

    provider "azurerm" {
      features {
        key_vault {
          purge_soft_delete_on_destroy = false
        }
        resource_group {
          prevent_deletion_if_contains_resources = true
        }
      }
      subscription_id = "${local.subscription_id}"
      tenant_id       = "${local.tenant_id}"
    }

    provider "azapi" {
      tenant_id       = "${local.tenant_id}"
      subscription_id = "${local.subscription_id}"
    }
  EOF
}

# Configure remote state in Azure Storage
remote_state {
  backend = "azurerm"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    resource_group_name  = "rg-radshow-tfstate"
    storage_account_name = "stradshwtfstate"
    container_name       = "tfstate"
    key                  = "${path_relative_to_include()}/terraform.tfstate"
    subscription_id      = local.subscription_id
    tenant_id            = local.tenant_id
  }
}

# Common inputs passed to all modules
inputs = {
  tags = {
    Project     = "RAD-Showcase"
    Environment = local.env
    ManagedBy   = "Terragrunt"
    Repository  = "radshow-lic"
  }
}
