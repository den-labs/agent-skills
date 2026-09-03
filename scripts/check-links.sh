#!/usr/bin/env bash
# Check that external links in the skills still resolve.
#
# The skills cite ecosystem programs (Celo Agent Visa, Divvi, Retro9000) and
# vendor docs, which are the fastest-rotting part of the content. This catches
# a link that has died before a user does.
#
# Usage: ./scripts/check-links.sh
#
# Exit code 0 if every link resolves, 1 otherwise. Network dependent, so CI
# treats a failure as informational.

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
  RED=$'\033[31m'; GREEN=$'\033[32m'; YELLOW=$'\033[33m'; BOLD=$'\033[1m'; RESET=$'\033[0m'
else
  RED=""; GREEN=""; YELLOW=""; BOLD=""; RESET=""
fi

OK=0
DEAD=0
SKIPPED=0

# Collect every distinct https URL from the markdown, stripping trailing
# punctuation that markdown prose leaves attached.
URLS="$(grep -rhoE 'https://[A-Za-z0-9._~:/?#@!$&*+,;=%-]+' \
  "$REPO_ROOT/skills" "$REPO_ROOT/README.md" \
  --include='*.md' 2>/dev/null \
  | sed -E 's/[.,)»"'"'"']+$//' \
  | sort -u)"

printf '%sChecking %s external links%s\n\n' "$BOLD" "$(printf '%s\n' "$URLS" | grep -c .)" "$RESET"

for url in $URLS; do
  case "$url" in
    # Addresses on explorers are verified by verify-addresses.sh against the
    # chain itself, which is stronger than an HTTP check and far less flaky.
    *"/address/"*|*"/token/"*|*"/tx/"*)
      SKIPPED=$((SKIPPED + 1))
      continue
      ;;
    # Placeholders in examples.
    *myagent.*|*mcp.myagent*|*example.com*|*example.invalid*|*yourdomain*)
      SKIPPED=$((SKIPPED + 1))
      continue
      ;;
  esac

  code="$(curl -sS -L -o /dev/null -m 20 \
    -A 'Mozilla/5.0 (compatible; agent-skills-linkcheck/1.0)' \
    -w '%{http_code}' "$url" 2>/dev/null || printf '000')"

  case "$code" in
    2*|3*)
      OK=$((OK + 1))
      ;;
    # Several docs hosts answer 403/405 to a bot but serve fine in a browser.
    403|405|429)
      SKIPPED=$((SKIPPED + 1))
      printf '  %sskip%s %s (HTTP %s — bot-blocked, not necessarily dead)\n' "$YELLOW" "$RESET" "$url" "$code"
      ;;
    *)
      DEAD=$((DEAD + 1))
      printf '  %sDEAD%s %s (HTTP %s)\n' "$RED" "$RESET" "$url" "$code"
      ;;
  esac
done

printf '\n%s%s%s ok, %s%s%s dead, %s skipped\n' \
  "$GREEN" "$OK" "$RESET" "$RED" "$DEAD" "$RESET" "$SKIPPED"

[ "$DEAD" -eq 0 ]
