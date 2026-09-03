#!/usr/bin/env bash
# Vendor skills/_shared/erc8004/lib.sh into every skill that uses it.
#
# Skills are installed one at a time, so each must carry its own copy of the
# shared helpers. This script is the only sanctioned way to update those copies;
# validate-skills.sh fails if a vendored copy drifts from the canonical file.
#
# Usage: ./scripts/sync-shared.sh [--check]

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CANONICAL="$REPO_ROOT/skills/_shared/erc8004/lib.sh"
CONSUMERS=(erc8004-avalanche erc8004-celo)

CHECK_ONLY=0
[ "${1:-}" = "--check" ] && CHECK_ONLY=1

[ -f "$CANONICAL" ] || { echo "error: missing $CANONICAL" >&2; exit 1; }

drift=0
for skill in "${CONSUMERS[@]}"; do
  dest="$REPO_ROOT/skills/$skill/scripts/lib/erc8004.sh"

  if [ "$CHECK_ONLY" = "1" ]; then
    if [ ! -f "$dest" ]; then
      echo "DRIFT $skill: vendored copy is missing" >&2
      drift=1
    elif ! cmp -s "$CANONICAL" "$dest"; then
      echo "DRIFT $skill: vendored copy differs from canonical — run ./scripts/sync-shared.sh" >&2
      drift=1
    fi
  else
    mkdir -p "$(dirname "$dest")"
    cp "$CANONICAL" "$dest"
    chmod 644 "$dest"
    echo "synced skills/$skill/scripts/lib/erc8004.sh"
  fi
done

exit "$drift"
