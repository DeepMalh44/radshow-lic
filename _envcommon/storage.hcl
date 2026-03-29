# -----------------------------------------------------
# Common: Storage Account
# RA-GZRS, static website for Vue.js SPA
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
  public_network_access_enabled   = false
  allow_nested_items_to_be_public = false
  enable_static_website             = true
  static_website_index_document     = "index.html"
  static_website_error_404_document = "index.html"
  enable_diagnostics                = true

  containers = {
    "$web" = {
      container_access_type = "private"
    }
  }
}
