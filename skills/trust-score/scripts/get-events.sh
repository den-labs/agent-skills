#!/usr/bin/env bash
# Get the on-chain event history for an ERC-8004 agent.
# Usage: ./get-events.sh <oracle> <chain> <agentId> [limit]
# Example: ./get-events.sh denscope celo 1 20
#
# Requires an API key in TRUST_API_KEY, DENSCOPE_API_KEY, or AYNI_API_KEY.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/trust.sh
source "$SCRIPT_DIR/lib/trust.sh"

ORACLE="${1:?Usage: get-events.sh <oracle> <chain> <agentId> [limit]}"
CHAIN="${2:?Missing chain (celo, celo-sepolia, skale-base, avalanche, fuji, or a chain ID)}"
AGENT_ID="${3:?Missing agent ID}"
LIMIT="${4:-20}"

printf '%s' "$LIMIT" | grep -qE '^[0-9]+$' || ts_die "Limit must be a positive integer, got '$LIMIT'."

ts_require_jq
ts_resolve_oracle "$ORACLE"
ts_resolve_chain "$CHAIN"

printf 'Event history: %s / chain %s / agent #%s\n\n' "$ORACLE" "$TS_CHAIN_ID" "$AGENT_ID"

BODY="$(ts_get "${TS_BASE_URL}/api/v1/agent/${TS_CHAIN_ID}/${AGENT_ID}/events?limit=${LIMIT}" yes)"

printf '%s' "$BODY" | jq -r '
  (.events // []) as $e
  | if ($e | length) == 0 then
      "No events recorded for this agent."
    else
      "\($e | length) event(s), newest first:",
      "",
      ( $e[]
        | "  \(.timestamp // .blockTimestamp // "unknown")  \(.type // .eventName // "event")",
          "      block \(.blockNumber // "?")  tx \((.txHash // .transactionHash // "?")[0:18])…"
      )
    end
' || {
  echo "Could not parse the response. Raw body:" >&2
  printf '%s\n' "$BODY" >&2
  exit 1
}
