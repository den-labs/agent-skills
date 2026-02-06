#!/usr/bin/env bash
set -euo pipefail

# ERC-8004 Agent Registration on Celo
# Usage:
#   ./scripts/register.sh <agent-uri>
#   ./scripts/register.sh ipfs              # Upload to IPFS first, then register
#   NETWORK=alfajores ./scripts/register.sh <agent-uri>  # Register on Alfajores testnet

NETWORK="${NETWORK:-mainnet}"

if [ "$NETWORK" = "alfajores" ]; then
  RPC_URL="${CELO_RPC_URL:-https://alfajores-forno.celo-testnet.org}"
  IDENTITY_REGISTRY="0x8004A818BFB912233c491871b3d84c89A494BD9e"
  CHAIN_ID="44787"
  EXPLORER="https://alfajores.celoscan.io"
else
  RPC_URL="${CELO_RPC_URL:-https://forno.celo.org}"
  IDENTITY_REGISTRY="0x8004A169FB4a3325136EB29fA0ceB6D2e539a432"
  CHAIN_ID="42220"
  EXPLORER="https://celoscan.io"
fi

if [ -z "${PRIVATE_KEY:-}" ]; then
  echo "Error: PRIVATE_KEY environment variable is required"
  exit 1
fi

AGENT_URI="${1:-}"

if [ -z "$AGENT_URI" ]; then
  echo "Usage: ./scripts/register.sh <agent-uri|ipfs>"
  echo ""
  echo "Examples:"
  echo "  ./scripts/register.sh https://myagent.xyz/agent.json"
  echo "  ./scripts/register.sh ipfs://QmXYZ..."
  echo "  PINATA_JWT=xxx ./scripts/register.sh ipfs"
  echo "  NETWORK=alfajores ./scripts/register.sh https://myagent.xyz/agent.json"
  exit 1
fi

# If "ipfs" mode, create and upload registration file first
if [ "$AGENT_URI" = "ipfs" ]; then
  if [ -z "${PINATA_JWT:-}" ]; then
    echo "Error: PINATA_JWT is required for IPFS upload"
    exit 1
  fi

  AGENT_NAME="${AGENT_NAME:-My Celo Agent}"
  AGENT_DESCRIPTION="${AGENT_DESCRIPTION:-An AI agent on Celo}"
  AGENT_IMAGE="${AGENT_IMAGE:-}"

  REGISTRATION_JSON=$(cat <<EOF
{
  "type": "https://eips.ethereum.org/EIPS/eip-8004#registration-v1",
  "name": "$AGENT_NAME",
  "description": "$AGENT_DESCRIPTION",
  "image": "$AGENT_IMAGE",
  "services": [],
  "x402Support": false,
  "active": true,
  "registrations": [
    {
      "agentId": 0,
      "agentRegistry": "eip155:${CHAIN_ID}:${IDENTITY_REGISTRY}"
    }
  ],
  "supportedTrust": ["reputation"]
}
EOF
)

  echo "Uploading registration file to IPFS via Pinata..."

  TMPFILE=$(mktemp /tmp/agent-registration-XXXXXX.json)
  echo "$REGISTRATION_JSON" > "$TMPFILE"

  RESPONSE=$(curl -s -X POST "https://api.pinata.cloud/pinning/pinFileToIPFS" \
    -H "Authorization: Bearer $PINATA_JWT" \
    -F "file=@$TMPFILE" \
    -F "pinataMetadata={\"name\": \"agent-registration-celo-${CHAIN_ID}.json\"}")

  rm -f "$TMPFILE"

  IPFS_HASH=$(echo "$RESPONSE" | grep -o '"IpfsHash":"[^"]*"' | cut -d'"' -f4)

  if [ -z "$IPFS_HASH" ]; then
    echo "Error: Failed to upload to IPFS"
    echo "Response: $RESPONSE"
    exit 1
  fi

  AGENT_URI="ipfs://$IPFS_HASH"
  echo "Uploaded to IPFS: $AGENT_URI"
fi

echo ""
echo "=== ERC-8004 Agent Registration ==="
echo "Network:  Celo $NETWORK (Chain ID: $CHAIN_ID)"
echo "Registry: $IDENTITY_REGISTRY"
echo "Agent URI: $AGENT_URI"
echo ""

# Check if cast (Foundry) is available
if ! command -v cast &> /dev/null; then
  echo "Error: 'cast' (Foundry) is required. Install it with:"
  echo "  curl -L https://foundry.paradigm.xyz | bash && foundryup"
  exit 1
fi

echo "Registering agent..."

TX_HASH=$(cast send "$IDENTITY_REGISTRY" \
  "register(string)(uint256)" "$AGENT_URI" \
  --rpc-url "$RPC_URL" \
  --private-key "$PRIVATE_KEY" \
  --json | grep -o '"transactionHash":"[^"]*"' | cut -d'"' -f4)

echo "Transaction sent: $TX_HASH"
echo "Explorer: $EXPLORER/tx/$TX_HASH"

# Wait for receipt
echo "Waiting for confirmation..."
sleep 3

RECEIPT=$(cast receipt "$TX_HASH" --rpc-url "$RPC_URL" --json 2>/dev/null || echo "")

if [ -n "$RECEIPT" ]; then
  echo ""
  echo "Registration successful!"
  echo "Transaction: $EXPLORER/tx/$TX_HASH"
  echo ""
  echo "Your agent is now registered on Celo $NETWORK."
  echo "View on 8004.org: https://www.8004.org"
else
  echo ""
  echo "Transaction submitted. Check status at:"
  echo "$EXPLORER/tx/$TX_HASH"
fi
