# DEV01 / front-door
# Single region — traffic routed through Application Gateway
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

  mock_outputs = { name = "mock-rg", location = "swedencentral" }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

dependency "application_gateway" {
  config_path = "../application-gateway"

  mock_outputs = {
    public_ip_address = "10.0.0.1"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

inputs = {
  profile_name        = "afd-${local.env_vars.locals.name_prefix}"
  resource_group_name = dependency.resource_group.outputs.name
  waf_policy_name     = "wafafd${replace(local.env_vars.locals.name_prefix, "-", "")}"

  endpoints = {
    "ep-spa" = { enabled = true }
  }

  origin_groups = {
    "og-appgw" = {
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
  }

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
  }

  routes = {
    "route-all" = {
      endpoint_key           = "ep-spa"
      origin_group_key       = "og-appgw"
      origin_keys            = ["appgw-primary"]
      enabled                = true
      forwarding_protocol    = "HttpsOnly"
      https_redirect_enabled = true
      patterns_to_match      = ["/*"]
      supported_protocols    = ["Http", "Https"]
      link_to_default_domain = true
    }
  }
}
