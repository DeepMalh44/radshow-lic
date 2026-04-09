# STG01 / front-door
# Active-Passive: primary AppGW (priority=1) → secondary AppGW (priority=2)
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

dependency "application_gateway" {
  config_path = "../application-gateway"

  mock_outputs = {
    public_ip_address = "10.0.0.1"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

dependency "application_gateway_secondary" {
  config_path = "../application-gateway-secondary"

  mock_outputs = {
    public_ip_address = "10.0.0.2"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

inputs = {
  profile_name        = "afd-${local.env_vars.locals.name_prefix}"
  resource_group_name = dependency.resource_group.outputs.name
  waf_policy_name     = "wafafd${replace(local.env_vars.locals.name_prefix, "-", "")}"

  # ── Endpoints ──
  endpoints = {
    "ep-spa" = { enabled = true }
  }

  # ── Origin Groups: single og-appgw (AppGW handles path routing) ──
  origin_groups = {
    "og-appgw" = {
      session_affinity_enabled = false
      restore_traffic_time_to_healed_or_new_endpoint_in_minutes = 10
      health_probe = {
        interval_in_seconds = 30
        path                = "/api/healthz"
        protocol            = "Https"
        request_type        = "GET"
      }
      load_balancing = {
        additional_latency_in_milliseconds = 0
        sample_size                        = 4
        successful_samples_required        = 2
      }
    }
  }

  # ── Origins: AppGW public IPs (self-signed cert → cert check disabled) ──
  origins = {
    "appgw-primary" = {
      origin_group_key               = "og-appgw"
      enabled                        = true
      certificate_name_check_enabled = false
      host_name                      = dependency.application_gateway.outputs.public_ip_address
      origin_host_header             = dependency.application_gateway.outputs.public_ip_address
      http_port                      = 80
      https_port                     = 443
      priority                       = 1
      weight                         = 1000
    }
    "appgw-secondary" = {
      origin_group_key               = "og-appgw"
      enabled                        = true
      certificate_name_check_enabled = false
      host_name                      = dependency.application_gateway_secondary.outputs.public_ip_address
      origin_host_header             = dependency.application_gateway_secondary.outputs.public_ip_address
      http_port                      = 80
      https_port                     = 443
      priority                       = 2
      weight                         = 1000
    }
  }

  # ── Routes: Single route-all (AppGW URL path map handles /api/* vs /*) ──
  routes = {
    "route-all" = {
      endpoint_key           = "ep-spa"
      origin_group_key       = "og-appgw"
      origin_keys            = ["appgw-primary", "appgw-secondary"]
      enabled                = true
      forwarding_protocol    = "HttpsOnly"
      https_redirect_enabled = true
      patterns_to_match      = ["/*"]
      supported_protocols    = ["Http", "Https"]
      link_to_default_domain = true
    }
  }
}
