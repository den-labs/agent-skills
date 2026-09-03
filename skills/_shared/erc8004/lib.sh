#!/usr/bin/env bash
# ERC-8004 shared helpers — canonical source: skills/_shared/erc8004/lib.sh
#
# This file is vendored verbatim into each skill at scripts/lib/erc8004.sh so
# that every skill stays self-contained when installed on its own. Do not edit
# a vendored copy: edit the canonical file and run ./scripts/sync-shared.sh.
# validate-skills.sh fails the build if any copy drifts.
#
# shellcheck shell=bash

# --- Output -----------------------------------------------------------------

if [ -t 2 ] && [ -z "${NO_COLOR:-}" ]; then
  E8_RED=$'\033[31m'; E8_GREEN=$'\033[32m'; E8_YELLOW=$'\033[33m'
  E8_BOLD=$'\033[1m'; E8_RESET=$'\033[0m'
else
  E8_RED=""; E8_GREEN=""; E8_YELLOW=""; E8_BOLD=""; E8_RESET=""
fi

e8_info()  { printf '%s\n' "$*" >&2; }
e8_ok()    { printf '%s%s%s\n' "$E8_GREEN" "$*" "$E8_RESET" >&2; }
e8_warn()  { printf '%swarning:%s %s\n' "$E8_YELLOW" "$E8_RESET" "$*" >&2; }
e8_die()   { printf '%serror:%s %s\n' "$E8_RED" "$E8_RESET" "$*" >&2; exit 1; }

# --- Preconditions ----------------------------------------------------------

# e8_require_cmd <command> <install hint>
e8_require_cmd() {
  command -v "$1" >/dev/null 2>&1 || e8_die "'$1' is required. $2"
}

e8_require_foundry() {
  e8_require_cmd cast "Install Foundry: curl -L https://foundry.paradigm.xyz | bash && foundryup"
}

e8_require_jq() {
  e8_require_cmd jq "Install it: brew install jq  (or apt-get install jq)"
}

e8_require_curl() {
  e8_require_cmd curl "Install it: brew install curl"
}

# --- Reading the chain (no Foundry) -----------------------------------------
#
# Reads are plain eth_call: a JSON-RPC POST with hex calldata. Requiring a Rust
# toolchain just to ask who owns an agent is disproportionate, so the read path
# needs only curl and jq. Signing still needs `cast` — bash cannot do secp256k1.

# e8_rpc <rpc-url> <method> <params-json> — returns the `result` field.
#
# A reverted eth_call is a normal answer, not a failure: ERC-721 ownerOf reverts
# for an unminted token, which is how "not registered" is expressed. Those
# return status 2 with no message so the caller can interpret them. Transport
# failures and other RPC errors still abort.
e8_rpc() {
  local rpc_url="$1" method="$2" params="$3"

  local response
  response="$(curl -sS -m 30 -X POST "$rpc_url" \
    -H 'content-type: application/json' \
    --data "$(jq -nc --arg m "$method" --argjson p "$params" \
      '{jsonrpc:"2.0",id:1,method:$m,params:$p}')" 2>&1)" \
    || e8_die "RPC request to $rpc_url failed:
$response"

  local err
  err="$(printf '%s' "$response" | jq -r '.error.message // empty' 2>/dev/null)"
  if [ -n "$err" ]; then
    case "$err" in
      *"execution reverted"*|*"revert"*) return 2 ;;
      *) e8_die "RPC error from $rpc_url: $err" ;;
    esac
  fi

  printf '%s' "$response" | jq -r '.result // empty'
}

# e8_encode_uint256 <n> — left-pads an integer to a 32-byte hex word.
e8_encode_uint256() {
  local n="$1"
  printf '%s' "$n" | grep -qE '^[0-9]+$' || e8_die "Not an unsigned integer: '$n'"
  # printf %x is limited to 64-bit. Real agent IDs are sequential and nowhere
  # near that, so refuse loudly rather than silently encode the wrong value.
  [ "${#n}" -le 19 ] && [ "$n" -le 9223372036854775807 ] 2>/dev/null \
    || e8_die "Value '$n' exceeds the 64-bit range this encoder supports."
  printf '%064x' "$n"
}

# e8_eth_call <rpc-url> <to> <calldata> — returns the raw hex result.
e8_eth_call() {
  local rpc_url="$1" to="$2" data="$3"
  e8_rpc "$rpc_url" eth_call \
    "$(jq -nc --arg to "$to" --arg data "$data" '[{to:$to,data:$data},"latest"]')"
}

# e8_decode_address <32-byte-word> — the low 20 bytes, 0x-prefixed.
e8_decode_address() {
  local word="${1#0x}"
  [ "${#word}" -ge 64 ] || return 1
  printf '0x%s' "$(printf '%s' "${word:24:40}" | tr 'A-Z' 'a-z')"
}

