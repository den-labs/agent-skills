#!/usr/bin/env bash
# Get agent profile
# Usage: ./get-agent.sh <oracle> <chain> <agentId>

set -euo pipefail

ORACLE="${1:?Usage: get-agent.sh <oracle> <chain> <agentId>}"
CHAIN="${2:?Missing chain}"
AGENT_ID="${3:?Missing agent ID}"
API_KEY="${TRUST_API_KEY:-${DENSCOPE_API_KEY:-${AYNI_API_KEY:-}}}"

case "$ORACLE" in
  denscope) BASE_URL="https://denscope.vercel.app" ;;
  ayni)     BASE_URL="https://ayni-alpha.vercel.app" ;;
  *)        echo "Unknown oracle: $ORACLE" >&2; exit 1 ;;
esac

case "$CHAIN" in
  celo)          CHAIN_ID=42220 ;;
  celo-sepolia)  CHAIN_ID=11142220 ;;
  avalanche)     CHAIN_ID=43114 ;;
  fuji)          CHAIN_ID=43113 ;;
  *)             CHAIN_ID="$CHAIN" ;;
esac

URL="${BASE_URL}/api/v1/agent/${CHAIN_ID}/${AGENT_ID}"

echo "Agent #${AGENT_ID} on ${ORACLE} (chain ${CHAIN_ID}):"
echo ""

CURL_ARGS=(-s)
[ -n "$API_KEY" ] && CURL_ARGS+=(-H "Authorization: Bearer ${API_KEY}")

curl "${CURL_ARGS[@]}" "$URL" | python3 -c "
import sys, json
d = json.load(sys.stdin)
a = d['agent']
print(f\"Name: {a.get('displayName') or a.get('uri') or 'Unknown'}\")
print(f\"Owner: {a['owner']}\")
print(f\"Claimed: {'Yes' if a.get('claimed') else 'No'}\")
print(f\"Feedback: {a['feedbackCount']} ({a['positiveCount']}+ / {a['negativeCount']}-)\")
print(f\"First seen: {a.get('firstSeen', 'N/A')}\")
print(f\"Last seen: {a.get('lastSeen', 'N/A')}\")
" 2>/dev/null || curl "${CURL_ARGS[@]}" "$URL"
