#!/usr/bin/env bash
# Safety tests for the ERC-8004 on-chain scripts.
#
# These scripts spend real money, so the guards around that are the part most
# worth testing. `cast` is stubbed so no test can ever reach a real chain: the
# stub records the arguments it was called with and fails loudly on any call
# the test did not anticipate.
#
# Usage: ./tests/test-safety.sh

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK="$(mktemp -d "${TMPDIR:-/tmp}/erc8004-tests-XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

STUB_BIN="$WORK/bin"
mkdir -p "$STUB_BIN"

# `cast` stub: logs the invocation, never touches the network.
cat > "$STUB_BIN/cast" <<'STUB'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "${CAST_LOG:?}"
case "$1" in
  send)
    printf '{"transactionHash":"0xdeadbeef","status":"0x1"}\n' ;;
  receipt)
    printf '{"logs":[]}\n' ;;
  call)
    printf '0x0000000000000000000000000000000000000001\n' ;;
  wallet)
    printf '0x0000000000000000000000000000000000000001\n' ;;
  *)
    printf 'unexpected cast subcommand: %s\n' "$1" >&2; exit 1 ;;
esac
STUB
chmod +x "$STUB_BIN/cast"

PASS=0
FAIL=0

if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
  RED=$'\033[31m'; GREEN=$'\033[32m'; BOLD=$'\033[1m'; RESET=$'\033[0m'
else
  RED=""; GREEN=""; BOLD=""; RESET=""
fi

ok()   { PASS=$((PASS + 1)); printf '  %sok%s   %s\n' "$GREEN" "$RESET" "$1"; }
bad()  { FAIL=$((FAIL + 1)); printf '  %sFAIL%s %s\n' "$RED" "$RESET" "$1"; }

# run <skill> <script> [args...] — runs with the cast stub on PATH.
# Sets RUN_OUT (stdout+stderr), RUN_RC, and RUN_CAST (recorded cast calls).
run() {
  local skill="$1" script="$2"; shift 2
  CAST_LOG="$WORK/cast.log"
  : > "$CAST_LOG"
  export CAST_LOG
  RUN_OUT="$(PATH="$STUB_BIN:$PATH" \
    "$REPO_ROOT/skills/$skill/scripts/$script" "$@" 2>&1 </dev/null)"
  RUN_RC=$?
  RUN_CAST="$(cat "$CAST_LOG")"
}

assert_rc() {
  local expected="$1" label="$2"
  if [ "$RUN_RC" = "$expected" ]; then ok "$label"
  else bad "$label (exit $RUN_RC, expected $expected)"; printf '%s\n' "$RUN_OUT" | sed 's/^/         /' | head -5; fi
}

assert_contains() {
  local needle="$1" label="$2"
  if printf '%s' "$RUN_OUT" | grep -qF "$needle"; then ok "$label"
  else bad "$label (output did not contain '$needle')"; printf '%s\n' "$RUN_OUT" | sed 's/^/         /' | head -5; fi
}

assert_no_cast_send() {
  local label="$1"
  if printf '%s' "$RUN_CAST" | grep -q '^send'; then
    bad "$label (a transaction WAS sent)"
  else ok "$label"; fi
}

for skill in erc8004-celo erc8004-avalanche; do
  case "$skill" in
    erc8004-celo)      testnet="sepolia"; testnet_id="11142220"; mainnet_id="42220" ;;
    erc8004-avalanche) testnet="fuji";    testnet_id="43113";    mainnet_id="43114" ;;
  esac

  printf '%s%s%s\n' "$BOLD" "$skill" "$RESET"

  # --- The default network must be the testnet, never mainnet. ---
  unset NETWORK ERC8004_YES PRIVATE_KEY ERC8004_ACCOUNT
  run "$skill" check-agent.sh 1
  assert_contains "$testnet_id" "defaults to the testnet ($testnet), not mainnet"

  # --- Mainnet must refuse to spend from a non-interactive shell. ---
  NETWORK=mainnet PRIVATE_KEY=0xabc run "$skill" register.sh "https://example.com/a.json"
  assert_rc 1 "mainnet register refuses without a TTY"
  assert_contains "non-interactive" "mainnet refusal explains why"
  assert_no_cast_send "mainnet register sent no transaction"

  NETWORK=mainnet PRIVATE_KEY=0xabc run "$skill" give-feedback.sh 1 85 starred
  assert_rc 1 "mainnet feedback refuses without a TTY"
  assert_no_cast_send "mainnet feedback sent no transaction"

  # --- A missing signer must fail before any network call. ---
  unset PRIVATE_KEY ERC8004_ACCOUNT
  NETWORK="$testnet" run "$skill" register.sh "https://example.com/a.json"
  assert_rc 1 "register without a signer fails"
  assert_contains "ERC8004_ACCOUNT" "signer error recommends the keystore"
  assert_no_cast_send "no-signer register sent no transaction"

  # --- Input validation happens before spending gas. ---
  NETWORK="$testnet" PRIVATE_KEY=0xabc run "$skill" give-feedback.sh "not-a-number" 85
  assert_rc 1 "non-numeric agent id is rejected"
  assert_no_cast_send "invalid input sent no transaction"

  NETWORK="$testnet" PRIVATE_KEY=0xabc run "$skill" give-feedback.sh 1 "abc"
  assert_rc 1 "non-integer feedback value is rejected"

  run "$skill" check-agent.sh
  assert_rc 1 "check-agent with no argument shows usage"

  # --- The happy path on a testnet still works end to end. ---
  NETWORK="$testnet" PRIVATE_KEY=0xabc run "$skill" register.sh "https://example.com/a.json"
  assert_rc 0 "testnet register succeeds"
  if printf '%s' "$RUN_CAST" | grep -q 'confirmations 1'; then
    ok "register waits for a confirmation"
  else
    bad "register waits for a confirmation"
  fi

  # --- ERC8004_YES is the documented automation escape hatch. ---
  NETWORK=mainnet ERC8004_YES=1 PRIVATE_KEY=0xabc run "$skill" give-feedback.sh 1 85 starred
  assert_rc 0 "ERC8004_YES=1 allows mainnet in automation"
  assert_contains "$mainnet_id" "ERC8004_YES path targets mainnet"
done

printf '\n%s%d passed, %d failed%s\n' "$BOLD" "$PASS" "$FAIL" "$RESET"
[ "$FAIL" -eq 0 ]
