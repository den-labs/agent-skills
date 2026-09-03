#!/usr/bin/env bash
# Validate every skill in skills/ for structural and content correctness.
# Usage: ./scripts/validate-skills.sh [skill-name ...]
# Exit code 0 = all checks pass, 1 = at least one failure.

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKILLS_DIR="$REPO_ROOT/skills"

PASS=0
FAIL=0
WARN=0
CURRENT_SKILL=""

if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
  RED=$'\033[31m'; GREEN=$'\033[32m'; YELLOW=$'\033[33m'; BOLD=$'\033[1m'; RESET=$'\033[0m'
else
  RED=""; GREEN=""; YELLOW=""; BOLD=""; RESET=""
fi

pass() { PASS=$((PASS + 1)); [ -n "${VERBOSE:-}" ] && echo "  ${GREEN}ok${RESET}   $1"; return 0; }
fail() { FAIL=$((FAIL + 1)); echo "  ${RED}FAIL${RESET} [$CURRENT_SKILL] $1"; return 0; }
warn() { WARN=$((WARN + 1)); echo "  ${YELLOW}warn${RESET} [$CURRENT_SKILL] $1"; return 0; }

# Extract the YAML frontmatter block (between the first two --- lines).
frontmatter() {
  awk 'NR==1 && $0!="---" { exit } NR==1 { next } /^---$/ { exit } { print }' "$1"
}

# Read a top-level scalar key from frontmatter. Handles values containing colons.
fm_value() {
  frontmatter "$1" | awk -v key="$2" '
    $0 ~ "^" key ":" { sub("^" key ":[ \t]*", ""); print; exit }
  '
}

# Resolve the official Agent Skills reference validator once. It is the
# authority on frontmatter; this script must never invent competing rules.
SKILLS_REF=""
resolve_skills_ref() {
  if command -v skills-ref >/dev/null 2>&1; then
    SKILLS_REF="skills-ref"
  elif command -v npx >/dev/null 2>&1 \
      && npx --yes skills-ref@latest --version >/dev/null 2>&1; then
    SKILLS_REF="npx --yes skills-ref@latest"
  fi
}

# The spec is the source of truth for frontmatter: name, description, license,
# compatibility, metadata, allowed-tools. Anything else fails validation.
check_frontmatter() {
  local skill_dir="$1"

  if [ -z "$SKILLS_REF" ]; then
    warn "official validator unavailable — frontmatter not checked against the spec"
  else
    local out
    if out="$($SKILLS_REF validate "$skill_dir" 2>&1)"; then
      pass "passes skills-ref validate"
    else
      fail "fails the official Agent Skills spec:"
      printf '%s\n' "$out" | sed 's/^/         /'
    fi
  fi

  # Not covered by skills-ref: we require a semver version under metadata so
  # releases are traceable. A top-level `version:` key is NOT valid — the spec
  # allows only the six fields above, and metadata values must be strings.
  local skill_md="$skill_dir/SKILL.md" version
  version="$(awk '
    NR==1 && $0!="---" { exit }
    NR==1 { next }
    /^---$/ { exit }
    /^version:/ { print "TOPLEVEL"; exit }
    /^metadata:/ { inmeta=1; next }
    inmeta && /^[^ \t]/ { inmeta=0 }
    inmeta && /^[ \t]+version:/ {
      sub(/^[ \t]+version:[ \t]*/, ""); gsub(/"/, ""); print; exit
    }
  ' "$skill_md")"

  case "$version" in
    TOPLEVEL)
      fail "'version' is a top-level key — the spec forbids it; move it under 'metadata'" ;;
    "")
      warn "no metadata.version — releases will not be traceable" ;;
    *)
      if printf '%s' "$version" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+$'; then
        pass "metadata.version $version is valid semver"
      else
        fail "metadata.version '$version' is not semver (MAJOR.MINOR.PATCH)"
      fi ;;
  esac
}

check_links() {
  local skill_md="$1" skill_dir="$2"
  # Markdown links to relative paths: [text](path) where path has no scheme and no anchor-only target.
  local target
  while IFS= read -r target; do
    [ -z "$target" ] && continue
    case "$target" in
      http://*|https://*|mailto:*|\#*) continue ;;
    esac
    target="${target%%#*}"
    [ -z "$target" ] && continue
    if [ ! -e "$skill_dir/$target" ]; then
      fail "SKILL.md links to '$target' which does not exist"
    else
      pass "link $target resolves"
    fi
  done < <(grep -oE '\]\([^)]+\)' "$skill_md" | sed -E 's/^\]\(//; s/\)$//')
}

check_script_refs() {
  local skill_md="$1" skill_dir="$2"
  local ref
  while IFS= read -r ref; do
    [ -z "$ref" ] && continue
    if [ ! -e "$skill_dir/${ref#./}" ]; then
      fail "SKILL.md references script '$ref' which does not exist"
    else
      pass "script reference $ref exists"
    fi
  done < <(grep -oE '\./scripts/[A-Za-z0-9_.-]+\.sh' "$skill_md" | sort -u)
}

