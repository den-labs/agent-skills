#!/usr/bin/env bash
# Register an AI agent under ERC-8004 on Celo.
#
# Usage:
#   ./register.sh <agent-uri>       register an already-hosted registration file
#   ./register.sh ipfs              build the file, pin it to IPFS, then register
#
# Network defaults to Celo Sepolia. Set NETWORK=mainnet for the real chain;
# you will be asked to confirm before any funds are spent.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/erc8004.sh
source "$SCRIPT_DIR/lib/erc8004.sh"
# shellcheck source=lib/network.sh
source "$SCRIPT_DIR/lib/network.sh"

AGENT_URI="${1:-}"

if [ -z "$AGENT_URI" ]; then
  cat >&2 <<'USAGE'
Usage: ./register.sh <agent-uri|ipfs>

Examples:
  ./register.sh https://myagent.xyz/agent.json
  ./register.sh ipfs://QmXYZ...
  AGENT_NAME="My Agent" PINATA_JWT=xxx ./register.sh ipfs
  NETWORK=mainnet ./register.sh https://myagent.xyz/agent.json

Signing (in order of preference):
  ERC8004_ACCOUNT=<name>   encrypted keystore — cast wallet import <name> --interactive
  ERC8004_LEDGER=1         Ledger hardware wallet
  PRIVATE_KEY=<raw hex>    unencrypted, discouraged
USAGE
  exit 1
fi

e8_require_foundry
e8_require_jq
e8_require_curl
e8_load_network
e8_resolve_signer

if [ "$AGENT_URI" = "ipfs" ]; then
  : "${AGENT_NAME:?AGENT_NAME is required when building the registration file}"
  AGENT_URI="$(e8_pin_json_to_ipfs \
    "$(e8_registration_json "$E8_CHAIN_ID" "$E8_IDENTITY_REGISTRY")" \
    "agent-registration-celo-${E8_CHAIN_ID}.json")"
  e8_ok "Pinned to IPFS: $AGENT_URI"
fi

e8_check_uri_reachable "$AGENT_URI"

SIGNER="$(e8_signer_address)"

e8_info ""
e8_info "=== ERC-8004 Agent Registration ==="
e8_info "Network:   ${E8_CHAIN_LABEL} ${E8_NETWORK} (chain ID ${E8_CHAIN_ID})"
e8_info "Registry:  ${E8_IDENTITY_REGISTRY}"
e8_info "Agent URI: ${AGENT_URI}"
[ -n "$SIGNER" ] && e8_info "Signer:    ${SIGNER}"
e8_info ""

e8_confirm_mainnet "$E8_NETWORK" "Register agent '${AGENT_URI}' on ${E8_CHAIN_LABEL} mainnet."

TX_HASH="$(e8_send_tx "$E8_RPC_URL" "$E8_IDENTITY_REGISTRY" "register(string)(uint256)" "$AGENT_URI")"

e8_ok "Registration confirmed."
e8_info "Transaction: ${E8_EXPLORER}/tx/${TX_HASH}"

AGENT_ID="$(e8_agent_id_from_receipt "$E8_RPC_URL" "$TX_HASH")"
if [ -n "$AGENT_ID" ]; then
  e8_ok "Agent ID: ${AGENT_ID}"
  e8_info "Verify:   ./check-agent.sh ${AGENT_ID}"
else
  e8_warn "Could not read the agent ID from the receipt. Check the explorer link above."
fi