# e8_decode_string <abi-encoded-return> — decodes a single dynamic string.
# Layout: [32b offset][32b length][data, right-padded to a 32-byte boundary].
e8_decode_string() {
  local hex="${1#0x}"
  [ "${#hex}" -ge 128 ] || return 1

  # Honour the offset rather than assuming the data starts at word 1.
  local offset_hex offset
  offset_hex="$(printf '%s' "${hex:0:64}" | sed 's/^0*//')"
  if [ -z "$offset_hex" ]; then
    offset=0
  else
    offset=$((16#$offset_hex))
  fi

  local length_hex length
  length_hex="$(printf '%s' "${hex:$((offset * 2)):64}" | sed 's/^0*//')"
  if [ -z "$length_hex" ]; then
    printf ''
    return 0
  fi
  length=$((16#$length_hex))

  local data="${hex:$((offset * 2 + 64)):$((length * 2))}"
  [ "${#data}" -eq $((length * 2)) ] || return 1

  # Hex pairs to bytes, without spawning a subprocess per character.
  printf '%b' "$(printf '%s' "$data" | sed 's/../\\x&/g')"
}

# --- Signing ----------------------------------------------------------------
#
# Resolves how cast should sign, in order of decreasing safety:
#   ERC8004_ACCOUNT   -> cast keystore account   (--account, prompts for its passphrase)
#   ERC8004_LEDGER=1  -> Ledger hardware wallet  (--ledger)
#   ERC8004_TREZOR=1  -> Trezor hardware wallet  (--trezor)
#   PRIVATE_KEY       -> raw key in the environment (discouraged, warns)
#
# Populates the global array E8_SIGNER_ARGS.
e8_resolve_signer() {
  E8_SIGNER_ARGS=()

  if [ -n "${ERC8004_ACCOUNT:-}" ]; then
    E8_SIGNER_ARGS=(--account "$ERC8004_ACCOUNT")
    e8_info "Signing with keystore account: $ERC8004_ACCOUNT"
  elif [ "${ERC8004_LEDGER:-}" = "1" ]; then
    E8_SIGNER_ARGS=(--ledger)
    [ -n "${ERC8004_HD_PATH:-}" ] && E8_SIGNER_ARGS+=(--mnemonic-derivation-path "$ERC8004_HD_PATH")
    e8_info "Signing with Ledger hardware wallet"
  elif [ "${ERC8004_TREZOR:-}" = "1" ]; then
    E8_SIGNER_ARGS=(--trezor)
    [ -n "${ERC8004_HD_PATH:-}" ] && E8_SIGNER_ARGS+=(--mnemonic-derivation-path "$ERC8004_HD_PATH")
    e8_info "Signing with Trezor hardware wallet"
  elif [ -n "${PRIVATE_KEY:-}" ]; then
    E8_SIGNER_ARGS=(--private-key "$PRIVATE_KEY")
    e8_warn "Using PRIVATE_KEY from the environment. Prefer an encrypted keystore:"
    e8_warn "  cast wallet import my-agent --interactive"
    e8_warn "  export ERC8004_ACCOUNT=my-agent"
  else
    e8_die "No signer configured. Set one of:
  ERC8004_ACCOUNT=<name>  encrypted keystore (recommended; create with 'cast wallet import <name> --interactive')
  ERC8004_LEDGER=1        Ledger hardware wallet
  ERC8004_TREZOR=1        Trezor hardware wallet
  PRIVATE_KEY=<raw hex>   unencrypted key in the environment (discouraged)"
  fi
}

# e8_signer_address <rpc-url> — best-effort sender address, empty if unavailable.
e8_signer_address() {
  if [ -n "${ERC8004_ACCOUNT:-}" ]; then
    cast wallet address --account "$ERC8004_ACCOUNT" 2>/dev/null || true
  elif [ -n "${PRIVATE_KEY:-}" ]; then
    cast wallet address --private-key "$PRIVATE_KEY" 2>/dev/null || true
  fi
}

# --- Confirmation gate ------------------------------------------------------

# e8_confirm_mainnet <network-label> <action description>
# Any transaction that spends real funds must pass through here. Set
# ERC8004_YES=1 to pre-approve in automation.
e8_confirm_mainnet() {
  local network="$1" action="$2"

  case "$network" in
    mainnet|celo|avalanche) ;;
    *) return 0 ;;
  esac

  if [ "${ERC8004_YES:-}" = "1" ]; then
    e8_warn "ERC8004_YES=1 — proceeding on $network without a prompt."
    return 0
  fi

  if [ ! -t 0 ]; then
    e8_die "Refusing to send a $network transaction from a non-interactive shell.
Re-run with ERC8004_YES=1 if this is intentional, or use a testnet."
  fi

  printf '\n%s%s This will send a real transaction on %s and spend gas.%s\n' \
    "$E8_BOLD" "$E8_YELLOW" "$network" "$E8_RESET" >&2
  printf '  %s\n\n' "$action" >&2

  local reply
  read -r -p "Type 'yes' to continue: " reply
  [ "$reply" = "yes" ] || e8_die "Aborted by user."
}

# --- Transactions -----------------------------------------------------------

# e8_send_tx <rpc-url> <to> <signature> [args...]
# Sends a transaction, waits for one confirmation, and fails loudly if the
# transaction reverted. Echoes the transaction hash on stdout.
e8_send_tx() {
  local rpc_url="$1" to="$2" sig="$3"
  shift 3

  local out
  if ! out="$(cast send "$to" "$sig" "$@" \
      --rpc-url "$rpc_url" \
      --confirmations 1 \
      "${E8_SIGNER_ARGS[@]}" \
      --json 2>&1)"; then
    e8_die "Transaction failed to send:
$out"
  fi

  local tx_hash status
  tx_hash="$(printf '%s' "$out" | jq -r '.transactionHash // empty')"
  status="$(printf '%s' "$out" | jq -r '.status // empty')"

  [ -n "$tx_hash" ] || e8_die "Could not read a transaction hash from cast output:
$out"

  # cast reports status as 0x1 (success) or 0x0 (reverted).
  case "$status" in
    0x1|1|"success") ;;
    0x0|0|"failure")
      e8_die "Transaction $tx_hash REVERTED on chain. No state was changed, but gas was spent." ;;
    *)
      e8_warn "Could not determine transaction status (got '${status:-<empty>}'). Verify on the explorer." ;;
  esac

  printf '%s\n' "$tx_hash"
}

