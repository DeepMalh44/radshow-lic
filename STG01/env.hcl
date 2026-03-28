# -----------------------------------------------------
# STG01 Environment Configuration
# -----------------------------------------------------
locals {
  environment     = "STG01"
  subscription_id = "REPLACE_WITH_STG_SUBSCRIPTION_ID"
  tenant_id       = "REPLACE_WITH_TENANT_ID"

  # Region configuration
  primary_location   = "southcentralus"
  secondary_location = "northcentralus"
  primary_short      = "scus"
  secondary_short    = "ncus"

  # Naming prefix
  name_prefix = "radshow-stg01"

  # SKU sizing (production-like for staging)
  apim_sku_capacity     = 1
  app_service_sku       = "P1v3"
  function_app_sku      = "EP1"
  redis_capacity        = 1
  sql_mi_vcores         = 4
  sql_mi_storage_gb     = 32
  aca_min_replicas      = 1
  aca_max_replicas      = 5

  # Feature flags
  enable_dr             = true   # DR enabled in staging for testing
  enable_waf            = true
  enable_geo_replication = true
  enable_delete_lock    = false
}
