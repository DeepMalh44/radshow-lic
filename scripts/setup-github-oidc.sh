#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# setup-github-oidc.sh — One-time setup for GitHub OIDC + repository secrets
#
# Creates an Entra ID app registration with federated credentials for each
# repository that needs to deploy via GitHub Actions, then configures the
# required GitHub environment secrets.
#
# Prerequisites:
#   - Azure CLI (az) authenticated with Owner/Contributor + User Access Admin
#   - GitHub CLI (gh) authenticated with repo access
#   - jq
#
# Usage:
#   chmod +x setup-github-oidc.sh
#   ./setup-github-oidc.sh --env DEV01 --org DeepMalh44
# ─────────────────────────────────────────────────────────────────────────────

set -euo pipefail

# ── Defaults ─────────────────────────────────────────────────────────────────
GITHUB_ORG="DeepMalh44"
ENVIRONMENT=""
SUBSCRIPTION_ID=""
TENANT_ID=""

usage() {
  echo "Usage: $0 --env <DEV01|STG01|PRD01> [--org <GitHubOrg>]"
  exit 1
}

while [[ $# -gt 0 ]]; do
  case $1 in
    --env) ENVIRONMENT="$2"; shift 2 ;;
    --org) GITHUB_ORG="$2"; shift 2 ;;
    *) usage ;;
  esac
done

[[ -z "$ENVIRONMENT" ]] && usage

# ── Resolve environment-specific values ──────────────────────────────────────
case "$ENVIRONMENT" in
  DEV01)
    SUBSCRIPTION_ID="b8383a80-7a39-472f-89b8-4f0b6a53b266"
    TENANT_ID="6021aa37-5a44-450a-8854-f08245985be2"
    NAME_PREFIX="radshow-dev01"
    PRIMARY_SHORT="swc"
    RESOURCE_GROUP="rg-radshow-dev01-swc"
    ;;
  STG01)
    SUBSCRIPTION_ID="${STG01_SUBSCRIPTION_ID:-$SUBSCRIPTION_ID}"
    TENANT_ID="${STG01_TENANT_ID:-$TENANT_ID}"
    NAME_PREFIX="radshow-stg01"
    PRIMARY_SHORT="scus"
    RESOURCE_GROUP="rg-radshow-stg01-scus"
    ;;
  PRD01)
    SUBSCRIPTION_ID="${PRD01_SUBSCRIPTION_ID:-$SUBSCRIPTION_ID}"
    TENANT_ID="${PRD01_TENANT_ID:-$TENANT_ID}"
    NAME_PREFIX="radshow-prd01"
    PRIMARY_SHORT="scus"
    RESOURCE_GROUP="rg-radshow-prd01-scus"
    ;;
  *)
    echo "ERROR: Unknown environment '$ENVIRONMENT'"
    exit 1
    ;;
esac

# Derived names
STORAGE_ACCOUNT="st$(echo "$NAME_PREFIX" | tr -d '-')${PRIMARY_SHORT}"
ACR_NAME="acr$(echo "$NAME_PREFIX" | tr -d '-')"
FUNC_APP_NAME="func-${NAME_PREFIX}"
FRONT_DOOR_PROFILE="afd-${NAME_PREFIX}"
FRONT_DOOR_ENDPOINT="ep-spa"
APP_DISPLAY_NAME="sp-radshow-cicd-${ENVIRONMENT,,}"

echo "═══════════════════════════════════════════════════════════════"
echo "  RAD Showcase — GitHub OIDC Setup"
echo "  Environment:  $ENVIRONMENT"
echo "  Subscription: $SUBSCRIPTION_ID"
echo "  Org:          $GITHUB_ORG"
echo "═══════════════════════════════════════════════════════════════"

# ── Step 1: Create Entra ID App Registration ─────────────────────────────────
echo ""
echo "▶ Step 1: Creating Entra ID App Registration: $APP_DISPLAY_NAME"

APP_ID=$(az ad app list --display-name "$APP_DISPLAY_NAME" --query "[0].appId" -o tsv 2>/dev/null || true)

if [[ -z "$APP_ID" || "$APP_ID" == "None" ]]; then
  APP_ID=$(az ad app create --display-name "$APP_DISPLAY_NAME" --query appId -o tsv)
  echo "  Created app: $APP_ID"
else
  echo "  App already exists: $APP_ID"
fi

# ── Step 2: Create Service Principal ─────────────────────────────────────────
echo ""
echo "▶ Step 2: Creating Service Principal"

SP_ID=$(az ad sp show --id "$APP_ID" --query id -o tsv 2>/dev/null || true)

if [[ -z "$SP_ID" || "$SP_ID" == "None" ]]; then
  SP_ID=$(az ad sp create --id "$APP_ID" --query id -o tsv)
  echo "  Created SP: $SP_ID"
else
  echo "  SP already exists: $SP_ID"
