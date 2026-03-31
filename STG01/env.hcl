# -----------------------------------------------------
# STG01 Environment Configuration
# -----------------------------------------------------
locals {
  environment     = "STG01"
  subscription_id = "b8383a80-7a39-472f-89b8-4f0b6a53b266"
  tenant_id       = "6021aa37-5a44-450a-8854-f08245985be2"

  # Region configuration
  primary_location   = "swedencentral"
  secondary_location = "germanywestcentral"
  primary_short      = "swc"
  secondary_short    = "gwc"

  # Naming prefix
  name_prefix = "radshow-stg01"

  # SKU sizing (production-like for staging)
  apim_sku_capacity     = 1
  app_service_sku       = "S1"
  function_app_sku      = "S1"
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
