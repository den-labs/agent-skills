#!/usr/bin/env bash
# Search ERC-8004 agents (no API key required)
# Usage: ./search-agents.sh <oracle> <chain> [query] [limit]

set -euo pipefail

ORACLE="${1:?Usage: search-agents.sh <oracle> <chain> [query] [limit]}"
CHAIN="${2:?Missing chain}"
QUERY="${3:-}"
LIMIT="${4:-10}"

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

PARAMS="chainId=${CHAIN_ID}&limit=${LIMIT}"
[ -n "$QUERY" ] && PARAMS="${PARAMS}&q=${QUERY}"

URL="${BASE_URL}/api/v1/search?${PARAMS}"

echo "Searching agents on ${ORACLE} (chain ${CHAIN_ID}):"
echo ""

API_KEY="${TRUST_API_KEY:-${DENSCOPE_API_KEY:-${AYNI_API_KEY:-}}}"
CURL_ARGS=(-s)
[ -n "$API_KEY" ] && CURL_ARGS+=(-H "Authorization: Bearer ${API_KEY}")

curl "${CURL_ARGS[@]}" "$URL" | python3 -c "
import sys, json
d = json.load(sys.stdin)
print(f\"Found {d['count']} agent(s):\")
print()
for a in d['agents']:
    fb = f\"{a['feedbackCount']} fb ({a['positiveCount']}+ / {a['negativeCount']}-)\"
    print(f\"  #{a['agentId']} — owner: {a['owner'][:12]}... | {fb}\")
" 2>/dev/null || curl "${CURL_ARGS[@]}" "$URL"
