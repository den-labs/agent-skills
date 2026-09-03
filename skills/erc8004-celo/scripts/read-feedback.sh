#!/usr/bin/env bash
# Read an agent's ERC-8004 reputation on Celo.
#
# Usage: ./read-feedback.sh <agent-id> [tag1] [tag2]
#        NETWORK=mainnet ./read-feedback.sh 1
#        NETWORK=mainnet ./read-feedback.sh 1 starred
#
# Read-only. Needs only curl and jq — no Foundry, no signer, no gas.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/erc8004.sh
source "$SCRIPT_DIR/lib/erc8004.sh"
# shellcheck source=lib/network.sh
source "$SCRIPT_DIR/lib/network.sh"

AGENT_ID="${1:-}"
TAG1="${2:-}"
TAG2="${3:-}"

[ -n "$AGENT_ID" ] || e8_die "Usage: ./read-feedback.sh <agent-id> [tag1] [tag2]"
printf '%s' "$AGENT_ID" | grep -qE '^[0-9]+$' || e8_die "Agent ID must be a positive integer, got '$AGENT_ID'."

e8_require_curl
e8_require_jq
e8_load_network

# keccak256 of the signature, first 4 bytes.
SEL_GET_CLIENTS="0x42dd519c"   # getClients(uint256)
SEL_GET_SUMMARY="0x81bbba58"   # getSummary(uint256,address[],string,string)

AGENT_WORD="$(e8_encode_uint256 "$AGENT_ID")"

e8_info "=== Reputation for agent #${AGENT_ID} on ${E8_CHAIN_LABEL} ${E8_NETWORK} ==="
[ -n "$TAG1$TAG2" ] && e8_info "Filtered by tag: ${TAG1:-<any>} ${TAG2:-}"
e8_info ""

CLIENTS_RAW="$(e8_eth_call "$E8_RPC_URL" "$E8_REPUTATION_REGISTRY" "${SEL_GET_CLIENTS}${AGENT_WORD}" || true)"

if [ -z "$CLIENTS_RAW" ] || [ "$CLIENTS_RAW" = "0x" ]; then
  e8_die "Agent #${AGENT_ID} has no reputation record on ${E8_CHAIN_LABEL} ${E8_NETWORK}."
fi

# bash 3.2 (the macOS default) has no mapfile, so read the list the portable way.
CLIENTS=()
while IFS= read -r _addr; do
  [ -n "$_addr" ] && CLIENTS+=("$_addr")
done <<EOF
$(e8_decode_address_array "$CLIENTS_RAW")
EOF

if [ "${#CLIENTS[@]}" -eq 0 ]; then
  printf 'No feedback yet — nobody has reviewed this agent.\n'
  exit 0
fi

printf 'Reviewers: %s\n\n' "${#CLIENTS[@]}"

# getSummary(uint256 agentId, address[] clients, string tag1, string tag2).
# Head is four words; the tail holds the array then each string. The contract
# rejects an empty client list, which is why getClients runs first.
CLIENT_COUNT="${#CLIENTS[@]}"
OFF_CLIENTS=128
OFF_TAG1=$(( OFF_CLIENTS + 32 + CLIENT_COUNT * 32 ))
TAG1_TAIL="$(e8_encode_string_tail "$TAG1")"
OFF_TAG2=$(( OFF_TAG1 + ${#TAG1_TAIL} / 2 ))

CALLDATA="${SEL_GET_SUMMARY}${AGENT_WORD}"
CALLDATA="${CALLDATA}$(printf '%064x' "$OFF_CLIENTS")"
CALLDATA="${CALLDATA}$(printf '%064x' "$OFF_TAG1")"
CALLDATA="${CALLDATA}$(printf '%064x' "$OFF_TAG2")"
CALLDATA="${CALLDATA}$(printf '%064x' "$CLIENT_COUNT")"
for client in "${CLIENTS[@]}"; do
  CALLDATA="${CALLDATA}$(printf '%064s' "${client#0x}" | tr ' ' '0')"
done
CALLDATA="${CALLDATA}${TAG1_TAIL}"
CALLDATA="${CALLDATA}$(e8_encode_string_tail "$TAG2")"

SUMMARY_RAW="$(e8_eth_call "$E8_RPC_URL" "$E8_REPUTATION_REGISTRY" "$CALLDATA" || true)"

if [ -z "$SUMMARY_RAW" ] || [ "$SUMMARY_RAW" = "0x" ]; then
  e8_die "getSummary returned nothing. The reputation registry may have rejected the query."
fi

H="${SUMMARY_RAW#0x}"
COUNT="$(e8_decode_uint "0x${H:0:64}")"
VALUE="$(e8_decode_int128 "0x${H:64:64}")"
DECIMALS="$(e8_decode_uint "0x${H:128:64}")"

printf 'Feedback count: %s\n' "$COUNT"

if [ "$DECIMALS" -eq 0 ]; then
  printf 'Summary value:  %s\n' "$VALUE"
else
  # Render the fixed-point value without assuming bc is installed.
  SIGN=""
  ABS="$VALUE"
  case "$VALUE" in -*) SIGN="-"; ABS="${VALUE#-}" ;; esac
  WHOLE=$(( ABS / (10 ** DECIMALS) ))
  FRAC=$(( ABS % (10 ** DECIMALS) ))
  printf 'Summary value:  %s%s.%0*d (%s decimals)\n' "$SIGN" "$WHOLE" "$DECIMALS" "$FRAC" "$DECIMALS"
fi

printf 'Registry:       %s\n' "$E8_REPUTATION_REGISTRY"
printf '\nReviewers:\n'
printf '  %s\n' "${CLIENTS[@]}"
