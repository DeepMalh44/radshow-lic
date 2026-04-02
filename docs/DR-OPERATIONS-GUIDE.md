# RAD Showcase - Disaster Recovery Operations Guide

## Overview

The RAD Showcase application supports automated DR failover between paired Azure regions.
Failover is triggered via the SPA Failover Control page or the `/api/failover` REST endpoint,
which orchestrates a 6-step process: password validation, active-region read, SQL MI FOG switch,
replication sync wait, Front Door origin priority swap, and Key Vault active-region update.

## Architecture

```
┌──────────────┐     ┌──────────────┐     ┌──────────┐     ┌──────────────┐
│  SPA (React) │────▶│  Front Door  │────▶│   APIM   │────▶│ Function App │
│              │     │  (og-spa +   │     │          │     │   (DR API)   │
│              │     │   og-api)    │     │          │     │              │
└──────────────┘     └──────────────┘     └──────────┘     └──────────────┘
                           │                                      │
                     Priority-based                         Orchestrates:
                     origin routing                         1. SQL MI FOG failover
                     (1=active, 2=passive)                  2. FD origin swap
                                                            3. KV state update
```

## Environments

| Environment | Primary Region | Secondary Region | DR Enabled |
|-------------|---------------|-----------------|------------|
| DEV01       | swedencentral | N/A             | No         |
| STG01       | centralindia  | southindia      | Yes        |
| PRD01       | southcentralus| northcentralus  | Yes        |

## Prerequisites for Fresh Deployments

### 1. Key Vault Secrets (Required - Manual Post-Deploy)

After Terragrunt deploys the Key Vault, you **must** create two secrets manually.
These cannot be seeded via IaC because they contain runtime state and sensitive values.

```bash
# Replace <env> with the environment prefix (e.g., stg01, prd01)
# Replace <region-short> with the primary region short name (e.g., cin, scus)

# 1. Failover password - used to authenticate failover requests from the SPA
az keyvault secret set \
  --vault-name kv-radshow-<env>-<region-short> \
  --name "failover-password" \
  --value "<CHOOSE_A_STRONG_PASSWORD>"

# 2. Active region - tracks which region is currently the primary
#    Must match the primary_location in env.hcl
az keyvault secret set \
  --vault-name kv-radshow-<env>-<region-short> \
  --name "active-region" \
  --value "<primary_location>"
```

**Per-environment examples:**

| Environment | Key Vault Name | `active-region` value | Notes |
|-------------|---------------|----------------------|-------|
| STG01       | `kv-radshow-stg01-cin` | `centralindia` | KV has private endpoint; toggle `--public-network-access` for CLI access |
| PRD01       | `kv-radshow-prd01-scus` | `southcentralus` | KV has private endpoint; toggle `--public-network-access` for CLI access |

> **Important:** If the Key Vault has public network access disabled (private endpoint only),
> you must temporarily enable it to create secrets via CLI, then re-disable:
> ```bash
> az keyvault update --name <kv-name> --public-network-access Enabled
> # ... create secrets ...
> az keyvault update --name <kv-name> --public-network-access Disabled
> ```

### 2. RBAC Roles (Provisioned by IaC)

The following roles are automatically assigned by the `role-assignments` Terragrunt module.
No manual action needed — listed here for reference:

| Role | Scope | Purpose |
|------|-------|---------|
| Key Vault Secrets Officer | Key Vault | Read/write `active-region` secret during failover |
| SQL Managed Instance Contributor | Primary + Secondary RGs | Initiate FOG failover |
| CDN Profile Contributor | Front Door Profile | Swap origin priorities |
| Storage Blob Data Contributor | Storage Account | App-level blob access |
| AcrPull | Container Registry | Pull container images |

### 3. Front Door Configuration (Provisioned by IaC)

- **Origin response timeout:** 240 seconds (set in `_envcommon/front-door.hcl` and module default)
- **Origin naming convention:** `*-primary` (priority 1) and `*-secondary` (priority 2)
- **Origin groups:** `og-api` (APIM backends) and `og-spa` (Storage static websites)
- The failover API swaps all origins in both groups simultaneously

### 4. Storage Accounts (Provisioned by IaC)

- `public_network_access_enabled = true` is required for Front Door SPA origins
  (no Private Link configured for storage → Front Door access). Set in module default.

### 5. Function App Environment Variables (Provisioned by IaC)

These are set automatically by the `function-app` and `function-app-secondary` Terragrunt configs:

