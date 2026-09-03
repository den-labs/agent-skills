#!/usr/bin/env bash
# Shared helpers for the trust-score scripts.
# shellcheck shell=bash
# shellcheck disable=SC2034  # TS_* variables are consumed by the sourcing script

if [ -t 2 ] && [ -z "${NO_COLOR:-}" ]; then
  TS_RED=$'\033[31m'; TS_BOLD=$'\033[1m'; TS_RESET=$'\033[0m'
else
  TS_RED=""; TS_BOLD=""; TS_RESET=""
fi

ts_die() { printf '%serror:%s %s\n' "$TS_RED" "$TS_RESET" "$*" >&2; exit 1; }

ts_require_jq() {
  command -v jq >/dev/null 2>&1 || ts_die "'jq' is required. Install it: brew install jq"
}

# ts_resolve_oracle <name> — sets TS_BASE_URL.
ts_resolve_oracle() {
  case "$1" in
    denscope) TS_BASE_URL="https://www.denscope.xyz" ;;
    ayni)     TS_BASE_URL="https://ayni.denscope.xyz" ;;
    *)        ts_die "Unknown oracle '$1'. Use 'denscope' or 'ayni'." ;;
  esac
}

# ts_resolve_chain <name-or-id> — sets TS_CHAIN_ID.
ts_resolve_chain() {
  case "$1" in
    celo)          TS_CHAIN_ID=42220 ;;
    celo-sepolia)  TS_CHAIN_ID=11142220 ;;
    skale-base)    TS_CHAIN_ID=1187947933 ;;
    avalanche)     TS_CHAIN_ID=43114 ;;
    fuji)          TS_CHAIN_ID=43113 ;;
    *)
      printf '%s' "$1" | grep -qE '^[0-9]+$' \
        || ts_die "Unknown chain '$1'. Use celo, celo-sepolia, skale-base, avalanche, fuji, or a numeric chain ID."
      TS_CHAIN_ID="$1"
      ;;
  esac
}

ts_api_key() {
  printf '%s' "${TRUST_API_KEY:-${DENSCOPE_API_KEY:-${AYNI_API_KEY:-}}}"
}

# ts_get <url> [require-auth] — echoes the response body, or exits with a
# diagnosis. Makes exactly one request: the previous implementation retried on
# a parse failure, doubling the load and hiding the real error.
ts_get() {
  local url="$1" require_auth="${2:-no}"
  local key; key="$(ts_api_key)"

  if [ "$require_auth" = "yes" ] && [ -z "$key" ]; then
    ts_die "This endpoint needs an API key. Set TRUST_API_KEY (or DENSCOPE_API_KEY / AYNI_API_KEY)."
  fi

  # -L: the oracles redirect canonical API paths; without it every call 301s.
  local curl_args=(-sS -L -m 30 -w '\n%{http_code}')
  [ -n "$key" ] && curl_args+=(-H "Authorization: Bearer ${key}")

  local response
  response="$(curl "${curl_args[@]}" "$url")" || ts_die "Request to $url failed."

  local code body
  code="$(printf '%s' "$response" | tail -1)"
  body="$(printf '%s' "$response" | sed '$d')"

  case "$code" in
    200) printf '%s' "$body" ;;
    401|403) ts_die "HTTP $code — the API key was rejected or lacks access to this endpoint." ;;
    404)     ts_die "HTTP 404 — not found. Check the oracle, chain, and agent ID." ;;
    429)     ts_die "HTTP 429 — rate limited. Retry in a moment." ;;
    *)       ts_die "HTTP $code from $url
$(printf '%s' "$body" | head -3)" ;;
  esac
}
