#!/usr/bin/env bash
# Read an ERC-8004 agent's on-chain record on Avalanche.
#
# Usage: ./check-agent.sh <agent-id>
#        NETWORK=mainnet ./check-agent.sh 1
#
# Read-only. Needs only curl and jq — no Foundry, no signer, no gas.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/erc8004.sh
source "$SCRIPT_DIR/lib/erc8004.sh"
# shellcheck source=lib/network.sh
source "$SCRIPT_DIR/lib/network.sh"

AGENT_ID="${1:-}"
[ -n "$AGENT_ID" ] || e8_die "Usage: ./check-agent.sh <agent-id>"
printf '%s' "$AGENT_ID" | grep -qE '^[0-9]+$' || e8_die "Agent ID must be a positive integer, got '$AGENT_ID'."

e8_require_curl
e8_require_jq
e8_load_network

# ERC-721 selectors: keccak256("ownerOf(uint256)")[0:4] and tokenURI(uint256).
SEL_OWNER_OF="0x6352211e"
SEL_TOKEN_URI="0xc87b56dd"

ARG="$(e8_encode_uint256 "$AGENT_ID")"

e8_info "=== ERC-8004 Agent #${AGENT_ID} on ${E8_CHAIN_LABEL} ${E8_NETWORK} ==="
e8_info ""

# ownerOf reverts for an unminted token, so an empty or zero result means the
# agent is not registered.
OWNER_RAW="$(e8_eth_call "$E8_RPC_URL" "$E8_IDENTITY_REGISTRY" "${SEL_OWNER_OF}${ARG}" || true)"

if [ -z "$OWNER_RAW" ] || [ "$OWNER_RAW" = "0x" ]; then
  e8_die "Agent #${AGENT_ID} is not registered on ${E8_CHAIN_LABEL} ${E8_NETWORK}."
fi

OWNER="$(e8_decode_address "$OWNER_RAW")" \
  || e8_die "Could not decode the owner address from: $OWNER_RAW"

if [ "$OWNER" = "0x0000000000000000000000000000000000000000" ]; then
  e8_die "Agent #${AGENT_ID} is not registered on ${E8_CHAIN_LABEL} ${E8_NETWORK}."
fi

TOKEN_URI_RAW="$(e8_eth_call "$E8_RPC_URL" "$E8_IDENTITY_REGISTRY" "${SEL_TOKEN_URI}${ARG}" || true)"
TOKEN_URI=""
if [ -n "$TOKEN_URI_RAW" ] && [ "$TOKEN_URI_RAW" != "0x" ]; then
  TOKEN_URI="$(e8_decode_string "$TOKEN_URI_RAW" || true)"
fi

# Agents may inline their whole registration document as a data: URI (some are
# gzipped base64 and run to kilobytes), so summarise rather than flood the
# terminal. Set FULL_URI=1 to print it verbatim.
describe_uri() {
  local uri="$1"
  if [ -z "$uri" ]; then
    printf '<unavailable>'
  elif [ "${FULL_URI:-}" = "1" ] || [ "${#uri}" -le 96 ]; then
    printf '%s' "$uri"
  else
    printf '%s… (%s chars, FULL_URI=1 to show)' "${uri:0:72}" "${#uri}"
  fi
}

printf 'Owner:     %s\n' "$OWNER"
printf 'Agent URI: %s\n' "$(describe_uri "$TOKEN_URI")"
printf 'Registry:  %s\n' "$E8_IDENTITY_REGISTRY"
printf 'CAIP-10:   eip155:%s:%s\n' "$E8_CHAIN_ID" "$E8_IDENTITY_REGISTRY"
printf 'Explorer:  %s/token/%s?a=%s\n' "$E8_EXPLORER" "$E8_IDENTITY_REGISTRY" "$AGENT_ID"
