# -----------------------------------------------------
# DEV01 Environment Configuration
# -----------------------------------------------------
locals {
  environment     = "DEV01"
  subscription_id = "b8383a80-7a39-472f-89b8-4f0b6a53b266"
  tenant_id       = "6021aa37-5a44-450a-8854-f08245985be2"

  # Region configuration (configurable per environment)
  primary_location   = "southcentralus"
  secondary_location = "northcentralus"
  primary_short      = "scus"
  secondary_short    = "ncus"

  # Naming prefix
  name_prefix = "radshow-dev01"

  # SKU sizing (smaller for dev)
  apim_sku_capacity     = 1
  app_service_sku       = "S1"
  function_app_sku      = "S1"
  redis_capacity        = 1
  sql_mi_vcores         = 4
  sql_mi_storage_gb     = 32
  aca_min_replicas      = 1
  aca_max_replicas      = 3

  # Feature flags
  enable_dr             = false  # DR not needed in dev
  enable_waf            = false  # WAF not needed in dev
  enable_geo_replication = false
  enable_delete_lock    = false
}
