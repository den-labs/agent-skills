#!/usr/bin/env bash
# Get risk signals for an ERC-8004 agent (reputation drops, sybil, spikes).
# Usage: ./get-signals.sh <oracle> <chain> <agentId>
# Example: ./get-signals.sh denscope celo 1
#
# Requires an API key in TRUST_API_KEY, DENSCOPE_API_KEY, or AYNI_API_KEY.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/trust.sh
source "$SCRIPT_DIR/lib/trust.sh"

ORACLE="${1:?Usage: get-signals.sh <oracle> <chain> <agentId>}"
CHAIN="${2:?Missing chain (celo, celo-sepolia, avalanche, fuji, or a chain ID)}"
AGENT_ID="${3:?Missing agent ID}"

ts_require_jq
ts_resolve_oracle "$ORACLE"
ts_resolve_chain "$CHAIN"

printf 'Risk signals: %s / chain %s / agent #%s\n\n' "$ORACLE" "$TS_CHAIN_ID" "$AGENT_ID"

BODY="$(ts_get "${TS_BASE_URL}/api/v1/agent/${TS_CHAIN_ID}/${AGENT_ID}/signals" yes)"

printf '%s' "$BODY" | jq -r '
  (.signals // []) as $s
  | if ($s | length) == 0 then
      "No risk signals — nothing flagged for this agent."
    else
      "\($s | length) signal(s):",
      "",
      ( $s[]
        | "  [\(.severity // "unknown" | ascii_upcase)] \(.type // "signal")",
          "      \(.description // .message // "no description")",
          "      detected: \(.detectedAt // .createdAt // "unknown")",
          ""
      )
    end
' || {
  echo "Could not parse the response. Raw body:" >&2
  printf '%s\n' "$BODY" >&2
  exit 1
}
