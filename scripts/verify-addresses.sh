#!/usr/bin/env bash
# Verify that every registry address the skills document actually has code
# deployed at it, on the network the skills claim.
#
# The addresses are deterministic deployments reused across 40+ chains, which
# makes it easy to paste a mainnet address into a testnet table and never
# notice. This checks the claim directly with eth_getCode.
#
# Usage: ./scripts/verify-addresses.sh

set -uo pipefail

command -v jq >/dev/null 2>&1 || { echo "error: jq is required" >&2; exit 1; }

if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
  RED=$'\033[31m'; GREEN=$'\033[32m'; BOLD=$'\033[1m'; RESET=$'\033[0m'
else
  RED=""; GREEN=""; BOLD=""; RESET=""
fi

MAINNET_IDENTITY="0x8004A169FB4a3325136EB29fA0ceB6D2e539a432"
MAINNET_REPUTATION="0x8004BAa17C55a88189AE136b182e5fdA19dE9b63"
TESTNET_IDENTITY="0x8004A818BFB912233c491871b3d84c89A494BD9e"
TESTNET_REPUTATION="0x8004B663056A597Dffe9eCcC1965A193B7388713"

# label | rpc | identity | reputation
TARGETS=(
  "Celo mainnet|https://forno.celo.org|$MAINNET_IDENTITY|$MAINNET_REPUTATION"
  "Celo Sepolia|https://forno.celo-sepolia.celo-testnet.org|$TESTNET_IDENTITY|$TESTNET_REPUTATION"
  "Avalanche C-Chain|https://api.avax.network/ext/bc/C/rpc|$MAINNET_IDENTITY|$MAINNET_REPUTATION"
  "Avalanche Fuji|https://api.avax-test.network/ext/bc/C/rpc|$TESTNET_IDENTITY|$TESTNET_REPUTATION"
)

PASS=0
FAIL=0

# has_code <rpc-url> <address> — 0 if the address holds contract code.
has_code() {
  local rpc="$1" addr="$2" code
  code="$(curl -sS -m 20 -X POST "$rpc" \
    -H 'content-type: application/json' \
    --data "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"eth_getCode\",\"params\":[\"$addr\",\"latest\"]}" \
    2>/dev/null | jq -r '.result // empty')"

  [ -n "$code" ] && [ "$code" != "0x" ]
}

printf '%sVerifying documented ERC-8004 registry addresses%s\n\n' "$BOLD" "$RESET"

for target in "${TARGETS[@]}"; do
  IFS='|' read -r label rpc identity reputation <<< "$target"
  printf '%s%s%s\n' "$BOLD" "$label" "$RESET"

  for pair in "Identity:$identity" "Reputation:$reputation"; do
    name="${pair%%:*}"
    addr="${pair#*:}"

    if has_code "$rpc" "$addr"; then
      PASS=$((PASS + 1))
      printf '  %sok%s   %-11s %s\n' "$GREEN" "$RESET" "$name" "$addr"
    else
      FAIL=$((FAIL + 1))
      printf '  %sFAIL%s %-11s %s has no code on this network\n' "$RED" "$RESET" "$name" "$addr"
    fi
  done
done

printf '\n%s%d verified, %d failed%s\n' "$BOLD" "$PASS" "$FAIL" "$RESET"
[ "$FAIL" -eq 0 ]
