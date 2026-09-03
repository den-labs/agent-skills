#!/usr/bin/env bash
# Read an ERC-8004 agent's on-chain record on Avalanche.
#
# Usage: ./check-agent.sh <agent-id>
#        NETWORK=mainnet ./check-agent.sh 1
#
# Read-only: sends no transaction and needs no signer.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/erc8004.sh
source "$SCRIPT_DIR/lib/erc8004.sh"
# shellcheck source=lib/network.sh
source "$SCRIPT_DIR/lib/network.sh"

AGENT_ID="${1:-}"
[ -n "$AGENT_ID" ] || e8_die "Usage: ./check-agent.sh <agent-id>"
printf '%s' "$AGENT_ID" | grep -qE '^[0-9]+$' || e8_die "Agent ID must be a positive integer, got '$AGENT_ID'."

e8_require_foundry
e8_load_network

e8_info "=== ERC-8004 Agent #${AGENT_ID} on ${E8_CHAIN_LABEL} ${E8_NETWORK} ==="
e8_info ""

# ownerOf reverts for an unminted token — that is how we detect "not registered".
OWNER="$(cast call "$E8_IDENTITY_REGISTRY" "ownerOf(uint256)(address)" "$AGENT_ID" \
  --rpc-url "$E8_RPC_URL" 2>/dev/null || true)"

if [ -z "$OWNER" ]; then
  e8_die "Agent #${AGENT_ID} is not registered on ${E8_CHAIN_LABEL} ${E8_NETWORK}."
fi

TOKEN_URI="$(cast call "$E8_IDENTITY_REGISTRY" "tokenURI(uint256)(string)" "$AGENT_ID" \
  --rpc-url "$E8_RPC_URL" 2>/dev/null || true)"

printf 'Owner:     %s\n' "$OWNER"
printf 'Agent URI: %s\n' "${TOKEN_URI:-<unavailable>}"
printf 'Registry:  %s\n' "$E8_IDENTITY_REGISTRY"
printf 'CAIP-10:   eip155:%s:%s\n' "$E8_CHAIN_ID" "$E8_IDENTITY_REGISTRY"
printf 'Explorer:  %s/token/%s?a=%s\n' "$E8_EXPLORER" "$E8_IDENTITY_REGISTRY" "$AGENT_ID"
