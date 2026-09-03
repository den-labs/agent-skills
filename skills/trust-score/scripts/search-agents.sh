#!/usr/bin/env bash
# Search registered ERC-8004 agents.
# Usage: ./search-agents.sh <oracle> <chain> [query] [limit]
# Example: ./search-agents.sh denscope celo
#
# No API key required.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/trust.sh
source "$SCRIPT_DIR/lib/trust.sh"

ORACLE="${1:?Usage: search-agents.sh <oracle> <chain> [query] [limit]}"
CHAIN="${2:?Missing chain (celo, celo-sepolia, skale-base, avalanche, fuji, or a chain ID)}"
QUERY="${3:-}"
LIMIT="${4:-10}"

printf '%s' "$LIMIT" | grep -qE '^[0-9]+$' || ts_die "Limit must be a positive integer, got '$LIMIT'."

ts_require_jq
ts_resolve_oracle "$ORACLE"
ts_resolve_chain "$CHAIN"

URL="${TS_BASE_URL}/api/v1/search?chainId=${TS_CHAIN_ID}&limit=${LIMIT}"
if [ -n "$QUERY" ]; then
  # Percent-encode the query so terms with spaces or & do not corrupt the URL.
  URL="${URL}&q=$(printf '%s' "$QUERY" | jq -sRr @uri)"
fi

printf 'Searching agents on %s (chain %s)\n\n' "$ORACLE" "$TS_CHAIN_ID"

BODY="$(ts_get "$URL" yes)"

printf '%s' "$BODY" | jq -r '
  "Found \(.count) agent(s):",
  "",
  ( .agents[]
    | "  #\(.agentId) — owner \(.owner[0:12])... | \(.feedbackCount) fb (\(.positiveCount)+ / \(.negativeCount)-)" )
' || {
  echo "Could not parse the response. Raw body:" >&2
  printf '%s\n' "$BODY" >&2
  exit 1
}
