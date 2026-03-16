#!/usr/bin/env bash
# Get trust score for an ERC-8004 agent
# Usage: ./get-score.sh <oracle> <chain> <agentId>
# Example: ./get-score.sh denscope celo 1

set -euo pipefail

ORACLE="${1:?Usage: get-score.sh <oracle> <chain> <agentId>}"
CHAIN="${2:?Missing chain (celo, celo-sepolia, avalanche, fuji, or chain ID)}"
AGENT_ID="${3:?Missing agent ID}"
API_KEY="${TRUST_API_KEY:-${DENSCOPE_API_KEY:-${AYNI_API_KEY:-}}}"

if [ -z "$API_KEY" ]; then
  echo "Error: Set TRUST_API_KEY, DENSCOPE_API_KEY, or AYNI_API_KEY" >&2
  exit 1
fi

# Resolve oracle base URL
case "$ORACLE" in
  denscope) BASE_URL="https://denscope.vercel.app" ;;
  ayni)     BASE_URL="https://ayni-alpha.vercel.app" ;;
  *)        echo "Unknown oracle: $ORACLE (use denscope or ayni)" >&2; exit 1 ;;
esac

# Resolve chain ID
case "$CHAIN" in
  celo)          CHAIN_ID=42220 ;;
  celo-sepolia)  CHAIN_ID=11142220 ;;
  avalanche)     CHAIN_ID=43114 ;;
  fuji)          CHAIN_ID=43113 ;;
  *)             CHAIN_ID="$CHAIN" ;;
esac

URL="${BASE_URL}/api/v1/agent/${CHAIN_ID}/${AGENT_ID}/score"

echo "Querying trust score: ${ORACLE} / chain ${CHAIN_ID} / agent #${AGENT_ID}"
echo ""

RESPONSE=$(curl -s -w "\n%{http_code}" \
  -H "Authorization: Bearer ${API_KEY}" \
  "$URL")

HTTP_CODE=$(echo "$RESPONSE" | tail -1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [ "$HTTP_CODE" != "200" ]; then
  echo "Error: HTTP $HTTP_CODE"
  echo "$BODY" | head -3
  exit 1
fi

# Parse and display
echo "$BODY" | python3 -c "
import sys, json
d = json.load(sys.stdin)
s = d['score']
print(f\"Trust Score: {s['value']}/100\")
print(f\"Confidence: {s['confidence']}\")
print(f\"Feedback: {s['stats']['feedbackCount']} total ({s['stats']['positiveCount']}+ / {s['stats']['negativeCount']}-)\")
print(f\"Open Incidents: {s['stats']['openIncidents']}\")
print()
print('Breakdown:')
for k, v in s['breakdown'].items():
    print(f\"  {k}: {v['value']*100:.1f}% (weight: {v['weight']})\")
" 2>/dev/null || echo "$BODY"
