# -----------------------------------------------------
# PRD01 Environment Configuration
# Tier 1 Mission-Critical: RTO ≤ 15 min, RPO ≤ 5 min
# -----------------------------------------------------
locals {
  environment     = "PRD01"
  subscription_id = "REPLACE_WITH_PRD_SUBSCRIPTION_ID"
  tenant_id       = "REPLACE_WITH_TENANT_ID"

  # Region configuration
  primary_location   = "southcentralus"
  secondary_location = "northcentralus"
  primary_short      = "scus"
  secondary_short    = "ncus"

  # Naming prefix
  name_prefix = "radshow-prd01"

  # SKU sizing (production)
  apim_sku_capacity     = 1
  app_service_sku       = "P2v3"
  function_app_sku      = "EP1"
  redis_capacity        = 2
  sql_mi_vcores         = 8
  sql_mi_storage_gb     = 64
  aca_min_replicas      = 2
  aca_max_replicas      = 10

  # Feature flags
  enable_dr              = true
  enable_waf             = true
  enable_geo_replication = true
  enable_delete_lock     = true  # CanNotDelete locks on production
}
