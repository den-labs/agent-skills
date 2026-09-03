#!/usr/bin/env bash
# Point an ERC-8004 agent identity at a new registration file on Avalanche.
#
# Usage: ./update-agent.sh <agent-id> <new-agent-uri>
#        NETWORK=mainnet ./update-agent.sh 1 https://myagent.xyz/agent.json
#
# Calls setAgentURI(uint256,string) on the Identity Registry. Only the agent's
# owner (or an approved operator) can do this.
#
# Network defaults to Avalanche Fuji; mainnet requires an explicit confirmation.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/erc8004.sh
source "$SCRIPT_DIR/lib/erc8004.sh"
# shellcheck source=lib/network.sh
source "$SCRIPT_DIR/lib/network.sh"

AGENT_ID="${1:-}"
NEW_URI="${2:-}"

if [ -z "$AGENT_ID" ] || [ -z "$NEW_URI" ]; then
  cat >&2 <<'USAGE'
Usage: ./update-agent.sh <agent-id> <new-agent-uri>

Examples:
  ./update-agent.sh 1 https://myagent.xyz/agent.json
  ./update-agent.sh 1 ipfs://QmNewCid...
  NETWORK=mainnet ./update-agent.sh 1 https://myagent.xyz/agent.json

Only the owner of the agent NFT can change its URI.
Set SKIP_URI_CHECK=1 to skip the reachability pre-flight.
USAGE
  exit 1
fi

printf '%s' "$AGENT_ID" | grep -qE '^[0-9]+$' || e8_die "Agent ID must be a positive integer, got '$AGENT_ID'."

e8_require_foundry
e8_require_jq
e8_require_curl
e8_load_network
e8_resolve_signer

SEL_OWNER_OF="0x6352211e"
AGENT_WORD="$(e8_encode_uint256 "$AGENT_ID")"

# Fail before spending gas if the caller does not own the agent.
OWNER_RAW="$(e8_eth_call "$E8_RPC_URL" "$E8_IDENTITY_REGISTRY" "${SEL_OWNER_OF}${AGENT_WORD}" || true)"
[ -n "$OWNER_RAW" ] && [ "$OWNER_RAW" != "0x" ] \
  || e8_die "Agent #${AGENT_ID} is not registered on ${E8_CHAIN_LABEL} ${E8_NETWORK}."
OWNER="$(e8_decode_address "$OWNER_RAW")"

SIGNER="$(e8_signer_address)"
if [ -n "$SIGNER" ]; then
  SIGNER_LC="$(printf '%s' "$SIGNER" | tr 'A-Z' 'a-z')"
  if [ "$SIGNER_LC" != "$OWNER" ]; then
    e8_warn "Signer $SIGNER_LC is not the owner ($OWNER)."
    e8_warn "This will revert unless the owner approved you as an operator."
  fi
fi

e8_check_uri_reachable "$NEW_URI"

e8_info ""
e8_info "=== Update ERC-8004 Agent URI ==="
e8_info "Network:  ${E8_CHAIN_LABEL} ${E8_NETWORK} (chain ID ${E8_CHAIN_ID})"
e8_info "Agent ID: ${AGENT_ID}"
e8_info "Owner:    ${OWNER}"
e8_info "New URI:  ${NEW_URI}"
e8_info ""

e8_confirm_mainnet "$E8_NETWORK" "Point agent #${AGENT_ID} at '${NEW_URI}' on ${E8_CHAIN_LABEL} mainnet."

TX_HASH="$(e8_send_tx "$E8_RPC_URL" "$E8_IDENTITY_REGISTRY" \
  "setAgentURI(uint256,string)" "$AGENT_ID" "$NEW_URI")"

e8_ok "Agent URI updated."
e8_info "Transaction: ${E8_EXPLORER}/tx/${TX_HASH}"
e8_info "Verify:      ./check-agent.sh ${AGENT_ID}"
