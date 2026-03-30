# -----------------------------------------------------
# Common: Storage Account
# RA-GZRS, static website for Vue.js SPA
# Public network access enabled because:
#   1. The static website ($web) serves public SPA assets (HTML/JS/CSS)
#   2. Front Door origins must reach the *.web.core.windows.net endpoint
#   3. CI/CD pipelines need data-plane access to upload build artifacts
# Blob containers remain "private" (no anonymous access) — only the
# static website endpoint is publicly reachable.
# -----------------------------------------------------
terraform {
  source = "git::https://github.com/DeepMalh44/radshow-def.git//modules/storage?ref=${local.env_vars.locals.environment == "PRD01" ? "v1.0.0" : "main"}"
}

locals {
  env_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
}

inputs = {
  account_tier                    = "Standard"
  account_replication_type        = "RAGZRS"
  account_kind                    = "StorageV2"
  access_tier                     = "Hot"
  min_tls_version                 = "TLS1_2"
  shared_access_key_enabled       = false
  public_network_access_enabled   = true
  allow_nested_items_to_be_public = false
  enable_static_website             = true
  static_website_index_document     = "index.html"
  static_website_error_404_document = "index.html"
  enable_diagnostics                = true

  # Allow Front Door and CI/CD to reach the storage data plane
  network_rules = {
    default_action = "Allow"
    bypass         = ["AzureServices"]
  }

  containers = {
    "$web" = {
      container_access_type = "private"
    }
  }
}
