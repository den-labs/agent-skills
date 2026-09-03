# Contributing

Thanks for helping improve DEN Labs Agent Skills.

## Before you open a PR

Both suites must pass. CI runs them on every push and pull request.

```bash
./scripts/validate-skills.sh    # wraps skills-ref, plus links, shellcheck, secrets
./tests/test-safety.sh          # guarantees around the on-chain scripts
./tests/test-reads.sh           # live read path against all four networks
./scripts/check-links.sh        # external links still resolve
```

You need `bash`, `jq`, and `shellcheck` (`brew install jq shellcheck`). Foundry is only needed to run the skills for real — the test suite stubs `cast`.

## Repository layout

```
skills/<skill-name>/
  SKILL.md                  required — frontmatter + documentation
  references/*.md           optional — deep reference material
  scripts/*.sh              optional — executable helpers (mode 755)
  scripts/lib/*.sh          optional — sourced libraries (mode 644, never executable)
  assets/                   optional — templates and fixtures

skills/_shared/erc8004/     canonical shared code, vendored into skills
scripts/                    repo tooling (validation, sync, verification)
tests/                      test suites
```

## Adding a skill

1. Create `skills/<name>/SKILL.md` with frontmatter:

   ```yaml
   ---
   name: <name>              # must match the directory name exactly
   description: ...          # 40–1024 chars; this is what an agent reads to
                             # decide whether to invoke the skill, so make it
                             # say when to use it, not just what it is
   license: ...              # optional
   compatibility: ...        # optional; environment requirements
   metadata:
     version: "1.0.0"        # semver, as a string
   ---
   ```

   Validate with the official reference validator, which is the authority:

   ```bash
   npx skills-ref@latest validate skills/<name>
   ```

2. Add it to the table in `README.md` — the validator fails if a skill is not listed.
3. Make scripts executable (`chmod 755`) and start each with `#!/usr/bin/env bash` and `set -euo pipefail`.
4. Run both suites.

## The shared ERC-8004 library

`skills/_shared/erc8004/lib.sh` is the single source of truth for ERC-8004 helpers. Skills are installed one at a time, so each carries its own vendored copy at `scripts/lib/erc8004.sh`.

**Never edit a vendored copy.** Edit the canonical file, then:

```bash
./scripts/sync-shared.sh
```

`validate-skills.sh` fails if any copy has drifted.

Chain-specific configuration (`scripts/lib/network.sh`) is deliberately *not* shared — that is where each chain's RPCs, registries, and explorers live.

## Writing on-chain scripts

Anything that can spend funds must:

- Default to a **testnet**. Mainnet is always an explicit opt-in.
- Route mainnet through `e8_confirm_mainnet`, which requires a typed confirmation and refuses non-interactive shells unless `ERC8004_YES=1`.
- Send through `e8_send_tx`, which waits for a confirmation and fails on revert. Never report success you have not verified.
- Resolve signing through `e8_resolve_signer` so keystores and hardware wallets work, rather than reading `PRIVATE_KEY` directly.
- Validate inputs *before* spending gas.
- Parse JSON with `jq`, never `grep`/`cut`.

Add a case to `tests/test-safety.sh` for any new guarantee.

## Never commit

Private keys, mnemonics, API keys, `.env` files. A pre-commit hook and the validator both scan for these, but they are a backstop, not a substitute for care.

## Chain-specific skills

ERC-8004 skills are intentionally per-chain rather than unified. The ERC-8004 core is identical everywhere and lives in the shared library; a chain skill exists to carry what is genuinely specific to that ecosystem. When adding one, lead with what makes that chain different for an autonomous agent — not a renamed copy of an existing skill.

## Licensing

This repository is released under the Wolfcito Open / Commercial License
(WOCL), not an OSI-approved open source licence: commercial use requires a
separate agreement. Contributions are welcome, and by opening a pull request
you agree your contribution is licensed on the same terms. If that is a problem
for you, open an issue first rather than spending effort on a PR.

## Commits

Use [Conventional Commits](https://www.conventionalcommits.org/): `feat:`, `fix:`, `docs:`, `test:`, `chore:`, `refactor:`. Keep commits atomic — one logical change each. Report the test result in the commit body when it is relevant.

## Versioning

Each skill carries its own version at `metadata.version` and follows semver.
A top-level `version:` key is **invalid** — the Agent Skills spec allows only
`name`, `description`, `license`, `compatibility`, `metadata` and
`allowed-tools`, and `metadata` values must be strings:

- **MAJOR** — a breaking change to script arguments, environment variables, or behaviour
- **MINOR** — new capability, backwards compatible
- **PATCH** — fixes and documentation

Record changes in `CHANGELOG.md`.