| Variable | Description | Example (STG01) |
|----------|-------------|-----------------|
| `SUBSCRIPTION_ID` | Azure subscription ID | `b8383a80-...` |
| `RESOURCE_GROUP_PRIMARY` | Primary region resource group | `rg-radshow-stg01-cin` |
| `RESOURCE_GROUP_SECONDARY` | Secondary region resource group | `rg-radshow-stg01-sin` |
| `SQL_MI_FOG_NAME` | SQL MI Failover Group name | `fog-radshow-stg01` |
| `FRONT_DOOR_PROFILE_NAME` | Front Door profile name | `afd-radshow-stg01` |
| `FRONT_DOOR_ORIGIN_GROUP_NAME` | Comma-separated origin groups | `og-api,og-spa` |
| `PRIMARY_LOCATION` | Primary Azure region | `centralindia` |
| `SECONDARY_LOCATION` | Secondary Azure region | `southindia` |

## Failover Operations

### Triggering Failover from the SPA

1. Navigate to the SPA Failover Control page (e.g., `https://<front-door-endpoint>/failover`)
2. Enter the failover password
3. Click **"Failover to Secondary"** or **"Failback to Primary"**
4. Monitor the 6-step progress display
5. Expected RTO: **~120 seconds**

### Triggering Failover via API

```bash
# Failover (primary → secondary)
curl -X POST https://<front-door-endpoint>/api/failover \
  -H "Content-Type: application/json" \
  -d '{"action":"failover","password":"<failover-password>"}'

# Failback (secondary → primary)
curl -X POST https://<front-door-endpoint>/api/failover \
  -H "Content-Type: application/json" \
  -d '{"action":"failback","password":"<failover-password>"}'
```

### Failover Steps (executed by the Function App)

| Step | Name | Duration | Description |
|------|------|----------|-------------|
| 1 | Validate password | <1s | Checks `failover-password` secret in Key Vault |
| 2 | Read active region | <1s | Reads `active-region` from KV, determines target |
| 3 | SQL MI FOG switch | <1s* | POSTs failover to ARM API (fire-and-forget) |
| 4 | Wait for replication sync | 10s | Post-failover stabilization delay |
| 5 | Front Door origin swap | ~110s | Updates all origin priorities in parallel |
| 6 | Update KV active-region | <1s | Writes new active region to Key Vault |

*Step 3 initiates the FOG failover asynchronously. The actual FOG role switch completes
in the background over 5-15 minutes. This is acceptable because APIM health probes
will route traffic to the healthy backend automatically.

### Response Format

```json
{
  "success": true,
  "message": "Failover completed: centralindia → southindia in 119s",
  "previousPrimary": "centralindia",
  "newPrimary": "southindia",
  "rtoSeconds": 119,
  "steps": [
    { "name": "Validate password", "status": "completed", "durationMs": 92, "detail": "..." },
    { "name": "Read active region", "status": "completed", "durationMs": 414, "detail": "..." },
    ...
  ]
}
```

## Troubleshooting

### `InstanceFailoverGroupFailoverRequestOnPrimary`

**Cause:** The FOG state is out of sync — the target region is already the primary.

**Fix:** Verify the FOG state from both sides:
```bash
az sql instance-failover-group show --name <fog-name> \
  --resource-group <primary-rg> --location <primary-location> \
  --query replicationRole -o tsv

az sql instance-failover-group show --name <fog-name> \
  --resource-group <secondary-rg> --location <secondary-location> \
  --query replicationRole -o tsv
```

If the roles are reversed, run `set-primary` to realign:
```bash
az sql instance-failover-group set-primary \
  --name <fog-name> --resource-group <primary-rg> --location <primary-location>
```

Then update the KV `active-region` to match.

### 504 Gateway Timeout

**Cause:** Front Door origin response timeout is too low.

**Fix:** Ensure `response_timeout_seconds = 240` in the Front Door profile.
```bash
az afd profile update --profile-name <afd-name> \
  --resource-group <rg-name> --origin-response-timeout-seconds 240
```

### `Already running in target region`

**Cause:** The Key Vault `active-region` already matches the target.

**Fix:** This means a previous failover completed (possibly from a timed-out request
that finished in the background). Verify the FOG and FD origin state match, then
trigger the opposite action (failback instead of failover, or vice versa).

### Key Vault Access Denied (403 Forbidden)

**Cause:** Key Vault has public network access disabled and the caller is
not using a private endpoint.

**Fix:** The Function App accesses KV via private endpoint (VNet integration).
For CLI access, temporarily toggle public access:
```bash
az keyvault update --name <kv-name> --public-network-access Enabled
# ... perform operation ...
az keyvault update --name <kv-name> --public-network-access Disabled
```

## Post-Deployment Checklist

After a fresh Terragrunt deployment, verify the following before DR is operational:

- [ ] Key Vault secrets created: `failover-password` and `active-region`
- [ ] Function App container image deployed (via CI/CD pipeline)
- [ ] Function App health check passes: `GET /api/healthz` returns 200
- [ ] Front Door health probes healthy for both origin groups
- [ ] FOG state matches KV `active-region` (both should show primary region)
- [ ] FD origins: `*-primary` at priority 1, `*-secondary` at priority 2
- [ ] Test failover from SPA with expected ~120s RTO
- [ ] Test failback to confirm round-trip works
