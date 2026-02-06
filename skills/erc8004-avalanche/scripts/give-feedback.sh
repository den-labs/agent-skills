#!/usr/bin/env bash
set -euo pipefail

# ERC-8004 Give Feedback on Avalanche C-Chain
# Usage:
#   ./scripts/give-feedback.sh <agent-id> <value> [tag1] [tag2]
#   NETWORK=fuji ./scripts/give-feedback.sh 1 85 "starred" "quality"

NETWORK="${NETWORK:-mainnet}"

if [ "$NETWORK" = "fuji" ]; then
  RPC_URL="${AVALANCHE_RPC_URL:-https://api.avax-test.network/ext/bc/C/rpc}"
  REPUTATION_REGISTRY="0x8004B663056A597Dffe9eCcC1965A193B7388713"
  CHAIN_ID="43113"
  EXPLORER="https://testnet.snowtrace.io"
else
  RPC_URL="${AVALANCHE_RPC_URL:-https://api.avax.network/ext/bc/C/rpc}"
  REPUTATION_REGISTRY="0x8004BAa17C55a88189AE136b182e5fdA19dE9b63"
  CHAIN_ID="43114"
  EXPLORER="https://snowtrace.io"
fi

if [ -z "${PRIVATE_KEY:-}" ]; then
  echo "Error: PRIVATE_KEY environment variable is required"
  exit 1
fi

AGENT_ID="${1:-}"
VALUE="${2:-}"
TAG1="${3:-}"
TAG2="${4:-}"
VALUE_DECIMALS="${VALUE_DECIMALS:-0}"

if [ -z "$AGENT_ID" ] || [ -z "$VALUE" ]; then
  echo "Usage: ./scripts/give-feedback.sh <agent-id> <value> [tag1] [tag2]"
  echo ""
  echo "Examples:"
  echo "  ./scripts/give-feedback.sh 1 85 starred"
  echo "  ./scripts/give-feedback.sh 1 9950 uptime   (with VALUE_DECIMALS=2 for 99.50%)"
  echo "  NETWORK=fuji ./scripts/give-feedback.sh 1 1 reachable"
  echo ""
  echo "Common tags:"
  echo "  starred        - Quality rating (0-100)"
  echo "  reachable      - Endpoint reachable (binary: 0 or 1)"
  echo "  uptime         - Uptime percentage (use VALUE_DECIMALS=2)"
  echo "  successRate    - Success rate percentage"
  echo "  responseTime   - Response time in ms"
  exit 1
fi

if ! command -v cast &> /dev/null; then
  echo "Error: 'cast' (Foundry) is required."
  exit 1
fi

EMPTY_HASH="0x0000000000000000000000000000000000000000000000000000000000000000"

echo "=== ERC-8004 Give Feedback ==="
echo "Network: Avalanche $NETWORK (Chain ID: $CHAIN_ID)"
echo "Agent ID: $AGENT_ID"
echo "Value: $VALUE (decimals: $VALUE_DECIMALS)"
echo "Tag1: ${TAG1:-<empty>}"
echo "Tag2: ${TAG2:-<empty>}"
echo ""

echo "Sending feedback..."

TX_HASH=$(cast send "$REPUTATION_REGISTRY" \
  "giveFeedback(uint256,int128,uint8,string,string,string,string,bytes32)" \
  "$AGENT_ID" "$VALUE" "$VALUE_DECIMALS" "$TAG1" "$TAG2" "" "" "$EMPTY_HASH" \
  --rpc-url "$RPC_URL" \
  --private-key "$PRIVATE_KEY" \
  --json | grep -o '"transactionHash":"[^"]*"' | cut -d'"' -f4)

echo "Transaction sent: $TX_HASH"
echo "Explorer: $EXPLORER/tx/$TX_HASH"
echo ""
echo "Feedback submitted successfully!"
