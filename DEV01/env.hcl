# -----------------------------------------------------
# DEV01 Environment Configuration
# -----------------------------------------------------
locals {
  environment     = "DEV01"
  subscription_id = "REPLACE_WITH_DEV_SUBSCRIPTION_ID"
  tenant_id       = "REPLACE_WITH_TENANT_ID"

  # Region configuration (configurable per environment)
  primary_location   = "southcentralus"
  secondary_location = "northcentralus"
  primary_short      = "scus"
  secondary_short    = "ncus"

  # Naming prefix
  name_prefix = "radshow-dev01"

  # SKU sizing (smaller for dev)
  apim_sku_capacity     = 1
  app_service_sku       = "P1v3"
  function_app_sku      = "EP1"
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