check_scripts() {
  local skill_dir="$1"
  [ -d "$skill_dir/scripts" ] || return 0

  local script
  for script in "$skill_dir"/scripts/* "$skill_dir"/scripts/lib/*; do
    [ -f "$script" ] || continue
    local rel="${script#"$REPO_ROOT"/}"

    # Files under scripts/lib/ are sourced by other scripts, never run directly.
    if [[ "$script" == */scripts/lib/* ]]; then
      if [ -x "$script" ]; then
        fail "$rel is a sourced library and must not be executable"
      else
        pass "$rel is non-executable (sourced library)"
      fi
    elif [ ! -x "$script" ]; then
      fail "$rel is not executable (chmod +x)"
    else
      pass "$rel is executable"
    fi

    if ! head -1 "$script" | grep -q '^#!'; then
      fail "$rel has no shebang"
    else
      pass "$rel has a shebang"
    fi

    if ! bash -n "$script" 2>/dev/null; then
      fail "$rel has a bash syntax error"
    else
      pass "$rel parses"
    fi

    # Every bash script that can touch the network or a key must fail fast.
    if [[ "$script" != */scripts/lib/* ]] \
        && head -1 "$script" | grep -q 'bash' \
        && ! grep -q 'set -euo pipefail' "$script"; then
      fail "$rel does not 'set -euo pipefail'"
    else
      pass "$rel sets strict mode"
    fi

    if command -v shellcheck >/dev/null 2>&1; then
      if ! shellcheck -S warning "$script" >/dev/null 2>&1; then
        fail "$rel has shellcheck warnings — run: shellcheck $rel"
      else
        pass "$rel passes shellcheck"
      fi
    fi
  done
}

check_secrets() {
  local skill_dir="$1"
  local hits

  # Flag 32-byte hex literals only where they would actually be a secret:
  # assigned to a key/seed variable or passed straight to a signing flag.
  # Bare 64-hex constants (event topics, the zero hash) are legitimate.
  hits="$(grep -rEn \
    -e '(PRIVATE_KEY|SECRET_KEY|MNEMONIC|SEED_PHRASE)[[:space:]]*=[[:space:]]*.?0x[0-9a-fA-F]{64}' \
    -e '--private-key[[:space:]]+0x[0-9a-fA-F]{64}' \
    "$skill_dir" --include='*.sh' --include='*.md' --include='*.json' 2>/dev/null || true)"

  if [ -n "$hits" ]; then
    fail "hardcoded signing key literal found:"
    printf '%s\n' "$hits" | sed 's/^/         /'
  else
    pass "no hardcoded signing keys"
  fi

  # A mnemonic committed as prose is just as bad as one in a variable.
  if grep -rEqn '\b(abandon|zoo)([[:space:]]+[a-z]+){10,}' "$skill_dir" \
      --include='*.sh' --include='*.md' --include='*.json' 2>/dev/null; then
    fail "what looks like a BIP-39 mnemonic phrase is committed"
  else
    pass "no committed mnemonic phrases"
  fi
}

check_readme_listing() {
  local skill_name="$1"
  if ! grep -q "$skill_name" "$REPO_ROOT/README.md"; then
    fail "not mentioned in README.md"
  else
    pass "listed in README.md"
  fi
}

main() {
  local skills=("$@")
  if [ ${#skills[@]} -eq 0 ]; then
    local d
    for d in "$SKILLS_DIR"/*/; do
      [ -d "$d" ] || continue
      case "$(basename "$d")" in _*) continue ;; esac
      skills+=("$(basename "$d")")
    done
  fi

  if [ ${#skills[@]} -eq 0 ]; then
    echo "${RED}No skills found in $SKILLS_DIR${RESET}"
    exit 1
  fi

  echo "${BOLD}Validating ${#skills[@]} skill(s)${RESET}"
  resolve_skills_ref
  if [ -n "$SKILLS_REF" ]; then
    echo "  using official validator: $SKILLS_REF"
  else
    echo "  ${YELLOW}note${RESET} skills-ref unavailable (needs node/npx) — spec checks skipped"
  fi
  command -v shellcheck >/dev/null 2>&1 || echo "  ${YELLOW}note${RESET} shellcheck not installed — skipping lint checks"
  echo

  local skill_name skill_dir skill_md
  for skill_name in "${skills[@]}"; do
    CURRENT_SKILL="$skill_name"
    skill_dir="$SKILLS_DIR/$skill_name"
    skill_md="$skill_dir/SKILL.md"

    echo "${BOLD}$skill_name${RESET}"

    if [ ! -d "$skill_dir" ]; then
      fail "directory does not exist"
      continue
    fi
    if [ ! -f "$skill_md" ]; then
      fail "has no SKILL.md"
      continue
    fi

    check_frontmatter "$skill_dir"
    check_links "$skill_md" "$skill_dir"
    check_script_refs "$skill_md" "$skill_dir"
    check_scripts "$skill_dir"
    check_secrets "$skill_dir"
    check_readme_listing "$skill_name"
  done

  CURRENT_SKILL="_shared"
  echo
  echo "${BOLD}shared library${RESET}"
  if [ -x "$REPO_ROOT/scripts/sync-shared.sh" ]; then
    if "$REPO_ROOT/scripts/sync-shared.sh" --check 2>&1 | grep -q DRIFT; then
      fail "vendored copies of skills/_shared/erc8004/lib.sh have drifted — run ./scripts/sync-shared.sh"
    else
      pass "vendored shared library is in sync across skills"
    fi
  fi

  CURRENT_SKILL=""
  echo
  echo "${BOLD}$PASS passed, $FAIL failed, $WARN warnings${RESET}"

  [ "$FAIL" -eq 0 ] || exit 1
}

main "$@"