# e8_agent_id_from_receipt <rpc-url> <tx-hash>
# Reads the agentId from the ERC-721 Transfer event emitted by register().
# Transfer(address,address,uint256) — topic[3] is the tokenId.
e8_agent_id_from_receipt() {
  local rpc_url="$1" tx_hash="$2"
  local transfer_topic="0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef"

  cast receipt "$tx_hash" --rpc-url "$rpc_url" --json 2>/dev/null \
    | jq -r --arg t "$transfer_topic" '
        [.logs[]? | select(.topics[0] == $t) | .topics[3]] | first // empty
      ' \
    | while read -r hex; do [ -n "$hex" ] && cast to-dec "$hex" 2>/dev/null; done
}

# --- IPFS -------------------------------------------------------------------

# e8_pin_json_to_ipfs <json> <pin name> — echoes ipfs://<cid> on stdout.
e8_pin_json_to_ipfs() {
  local json="$1" pin_name="$2"

  [ -n "${PINATA_JWT:-}" ] || e8_die "PINATA_JWT is required to upload to IPFS.
Get one at https://app.pinata.cloud/developers/api-keys, or pass a URI you host yourself."

  printf '%s' "$json" | jq empty 2>/dev/null || e8_die "Refusing to pin malformed JSON."

  local tmpfile
  tmpfile="$(mktemp "${TMPDIR:-/tmp}/agent-registration-XXXXXX.json")"
  # shellcheck disable=SC2064  # expand tmpfile now, not at trap time
  trap "rm -f '$tmpfile'" RETURN
  printf '%s' "$json" > "$tmpfile"

  e8_info "Uploading registration file to IPFS via Pinata..."

  local response
  response="$(curl -sS --fail-with-body -X POST "https://api.pinata.cloud/pinning/pinFileToIPFS" \
    -H "Authorization: Bearer $PINATA_JWT" \
    -F "file=@$tmpfile" \
    -F "pinataMetadata={\"name\":\"${pin_name}\"}" 2>&1)" \
    || e8_die "Pinata upload failed:
$response"

  local cid
  cid="$(printf '%s' "$response" | jq -r '.IpfsHash // empty')"
  [ -n "$cid" ] || e8_die "Pinata returned no IpfsHash:
$response"

  printf 'ipfs://%s\n' "$cid"
}

# --- Registration document --------------------------------------------------

# e8_registration_json <chain-id> <registry> — builds an ERC-8004 registration
# document from the AGENT_* environment variables. Emits valid JSON via jq.
e8_registration_json() {
  local chain_id="$1" registry="$2"

  local trust_json services_json
  trust_json="$(printf '%s' "${AGENT_SUPPORTED_TRUST:-reputation}" \
    | jq -R 'split(",") | map(gsub("^\\s+|\\s+$"; "")) | map(select(length > 0))')"
  services_json="${AGENT_SERVICES:-[]}"
  printf '%s' "$services_json" | jq empty 2>/dev/null \
    || e8_die "AGENT_SERVICES must be a JSON array, got: $services_json"

  jq -n \
    --arg name "${AGENT_NAME:?AGENT_NAME is required}" \
    --arg description "${AGENT_DESCRIPTION:-}" \
    --arg image "${AGENT_IMAGE:-}" \
    --arg registry "eip155:${chain_id}:${registry}" \
    --argjson x402 "${AGENT_X402_SUPPORT:-false}" \
    --argjson services "$services_json" \
    --argjson trust "$trust_json" \
    '{
      type: "https://eips.ethereum.org/EIPS/eip-8004#registration-v1",
      name: $name,
      description: $description,
      image: $image,
      services: $services,
      x402Support: $x402,
      active: true,
      registrations: [ { agentId: 0, agentRegistry: $registry } ],
      supportedTrust: $trust
    }'
}