fi

# ── Step 3: Assign Contributor + RBAC Admin on resource group ────────────────
echo ""
echo "▶ Step 3: Assigning roles on $RESOURCE_GROUP"

az role assignment create \
  --role "Contributor" \
  --assignee-object-id "$SP_ID" \
  --assignee-principal-type ServicePrincipal \
  --scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP" \
  --only-show-errors 2>/dev/null || echo "  Contributor already assigned"

az role assignment create \
  --role "Storage Blob Data Contributor" \
  --assignee-object-id "$SP_ID" \
  --assignee-principal-type ServicePrincipal \
  --scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP" \
  --only-show-errors 2>/dev/null || echo "  Storage Blob Data Contributor already assigned"

echo "  Roles assigned"

# ── Step 4: Create Federated Credentials for each repo ──────────────────────
echo ""
echo "▶ Step 4: Creating Federated Credentials"

REPOS=("radshow-lic" "radshow-spa" "radshow-api" "radshow-apim")

for REPO in "${REPOS[@]}"; do
  CRED_NAME="gh-${REPO}-${ENVIRONMENT,,}"
  SUBJECT="repo:${GITHUB_ORG}/${REPO}:environment:${ENVIRONMENT}"

  # Check if credential already exists
  EXISTS=$(az ad app federated-credential list --id "$APP_ID" --query "[?name=='$CRED_NAME'].name" -o tsv 2>/dev/null || true)

  if [[ -z "$EXISTS" ]]; then
    az ad app federated-credential create --id "$APP_ID" --parameters "{
      \"name\": \"$CRED_NAME\",
      \"issuer\": \"https://token.actions.githubusercontent.com\",
      \"subject\": \"$SUBJECT\",
      \"audiences\": [\"api://AzureADTokenExchange\"]
    }" --only-show-errors > /dev/null
    echo "  Created: $CRED_NAME ($SUBJECT)"
  else
    echo "  Exists:  $CRED_NAME"
  fi
done

# ── Step 5: Set GitHub Environment Secrets ───────────────────────────────────
echo ""
echo "▶ Step 5: Setting GitHub Environment Secrets"

set_secret() {
  local repo=$1 key=$2 value=$3
  echo "$value" | gh secret set "$key" --repo "${GITHUB_ORG}/${repo}" --env "$ENVIRONMENT" 2>/dev/null
  echo "  ${repo}/${ENVIRONMENT}: $key"
}

# Common secrets for all repos
for REPO in "${REPOS[@]}"; do
  set_secret "$REPO" "AZURE_CLIENT_ID" "$APP_ID"
  set_secret "$REPO" "AZURE_TENANT_ID" "$TENANT_ID"
  set_secret "$REPO" "AZURE_SUBSCRIPTION_ID" "$SUBSCRIPTION_ID"
done

# Repo-specific secrets
echo ""
echo "  Setting repo-specific secrets..."

# radshow-lic (Terragrunt)
set_secret "radshow-lic" "RESOURCE_GROUP" "$RESOURCE_GROUP"

# radshow-spa (SPA deployment)
set_secret "radshow-spa" "STORAGE_ACCOUNT_NAME" "$STORAGE_ACCOUNT"
set_secret "radshow-spa" "RESOURCE_GROUP" "$RESOURCE_GROUP"
set_secret "radshow-spa" "FRONT_DOOR_RESOURCE_GROUP" "$RESOURCE_GROUP"
set_secret "radshow-spa" "FRONT_DOOR_PROFILE_NAME" "$FRONT_DOOR_PROFILE"
set_secret "radshow-spa" "FRONT_DOOR_ENDPOINT_NAME" "$FRONT_DOOR_ENDPOINT"

# radshow-api (API deployment)
set_secret "radshow-api" "ACR_NAME" "$ACR_NAME"
set_secret "radshow-api" "FUNC_APP_NAME" "$FUNC_APP_NAME"
set_secret "radshow-api" "RESOURCE_GROUP" "$RESOURCE_GROUP"

# radshow-apim (APIOps)
set_secret "radshow-apim" "RESOURCE_GROUP" "$RESOURCE_GROUP"
set_secret "radshow-apim" "APIM_NAME" "apim-${NAME_PREFIX}"

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "  Setup complete for $ENVIRONMENT!"
echo ""
echo "  App Registration: $APP_DISPLAY_NAME ($APP_ID)"
echo "  Service Principal: $SP_ID"
echo "  Federated Credentials: ${#REPOS[@]} repos"
echo "  GitHub Secrets: configured"
echo ""
echo "  Next steps:"
echo "    1. Push changes to radshow-lic → triggers Terragrunt apply"
echo "    2. Push changes to radshow-spa → triggers SPA build & deploy"
echo "    3. Push changes to radshow-api → triggers API build & deploy"
echo "═══════════════════════════════════════════════════════════════"
