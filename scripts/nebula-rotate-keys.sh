#!/usr/bin/env bash
set -euo pipefail

# nebula-rotate-keys.sh - Generate and rotate Nebula host certs into Secret Manager
#
# Usage:
#   ./scripts/nebula-rotate-keys.sh <hostname|all> [duration_days]
#
# Example:
#   ./scripts/nebula-rotate-keys.sh hedwig
#   ./scripts/nebula-rotate-keys.sh all 365

GCP_PROJECT="${GCP_PROJECT:-bergmans-services}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
CA_CRT="${REPO_DIR}/nixos/common/global/nebula-bergnet-ca.crt"

TARGET_HOST="${1:-}"
DURATION_DAYS="${2:-365}" # Default 1 year (365 days)
DURATION="$((DURATION_DAYS * 24))h"

if [[ -z $TARGET_HOST ]]; then
    echo "Usage: $0 <hostname|all> [duration_days]"
    echo "Available NixOS hosts in registry:"
    echo "  spot (10.7.1.1)"
    echo "  hedwig (10.7.1.2)"
    echo "  snowball (10.7.1.3)"
    echo "  cheddar (10.7.1.4)"
    echo "  pinchy (10.7.1.5)"
    exit 1
fi

TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

echo "==> Fetching Nebula CA key from GCP Secret Manager ($GCP_PROJECT)..."
gcloud secrets versions access latest \
    --secret="nebula-ca-key" \
    --project="$GCP_PROJECT" >"$TMPDIR/ca.key"

rotate_host() {
    local host="$1"
    local ip="$2"
    local is_lighthouse="${3:-false}"

    echo "--------------------------------------------------------"
    echo "==> Rotating Nebula keypair for host: $host ($ip)..."

    local groups=""
    if [[ $is_lighthouse == "true" ]]; then
        groups="-groups lighthouse"
    fi

    nebula-cert sign \
        -name "$host" \
        -ip "$ip/24" \
        $groups \
        -ca-crt "$CA_CRT" \
        -ca-key "$TMPDIR/ca.key" \
        -out-crt "$TMPDIR/${host}.crt" \
        -out-key "$TMPDIR/${host}.key" \
        -duration "$DURATION"

    echo "==> Uploading certificate to GCP Secret Manager (nebula-cert-${host})..."
    gcloud secrets versions add "nebula-cert-${host}" \
        --data-file="$TMPDIR/${host}.crt" \
        --project="$GCP_PROJECT"

    echo "==> Uploading private key to GCP Secret Manager (nebula-key-${host})..."
    gcloud secrets versions add "nebula-key-${host}" \
        --data-file="$TMPDIR/${host}.key" \
        --project="$GCP_PROJECT"

    echo "==> Successfully rotated secrets for $host."
}

# Host definitions (matching nixos/common/global/nebula-bergnet-registry.nix)
declare -A HOST_IPS=(
    ["spot"]="10.7.1.1"
    ["hedwig"]="10.7.1.2"
    ["snowball"]="10.7.1.3"
    ["cheddar"]="10.7.1.4"
    ["pinchy"]="10.7.1.5"
)

declare -A IS_LIGHTHOUSE=(
    ["spot"]="true"
)

if [[ $TARGET_HOST == "all" ]]; then
    for host in "${!HOST_IPS[@]}"; do
        rotate_host "$host" "${HOST_IPS[$host]}" "${IS_LIGHTHOUSE[$host]:-false}"
    done
elif [[ -n ${HOST_IPS[$TARGET_HOST]:-} ]]; then
    rotate_host "$TARGET_HOST" "${HOST_IPS[$TARGET_HOST]}" "${IS_LIGHTHOUSE[$TARGET_HOST]:-false}"
else
    echo "Error: Unknown host '$TARGET_HOST'" >&2
    exit 1
fi
