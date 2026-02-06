#!/usr/bin/env bash
set -euo pipefail

# ERC-8004 Agent Checker on Celo
# Usage:
#   ./scripts/check-agent.sh <agent-id>
#   NETWORK=alfajores ./scripts/check-agent.sh <agent-id>

NETWORK="${NETWORK:-mainnet}"

if [ "$NETWORK" = "alfajores" ]; then
  RPC_URL="${CELO_RPC_URL:-https://alfajores-forno.celo-testnet.org}"
  IDENTITY_REGISTRY="0x8004A818BFB912233c491871b3d84c89A494BD9e"
  REPUTATION_REGISTRY="0x8004B663056A597Dffe9eCcC1965A193B7388713"
  CHAIN_ID="44787"
  EXPLORER="https://alfajores.celoscan.io"
else
  RPC_URL="${CELO_RPC_URL:-https://forno.celo.org}"
  IDENTITY_REGISTRY="0x8004A169FB4a3325136EB29fA0ceB6D2e539a432"
  REPUTATION_REGISTRY="0x8004BAa17C55a88189AE136b182e5fdA19dE9b63"
  CHAIN_ID="42220"
  EXPLORER="https://celoscan.io"
fi

AGENT_ID="${1:-}"

if [ -z "$AGENT_ID" ]; then
  echo "Usage: ./scripts/check-agent.sh <agent-id>"
  echo "  NETWORK=alfajores ./scripts/check-agent.sh 1"
  exit 1
fi

if ! command -v cast &> /dev/null; then
  echo "Error: 'cast' (Foundry) is required."
  exit 1
fi

echo "=== ERC-8004 Agent Info ==="
echo "Network: Celo $NETWORK (Chain ID: $CHAIN_ID)"
echo "Agent ID: $AGENT_ID"
echo ""

# Get owner
OWNER=$(cast call "$IDENTITY_REGISTRY" "ownerOf(uint256)(address)" "$AGENT_ID" --rpc-url "$RPC_URL" 2>/dev/null || echo "NOT_FOUND")

if [ "$OWNER" = "NOT_FOUND" ] || [ -z "$OWNER" ]; then
  echo "Agent #$AGENT_ID is not registered."
  exit 0
fi

echo "Owner: $OWNER"

# Get tokenURI
TOKEN_URI=$(cast call "$IDENTITY_REGISTRY" "tokenURI(uint256)(string)" "$AGENT_ID" --rpc-url "$RPC_URL" 2>/dev/null || echo "")
echo "Agent URI: $TOKEN_URI"

# Get agent wallet
AGENT_WALLET=$(cast call "$IDENTITY_REGISTRY" "getAgentWallet(uint256)(address)" "$AGENT_ID" --rpc-url "$RPC_URL" 2>/dev/null || echo "0x0000000000000000000000000000000000000000")
echo "Agent Wallet: $AGENT_WALLET"

# Get reputation clients
CLIENTS=$(cast call "$REPUTATION_REGISTRY" "getClients(uint256)(address[])" "$AGENT_ID" --rpc-url "$RPC_URL" 2>/dev/null || echo "[]")
echo ""
echo "Reputation Clients: $CLIENTS"

echo ""
echo "Registry ID: eip155:${CHAIN_ID}:${IDENTITY_REGISTRY}"
echo "Explorer: $EXPLORER/address/$IDENTITY_REGISTRY"
