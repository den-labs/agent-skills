# Changelog

All notable changes to this project are documented here.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and each skill carries its own semver `version` in its `SKILL.md` frontmatter.

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
