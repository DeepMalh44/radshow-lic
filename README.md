# radshow-lic - RAD Showcase Lifecycle Controller
# Terragrunt-based GitOps controller for multi-environment Azure deployments

## Overview
This repository manages the **lifecycle** of RAD Showcase infrastructure using Terragrunt.
It sources module definitions from [radshow-def](https://github.com/DeepMalh44/radshow-def)
and applies environment-specific configuration.

## Repository Structure
```
radshow-lic/
├── terragrunt.hcl              # Root config (provider, remote state, common tags)
├── _envcommon/                  # Shared module includes
│   ├── resource-group.hcl
│   ├── networking.hcl
│   ├── front-door.hcl
│   ├── apim.hcl
│   ├── app-service.hcl
│   ├── function-app.hcl
│   ├── container-apps.hcl
│   ├── container-instances.hcl
│   ├── container-registry.hcl
│   ├── sql-mi.hcl
│   ├── redis.hcl
│   ├── key-vault.hcl
│   ├── storage.hcl
│   ├── monitoring.hcl
│   └── automation.hcl
├── DEV01/                       # Development environment
│   ├── env.hcl                  # Environment-specific variables
│   └── {module}/terragrunt.hcl  # Per-module config
├── STG01/                       # Staging environment
│   ├── env.hcl
│   └── {module}/terragrunt.hcl
├── PRD01/                       # Production environment
│   ├── env.hcl
│   └── {module}/terragrunt.hcl
└── .github/workflows/           # CI/CD pipelines
    ├── plan.yml
    └── apply.yml
```

## Environments
| Environment | DR | WAF | Geo-Rep | Delete Lock | Regions |
|---|---|---|---|---|---|
| DEV01 | No | No | No | No | SCUS only |
| STG01 | Yes | Yes | Yes | No | SCUS + NCUS |
| PRD01 | Yes | Yes | Yes | Yes | SCUS + NCUS |

## Quick Start
```bash
# Prerequisites
# - Terraform >= 1.5.0
# - Terragrunt >= 0.50.0
# - Azure CLI authenticated

# Plan a single module
cd DEV01/resource-group
terragrunt plan

# Plan all modules in an environment
cd DEV01
terragrunt run-all plan

# Apply a single module
cd DEV01/resource-group
terragrunt apply

# Apply all (respects dependency order)
cd DEV01
terragrunt run-all apply
```

## Configuration
1. Update `subscription_id` and `tenant_id` in each `env.hcl`
2. Create the tfstate storage account: `rg-radshow-tfstate` / `stradshwtfstate`
3. Run `terragrunt run-all init` in the target environment

## Module Dependencies (apply order)
1. resource-group
2. networking, monitoring (parallel)
3. key-vault, storage (parallel)
4. apim, redis, sql-mi, container-registry (parallel)
5. app-service, function-app, container-apps, container-instances (parallel)
6. front-door (after backends)
7. automation (last)
