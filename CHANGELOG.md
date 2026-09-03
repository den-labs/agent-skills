# Changelog

All notable changes to this project are documented here.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and each skill carries its own semver `version` in its `SKILL.md` frontmatter.

## [1.3.0] - 2026-09-03

### Added

- `license` and `compatibility` frontmatter on all four skills. Both are spec fields that existed all along; the environment requirements had been written as prose in the body instead.
- `trust-score`: `get-signals.sh` (risk signals) and `get-events.sh` (on-chain history), completing the five endpoints the skill documents.
- `scripts/check-links.sh` plus a CI job. Ecosystem programme links are the fastest-rotting content in the skills.
- `references/registration-format.md` now documents every field, the `supportedTrust` values, and the environment variables `register.sh ipfs` reads.

### Fixed

- **A dead link shipped in 1.0.0**: `celopg.eco/insights/build-your-agent-on-celo` returns 404. Replaced with `docs.celo.org/build-on-celo/build-with-ai/overview`, verified 200.
- Celo fee-abstraction links pointed at `/developer/fee-abstraction`, which redirects; they now use the canonical `/build-on-celo/fee-abstraction/overview`.
- `CONTRIBUTING.md` still told contributors to put `version` at the top level of frontmatter — the exact mistake that broke every skill in 1.0.0. It now documents `metadata.version` and points at `skills-ref` as the authority.

### Known limitation

`get-signals.sh` and `get-events.sh` could not be verified against a live API: every `/api/v1/*` path on both oracles returns 401 and no key was available. They follow the documented schema and print the raw body rather than failing silently if a field name differs.

## [1.2.0] - 2026-09-03

### Added

- **Lifecycle operations.** The skills could create an identity and write feedback, but not maintain either — no way to update an agent's URI, revoke feedback, or read reputation back, all of which the documentation said were possible.
  - `read-feedback.sh` — reputation summary and reviewer list. Read-only, so it needs only `curl` and `jq`. Supports tag filtering.
  - `update-agent.sh` — repoints an identity at a new registration file via `setAgentURI`. Checks ownership before spending gas.
  - `revoke-feedback.sh` — withdraws feedback via `revokeFeedback`.
