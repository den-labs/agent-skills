#!/usr/bin/env bash
# Integration tests for the Foundry-free read path.
#
# These hit real public RPC endpoints. They send no transaction, spend no gas,
# and need no signer — so they are safe to run anywhere. They are network
# dependent, so CI treats a failure as informational.
#
# Usage: ./tests/test-reads.sh

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

PASS=0
FAIL=0

if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
  RED=$'\033[31m'; GREEN=$'\033[32m'; BOLD=$'\033[1m'; RESET=$'\033[0m'
else
  RED=""; GREEN=""; BOLD=""; RESET=""
fi

ok()  { PASS=$((PASS + 1)); printf '  %sok%s   %s\n' "$GREEN" "$RESET" "$1"; }
bad() { FAIL=$((FAIL + 1)); printf '  %sFAIL%s %s\n' "$RED" "$RESET" "$1"; [ -n "${2:-}" ] && printf '%s\n' "$2" | sed 's/^/         /' | head -4; }

# The read path must work without Foundry. If cast happens to be installed,
# hide it so these tests prove what they claim.
STUB_DIR="$(mktemp -d "${TMPDIR:-/tmp}/erc8004-noforge-XXXXXX")"
trap 'rm -rf "$STUB_DIR"' EXIT
cat > "$STUB_DIR/cast" <<'STUB'
#!/usr/bin/env bash
echo "cast was called, but the read path must not need Foundry" >&2
exit 127
STUB
chmod +x "$STUB_DIR/cast"

run_check() {
  local skill="$1"; shift
  PATH="$STUB_DIR:$PATH" "$REPO_ROOT/skills/$skill/scripts/check-agent.sh" "$@" 2>&1
}

run_feedback() {
  local skill="$1"; shift
  PATH="$STUB_DIR:$PATH" "$REPO_ROOT/skills/$skill/scripts/read-feedback.sh" "$@" 2>&1
}

printf '%sABI helpers (unit)%s\n' "$BOLD" "$RESET"

# shellcheck source=../skills/_shared/erc8004/lib.sh
source "$REPO_ROOT/skills/_shared/erc8004/lib.sh"

[ "$(e8_encode_uint256 1)" = "0000000000000000000000000000000000000000000000000000000000000001" ] \
  && ok "encode_uint256(1)" || bad "encode_uint256(1)"

[ "$(e8_encode_uint256 255)" = "00000000000000000000000000000000000000000000000000000000000000ff" ] \
  && ok "encode_uint256(255)" || bad "encode_uint256(255)"

# e8_die exits, so guard-rail checks must run in a subshell or they take the
# whole suite down with them.
( e8_encode_uint256 "not-a-number" ) >/dev/null 2>&1 \
  && bad "encode_uint256 rejects non-numeric" || ok "encode_uint256 rejects non-numeric"

( e8_encode_uint256 99999999999999999999999999 ) >/dev/null 2>&1 \
  && bad "encode_uint256 rejects out-of-range" || ok "encode_uint256 rejects out-of-range"

[ "$(e8_decode_address 0x0000000000000000000000006446ad9821021eeb9f85b8a18b0153d58166d161)" \
  = "0x6446ad9821021eeb9f85b8a18b0153d58166d161" ] \
  && ok "decode_address" || bad "decode_address"

HELLO="0x0000000000000000000000000000000000000000000000000000000000000020"
HELLO="${HELLO}0000000000000000000000000000000000000000000000000000000000000005"
HELLO="${HELLO}68656c6c6f000000000000000000000000000000000000000000000000000000"
[ "$(e8_decode_string "$HELLO")" = "hello" ] \
  && ok "decode_string (single word)" || bad "decode_string (single word)"

LONG_STR="ipfs://QmXYZabcdefghijklmnopqrstuvwxyz01"
LONG_HEX="$(printf '%s' "$LONG_STR" | od -An -tx1 | tr -d ' \n')"
LONG="0x0000000000000000000000000000000000000000000000000000000000000020"
LONG="${LONG}$(printf '%064x' ${#LONG_STR})"
LONG="${LONG}${LONG_HEX}$(printf '%0*d' $((128 - ${#LONG_HEX})) 0)"
[ "$(e8_decode_string "$LONG")" = "$LONG_STR" ] \
  && ok "decode_string (spans two words)" || bad "decode_string (spans two words)"

EMPTY="0x0000000000000000000000000000000000000000000000000000000000000020"
EMPTY="${EMPTY}0000000000000000000000000000000000000000000000000000000000000000"
[ -z "$(e8_decode_string "$EMPTY")" ] \
  && ok "decode_string (empty)" || bad "decode_string (empty)"

for target in "erc8004-celo|mainnet|42220|Celo" \
              "erc8004-celo|sepolia|11142220|Celo" \
              "erc8004-avalanche|mainnet|43114|Avalanche" \
              "erc8004-avalanche|fuji|43113|Avalanche"; do
  IFS='|' read -r skill network chain_id label <<< "$target"

  printf '\n%s%s / %s%s\n' "$BOLD" "$label" "$network" "$RESET"

  # Agent #1 exists on every one of these networks.
  out="$(NETWORK="$network" run_check "$skill" 1)"
  rc=$?

  if [ "$rc" -ne 0 ]; then
    bad "reads agent #1" "$out"
    continue
  fi
  ok "reads agent #1 without Foundry"

  printf '%s' "$out" | grep -qE 'Owner: +0x[0-9a-f]{40}' \
    && ok "owner decodes to an address" || bad "owner decodes to an address" "$out"

  printf '%s' "$out" | grep -q "eip155:${chain_id}:" \
    && ok "reports the right CAIP-10 chain" || bad "reports the right CAIP-10 chain" "$out"

  printf '%s' "$out" | grep -q 'Owner: *0x0000000000000000000000000000000000000000' \
    && bad "owner is not the zero address" || ok "owner is not the zero address"

  # Reputation is a read too, so it must also work without Foundry.
  out="$(NETWORK="$network" run_feedback "$skill" 1)"
  if [ $? -ne 0 ]; then
    bad "reads reputation for agent #1" "$out"
  else
    ok "reads reputation without Foundry"
    if printf '%s' "$out" | grep -qE 'Feedback count: [0-9]+|No feedback yet'; then
      ok "reputation summary decodes"
    else
      bad "reputation summary decodes" "$out"
    fi
  fi

  # An unminted token reverts; that must read as "not registered", not as a
  # transport error.
  out="$(NETWORK="$network" run_check "$skill" 99999999)"
  if printf '%s' "$out" | grep -q 'not registered'; then
    ok "a reverted ownerOf reads as 'not registered'"
  else
    bad "a reverted ownerOf reads as 'not registered'" "$out"
  fi
done

printf '\n%s%d passed, %d failed%s\n' "$BOLD" "$PASS" "$FAIL" "$RESET"
[ "$FAIL" -eq 0 ]
