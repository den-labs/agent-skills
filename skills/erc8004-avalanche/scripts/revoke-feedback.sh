#!/usr/bin/env bash
# Revoke feedback you previously published about an agent on Avalanche.
#
# Usage: ./revoke-feedback.sh <agent-id> <feedback-index>
#        NETWORK=mainnet ./revoke-feedback.sh 1 0
#
# Calls revokeFeedback(uint256,uint64). Only the address that submitted the
# feedback can revoke it. Use ./read-feedback.sh to see an agent's reviewers,
# and getLastIndex to find your own most recent index.
#
# Network defaults to Avalanche Fuji; mainnet requires an explicit confirmation.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/erc8004.sh
source "$SCRIPT_DIR/lib/erc8004.sh"
# shellcheck source=lib/network.sh
source "$SCRIPT_DIR/lib/network.sh"

AGENT_ID="${1:-}"
INDEX="${2:-}"

if [ -z "$AGENT_ID" ] || [ -z "$INDEX" ]; then
  cat >&2 <<'USAGE'
Usage: ./revoke-feedback.sh <agent-id> <feedback-index>

Examples:
  ./revoke-feedback.sh 1 0
  NETWORK=mainnet ./revoke-feedback.sh 1 2

Only the address that gave the feedback can revoke it. Revoking does not
delete anything — it marks the entry revoked, and that is permanent too.

Run ./read-feedback.sh <agent-id> first to inspect the agent's reputation.
USAGE
  exit 1
fi

printf '%s' "$AGENT_ID" | grep -qE '^[0-9]+$' || e8_die "Agent ID must be a positive integer, got '$AGENT_ID'."
printf '%s' "$INDEX" | grep -qE '^[0-9]+$' || e8_die "Feedback index must be a non-negative integer, got '$INDEX'."

e8_require_foundry
e8_require_jq
e8_load_network
e8_resolve_signer

SIGNER="$(e8_signer_address)"

e8_info ""
e8_info "=== Revoke ERC-8004 Feedback ==="
e8_info "Network:  ${E8_CHAIN_LABEL} ${E8_NETWORK} (chain ID ${E8_CHAIN_ID})"
e8_info "Registry: ${E8_REPUTATION_REGISTRY}"
e8_info "Agent ID: ${AGENT_ID}"
e8_info "Index:    ${INDEX}"
[ -n "$SIGNER" ] && e8_info "Signer:   ${SIGNER}"
e8_info ""
e8_warn "Only the original submitter can revoke. This will revert otherwise."

e8_confirm_mainnet "$E8_NETWORK" "Revoke feedback #${INDEX} for agent #${AGENT_ID} on ${E8_CHAIN_LABEL} mainnet."

TX_HASH="$(e8_send_tx "$E8_RPC_URL" "$E8_REPUTATION_REGISTRY" \
  "revokeFeedback(uint256,uint64)" "$AGENT_ID" "$INDEX")"

e8_ok "Feedback revoked."
e8_info "Transaction: ${E8_EXPLORER}/tx/${TX_HASH}"
e8_info "Verify:      ./read-feedback.sh ${AGENT_ID}"
