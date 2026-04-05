<#
.SYNOPSIS
  Seeds Key Vault secrets required for DR operations.
  Run ONCE after initial infrastructure deployment (terragrunt apply --all).

.DESCRIPTION
  Creates the 'active-region' and 'failover-password' secrets in both
  primary and secondary Key Vaults. Temporarily enables public network
  access, creates the secrets, then re-disables it.

  These secrets cannot be managed by Terraform because the Key Vaults
  have public_network_access_enabled=false (data plane unreachable from
  CI/CD runners outside the VNet).

.PARAMETER Environment
  Environment name (e.g., STG01, PRD01). Used to derive resource names.

.PARAMETER PrimaryLocation
  Short code for primary region (e.g., cin for centralindia).

.PARAMETER SecondaryLocation
  Short code for secondary region (e.g., sin for southindia).

.PARAMETER PrimaryRegion
  Full Azure region name (e.g., centralindia).

.PARAMETER FailoverPassword
  Password for DR failover operations. Will be stored in Key Vault.

.EXAMPLE
  .\seed-kv-secrets.ps1 -Environment STG01 -PrimaryLocation cin -SecondaryLocation sin -PrimaryRegion centralindia
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$Environment,
    [Parameter(Mandatory)][string]$PrimaryLocation,
    [Parameter(Mandatory)][string]$SecondaryLocation,
    [Parameter(Mandatory)][string]$PrimaryRegion,
    [string]$FailoverPassword = "DR-Failover-${Environment}!"
)

$ErrorActionPreference = 'Stop'

$prefix = "radshow-$($Environment.ToLower())"
$kvPrimary = "kv-${prefix}-${PrimaryLocation}"
$kvSecondary = "kv-${prefix}-${SecondaryLocation}"
$rgPrimary = "rg-${prefix}-${PrimaryLocation}"
$rgSecondary = "rg-${prefix}-${SecondaryLocation}"

$secrets = @{
    "active-region"    = $PrimaryRegion
    "failover-password" = $FailoverPassword
}

foreach ($kv in @(@{name=$kvPrimary; rg=$rgPrimary}, @{name=$kvSecondary; rg=$rgSecondary})) {
    Write-Host "=== Processing $($kv.name) ==="

    # Temporarily enable public access
    Write-Host "  Enabling public network access..."
    az keyvault update --name $kv.name -g $kv.rg --public-network-access Enabled --default-action Allow -o none 2>&1 | Out-Null
    Start-Sleep -Seconds 10  # Wait for network rule propagation

    # Create secrets
    foreach ($s in $secrets.GetEnumerator()) {
        Write-Host "  Creating secret: $($s.Key)"
        az keyvault secret set --vault-name $kv.name --name $s.Key --value $s.Value -o none 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Failed to create secret $($s.Key) in $($kv.name)"
        }
    }

    # Re-disable public access
    Write-Host "  Disabling public network access..."
    az keyvault update --name $kv.name -g $kv.rg --public-network-access Disabled --default-action Deny -o none 2>&1 | Out-Null

    Write-Host "  Done.`n"
}

Write-Host "All Key Vault secrets seeded successfully."
Write-Host "Both vaults locked down (public_network_access=Disabled)."
