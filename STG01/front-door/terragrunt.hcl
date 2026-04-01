# STG01 / front-door
# Active-Passive: primary (priority=1) → secondary (priority=2)
include "root" {
  path = find_in_parent_folders()
}

include "env" {
  path           = "${get_terragrunt_dir()}/../../_envcommon/front-door.hcl"
  merge_strategy = "deep"
}

locals {
  env_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
}

dependency "resource_group" {
  config_path = "../resource-group"
}

dependency "apim" {
  config_path = "../apim"

  mock_outputs = {
    gateway_url          = "https://apim-radshow-stg01-cin.azure-api.net"
    gateway_regional_url = "https://apim-radshow-stg01-cin-01.regional.azure-api.net"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

dependency "storage" {
  config_path = "../storage"

  mock_outputs = {
    primary_web_host = "stradshowstg01cin.z21.web.core.windows.net"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

dependency "storage_secondary" {
  config_path = "../storage-secondary"

  mock_outputs = {
    primary_web_host = "stradshowstg01sin.z21.web.core.windows.net"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

inputs = {
  profile_name        = "afd-${local.env_vars.locals.name_prefix}"
  resource_group_name = dependency.resource_group.outputs.name
  waf_policy_name     = "wafafd${replace(local.env_vars.locals.name_prefix, "-", "")}"

  # ── Endpoints ──
  # Single endpoint — SPA + API routes colocated so relative /api/* calls work
  endpoints = {
    "ep-spa" = { enabled = true }
  }

  # ── Origin Groups (active-passive health probes) ──
  origin_groups = {
    "og-api" = {
      session_affinity_enabled = false
      health_probe = {
        interval_in_seconds = 30
        path                = "/api/healthz"
        protocol            = "Https"
        request_type        = "HEAD"
      }
      load_balancing = {
        additional_latency_in_milliseconds = 0
        sample_size                        = 4
        successful_samples_required        = 2
      }
    }
    "og-spa" = {
      session_affinity_enabled = false
      health_probe = {
        interval_in_seconds = 30
        path                = "/index.html"
        protocol            = "Https"
        request_type        = "HEAD"
      }
      load_balancing = {
        additional_latency_in_milliseconds = 0
        sample_size                        = 4
        successful_samples_required        = 2
      }
    }
  }

  # ── Origins (priority drives active-passive) ──
  origins = {
    "apim-primary" = {
      origin_group_key               = "og-api"
      enabled                        = true
      certificate_name_check_enabled = true
      host_name                      = replace(dependency.apim.outputs.gateway_url, "https://", "")
      origin_host_header             = replace(dependency.apim.outputs.gateway_url, "https://", "")
      http_port                      = 80
      https_port                     = 443
      priority                       = 1
      weight                         = 1000
    }
    "apim-secondary" = {
      origin_group_key               = "og-api"
      enabled                        = true
      certificate_name_check_enabled = true
      host_name                      = replace(dependency.apim.outputs.gateway_regional_url, "https://", "")
      origin_host_header             = replace(dependency.apim.outputs.gateway_regional_url, "https://", "")
      http_port                      = 80
      https_port                     = 443
      priority                       = 2
      weight                         = 1000
    }
    "spa-primary" = {
      origin_group_key               = "og-spa"
      enabled                        = true
      certificate_name_check_enabled = true
      host_name                      = dependency.storage.outputs.primary_web_host
      origin_host_header             = dependency.storage.outputs.primary_web_host
      http_port                      = 80
      https_port                     = 443
      priority                       = 1
      weight                         = 1000
    }
    "spa-secondary" = {
      origin_group_key               = "og-spa"
      enabled                        = true
      certificate_name_check_enabled = true
      host_name                      = dependency.storage_secondary.outputs.primary_web_host
      origin_host_header             = dependency.storage_secondary.outputs.primary_web_host
      http_port                      = 80
      https_port                     = 443
      priority                       = 2
      weight                         = 1000
    }
  }

  # ── Routes ──
  routes = {
    "route-api" = {
      endpoint_key           = "ep-spa"
      origin_group_key       = "og-api"
      origin_keys            = ["apim-primary", "apim-secondary"]
      enabled                = true
      forwarding_protocol    = "HttpsOnly"
      https_redirect_enabled = true
      patterns_to_match      = ["/api/*"]
      supported_protocols    = ["Http", "Https"]
      link_to_default_domain = true
    }
    "route-spa" = {
      endpoint_key           = "ep-spa"
      origin_group_key       = "og-spa"
      origin_keys            = ["spa-primary", "spa-secondary"]
      enabled                = true
      forwarding_protocol    = "HttpsOnly"
      https_redirect_enabled = true
      patterns_to_match      = ["/*"]
      supported_protocols    = ["Http", "Https"]
      link_to_default_domain = true
      cache = {
        query_string_caching_behavior = "IgnoreQueryString"
        compression_enabled           = true
        content_types_to_compress     = [
          "text/html", "text/css", "application/javascript",
          "application/json", "image/svg+xml"
        ]
      }
    }
  }
}
