#!/usr/bin/env bash
# Get an ERC-8004 agent's public profile.
# Usage: ./get-agent.sh <oracle> <chain> <agentId>
# Example: ./get-agent.sh denscope celo 1
#
# No API key required.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/trust.sh
source "$SCRIPT_DIR/lib/trust.sh"

ORACLE="${1:?Usage: get-agent.sh <oracle> <chain> <agentId>}"
CHAIN="${2:?Missing chain (celo, celo-sepolia, skale-base, avalanche, fuji, or a chain ID)}"
AGENT_ID="${3:?Missing agent ID}"

ts_require_jq
ts_resolve_oracle "$ORACLE"
ts_resolve_chain "$CHAIN"

printf 'Agent #%s on %s (chain %s)\n\n' "$AGENT_ID" "$ORACLE" "$TS_CHAIN_ID"

BODY="$(ts_get "${TS_BASE_URL}/api/v1/agent/${TS_CHAIN_ID}/${AGENT_ID}" yes)"

printf '%s' "$BODY" | jq -r '
  .agent as $a
  | "Name:       \($a.displayName // $a.uri // "Unknown")",
    "Owner:      \($a.owner)",
    "Claimed:    \(if $a.claimed then "Yes" else "No" end)",
    "Feedback:   \($a.feedbackCount) (\($a.positiveCount)+ / \($a.negativeCount)-)",
    "First seen: \($a.firstSeen // "N/A")",
    "Last seen:  \($a.lastSeen // "N/A")"
' || {
  echo "Could not parse the response. Raw body:" >&2
  printf '%s\n' "$BODY" >&2
  exit 1
}
