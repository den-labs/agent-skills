#!/usr/bin/env bash
# Publish ERC-8004 reputation feedback for an agent on Avalanche.
#
# Usage: ./give-feedback.sh <agent-id> <value> [tag1] [tag2]
#        NETWORK=mainnet ./give-feedback.sh 1 85 starred
#
# Network defaults to Avalanche Fuji; mainnet requires an explicit confirmation.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/erc8004.sh
source "$SCRIPT_DIR/lib/erc8004.sh"
# shellcheck source=lib/network.sh
source "$SCRIPT_DIR/lib/network.sh"

AGENT_ID="${1:-}"
VALUE="${2:-}"
TAG1="${3:-}"
TAG2="${4:-}"
VALUE_DECIMALS="${VALUE_DECIMALS:-0}"

if [ -z "$AGENT_ID" ] || [ -z "$VALUE" ]; then
  cat >&2 <<'USAGE'
Usage: ./give-feedback.sh <agent-id> <value> [tag1] [tag2]

Examples:
  ./give-feedback.sh 1 85 starred
  VALUE_DECIMALS=2 ./give-feedback.sh 1 9950 uptime    # 99.50%
  NETWORK=mainnet ./give-feedback.sh 1 1 reachable

Common tags:
  starred        quality rating (0-100)
  reachable      endpoint reachable (0 or 1)
  uptime         uptime percentage (use VALUE_DECIMALS=2)
  successRate    success rate percentage
  responseTime   response time in milliseconds
USAGE
  exit 1
fi

printf '%s' "$AGENT_ID" | grep -qE '^[0-9]+$' || e8_die "Agent ID must be a positive integer, got '$AGENT_ID'."
printf '%s' "$VALUE" | grep -qE '^-?[0-9]+$' || e8_die "Value must be an integer, got '$VALUE'."
printf '%s' "$VALUE_DECIMALS" | grep -qE '^[0-9]+$' || e8_die "VALUE_DECIMALS must be a non-negative integer, got '$VALUE_DECIMALS'."

e8_require_foundry
e8_require_jq
e8_load_network
e8_resolve_signer

EMPTY_HASH="0x0000000000000000000000000000000000000000000000000000000000000000"

e8_info ""
e8_info "=== ERC-8004 Feedback ==="
e8_info "Network:  ${E8_CHAIN_LABEL} ${E8_NETWORK} (chain ID ${E8_CHAIN_ID})"
e8_info "Registry: ${E8_REPUTATION_REGISTRY}"
e8_info "Agent ID: ${AGENT_ID}"
e8_info "Value:    ${VALUE} (decimals: ${VALUE_DECIMALS})"
e8_info "Tags:     ${TAG1:-<none>} ${TAG2:-}"
e8_info ""

e8_confirm_mainnet "$E8_NETWORK" "Publish feedback ${VALUE} for agent #${AGENT_ID} on ${E8_CHAIN_LABEL} mainnet. Feedback is public and permanent."

TX_HASH="$(e8_send_tx "$E8_RPC_URL" "$E8_REPUTATION_REGISTRY" \
  "giveFeedback(uint256,int128,uint8,string,string,string,string,bytes32)" \
  "$AGENT_ID" "$VALUE" "$VALUE_DECIMALS" "$TAG1" "$TAG2" "" "" "$EMPTY_HASH")"

e8_ok "Feedback recorded on chain."
e8_info "Transaction: ${E8_EXPLORER}/tx/${TX_HASH}"