- **URI reachability pre-flight.** `register.sh` and `update-agent.sh` now verify the registration file resolves before minting or updating. An identity pointing at a 404 costs gas and is permanent. `SKIP_URI_CHECK=1` bypasses it.
- ABI helpers for reading structured returns: `e8_decode_uint`, `e8_decode_int128` (two's complement), `e8_decode_address_array`, `e8_encode_string_tail`.
- A script reference table in both SKILL.md files showing which scripts write and which need Foundry.

### Fixed

- `validate-skills.sh` now rejects bash 4+ builtins (`mapfile`, `readarray`, `${x^^}`, `${x,,}`, associative arrays). macOS ships bash 3.2, where `mapfile` does not exist — caught after shipping it in a first draft of `read-feedback.sh`.

### Notes

All function signatures were taken from the deployed contracts' verified ABIs (resolved through the ERC-1967 proxies), not from documentation: `register(string)`, `setAgentURI(uint256,string)`, `giveFeedback(uint256,int128,uint8,string,string,string,string,bytes32)`, `revokeFeedback(uint256,uint64)`, `getSummary(uint256,address[],string,string)`, `getClients(uint256)`. Selectors were computed with keccak256 and cross-checked against the two already proven live.

## [1.1.0] - 2026-09-03

### Changed

- **`check-agent.sh` no longer needs Foundry.** Reads are plain `eth_call`, so requiring a Rust toolchain just to ask who owns an agent was disproportionate. The read path now uses only `curl` and `jq`; `cast` remains required for signing, which bash cannot do. Verified against Celo mainnet, Celo Sepolia, Avalanche C-Chain and Fuji with `cast` replaced by a stub that fails if invoked.
- A reverted `ownerOf` is now reported as "not registered" rather than as an RPC error — that revert is how ERC-721 expresses an unminted token, not a failure.
- Long agent URIs are summarised instead of flooding the terminal. Some agents inline their whole registration document as a gzipped base64 `data:` URI; agent #1 on Celo is 1602 characters. `FULL_URI=1` prints it verbatim.

### Added

- `tests/test-reads.sh` — unit tests for the ABI encode/decode helpers plus live integration tests against all four networks. 28 checks, no gas, no signer.
- CI job running the read path against live chains (informational, since it depends on public RPCs).
- ABI helpers in the shared library: `e8_rpc`, `e8_eth_call`, `e8_encode_uint256`, `e8_decode_address`, `e8_decode_string`.

## [1.0.1] - 2026-09-03

### Fixed

- **All four skills failed the official Agent Skills spec.** `version` was added as a top-level frontmatter key in 1.0.0, but the spec allows only `name`, `description`, `license`, `compatibility`, `metadata` and `allowed-tools`. Version now lives at `metadata.version` as a string, and `skills-ref validate` passes on all four.
- `scripts/validate-skills.sh` now delegates frontmatter checking to the official `skills-ref` validator instead of enforcing its own invented rules — the previous version actively *required* the key that broke the spec, and reported 104 passing checks while every skill was invalid.
- CI runs `skills-ref validate` per skill. It validates only its first path argument and ignores the rest, so each skill is a separate invocation.
- `references/contract-addresses.md` for both chains now carries the "no Validation Registry deployed" note that 1.0.0 added only to `SKILL.md` and `api-reference.md`.

## [1.0.0] - 2026-09-03

### Added

- Shared ERC-8004 helper library (`skills/_shared/erc8004/lib.sh`), vendored into each ERC-8004 skill with drift enforced by the test suite.
- Test suite: `scripts/validate-skills.sh` (structure, frontmatter, links, shellcheck, secret scan) and `tests/test-safety.sh` (on-chain script guarantees, with `cast` stubbed).
- `scripts/verify-addresses.sh` — checks every documented registry address actually has code deployed on the network the docs claim.
- GitHub Actions CI running both suites plus the address check on every push and pull request.
- Keystore, Ledger, and Trezor signing via `ERC8004_ACCOUNT` / `ERC8004_LEDGER` / `ERC8004_TREZOR`.
- `register.sh` now reports the new agent ID, decoded from the ERC-721 `Transfer` event.
- Celo skill: sections on CIP-64 stablecoin gas, x402 agent payments, Self proof-of-humanity, MiniPay, the Celo Agent Visa and Divvi programs, and Celo's L2 migration.
- Avalanche skill: sections on running an agent on its own Avalanche L1, ICM/Teleporter for cross-chain calls, AvaCloud, Avalanche9000, and Retro9000.
- `CONTRIBUTING.md`, `CHANGELOG.md`, `.editorconfig`, `.gitignore`, and a pull request template.

### Changed

- **Breaking:** on-chain scripts now default to a testnet (Celo Sepolia / Fuji) instead of mainnet. Set `NETWORK=mainnet` explicitly for the real chain.
- **Breaking:** mainnet transactions require a typed confirmation, and are refused in non-interactive shells unless `ERC8004_YES=1` is set.
- `register.sh` and `give-feedback.sh` now wait for a confirmation and fail on revert instead of reporting unverified success.
- JSON is parsed with `jq` rather than `grep`/`cut`; the IPFS temp file honours `TMPDIR` and is cleaned up by a trap.
- Agent IDs and feedback values are validated before any gas is spent.
- `README.md` rewritten as an index; contract addresses now live only in each skill's `references/contract-addresses.md`.

### Fixed

- `trust-score` was missing from the README entirely.
- Unused `WALLET_ADDRESS` in the Avalanche `register.sh`.
- A prior `npx skills add` had replaced `skills/alchemy-contribute` with a symlink into `.agents/`, which git recorded as a deletion of all three source files. Restored, and the install artifacts are now ignored.

### Documented

- The **Validation Registry is not deployed on any chain** and that part of the ERC-8004 spec is still under revision. The skills previously documented its API as if it were usable.
- ERC-8004 is still a **Draft** EIP.

## [0.1.0]

Initial skills: `erc8004-avalanche`, `erc8004-celo`, `trust-score`, `alchemy-contribute`.
