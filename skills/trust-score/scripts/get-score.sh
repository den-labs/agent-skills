#!/usr/bin/env bash
# Get the ERC-8004 trust score for an agent.
# Usage: ./get-score.sh <oracle> <chain> <agentId>
# Example: ./get-score.sh denscope celo 1
#
# Requires an API key in TRUST_API_KEY, DENSCOPE_API_KEY, or AYNI_API_KEY.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/trust.sh
source "$SCRIPT_DIR/lib/trust.sh"

ORACLE="${1:?Usage: get-score.sh <oracle> <chain> <agentId>}"
CHAIN="${2:?Missing chain (celo, celo-sepolia, avalanche, fuji, or a chain ID)}"
AGENT_ID="${3:?Missing agent ID}"

ts_require_jq
ts_resolve_oracle "$ORACLE"
ts_resolve_chain "$CHAIN"

printf 'Trust score: %s / chain %s / agent #%s\n\n' "$ORACLE" "$TS_CHAIN_ID" "$AGENT_ID"

BODY="$(ts_get "${TS_BASE_URL}/api/v1/agent/${TS_CHAIN_ID}/${AGENT_ID}/score" yes)"

printf '%s' "$BODY" | jq -r '
  .score as $s
  | "Trust Score: \($s.value)/100",
    "Confidence:  \($s.confidence)",
    "Feedback:    \($s.stats.feedbackCount) total (\($s.stats.positiveCount)+ / \($s.stats.negativeCount)-)",
    "Incidents:   \($s.stats.openIncidents) open",
    "",
    "Breakdown:",
    ( $s.breakdown | to_entries[]
      | "  \(.key): \((.value.value * 100) | . * 10 | round / 10)% (weight \(.value.weight))" )
' || {
  echo "Could not parse the response. Raw body:" >&2
  printf '%s\n' "$BODY" >&2
  exit 1
}
