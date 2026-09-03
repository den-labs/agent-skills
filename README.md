# DEN Labs Agent Skills

> **DenLabs Lab** · SDK
> Installable AI agent skills for on-chain identity, reputation, and open-source contribution.

## Installation

```bash
npx skills add den-labs/agent-skills
```

Works with Claude Code, Cursor, Windsurf, Cline, GitHub Copilot, Gemini CLI, and 20+ other agents that consume installable skills.

## Available Skills

| Skill | Type | What it does |
|---|---|---|
| [**erc8004-celo**](skills/erc8004-celo/) | Blockchain | Register and manage AI agent identities on Celo via ERC-8004, plus Celo-native capabilities for agents: stablecoin gas (CIP-64), x402 payments, Self, Agent Visa |
| [**erc8004-avalanche**](skills/erc8004-avalanche/) | Blockchain | Register and manage AI agent identities on Avalanche via ERC-8004, plus Avalanche L1s, ICM/Teleporter, and AvaCloud |
| [**trust-score**](skills/trust-score/) | Oracle | Query ERC-8004 agent trust scores, reputation, and risk signals from DenScope (Celo) and Ayni (Avalanche) |
| [**alchemy-contribute**](skills/alchemy-contribute/) | DevTools / OSS | Automate the end-to-end contribution flow to any Alchemy open-source repo — fork, clone, branch, lint, commit, push, PR |

Each skill's `SKILL.md` is the authoritative documentation. Contract addresses live in each skill's `references/contract-addresses.md` so there is one place to update them.

## ERC-8004 skills

[ERC-8004 (Trustless Agents)](https://eips.ethereum.org/EIPS/eip-8004) gives autonomous agents a verifiable on-chain identity and portable reputation. The Identity and Reputation registries are deterministic deployments at the same addresses across 40+ chains; the **Validation Registry is not deployed anywhere yet** and that part of the spec is still under revision.

The Celo and Avalanche skills are kept separate on purpose. The ERC-8004 core is identical, and lives in one place (`skills/_shared/erc8004/lib.sh`, vendored into each skill with drift enforced by the test suite). What differs is everything each ecosystem actually cares about — stablecoin gas and agent payment rails on Celo, dedicated L1s and cross-chain messaging on Avalanche — and that belongs in a chain-specific skill.

**Safety defaults:** the on-chain scripts default to a testnet, require an explicit typed confirmation before spending on mainnet, refuse to touch mainnet from a non-interactive shell unless `ERC8004_YES=1` is set, and prefer encrypted keystores and hardware wallets over a raw `PRIVATE_KEY`.

## Development

```bash
./scripts/validate-skills.sh          # structure, frontmatter, links, lint, secrets
./tests/test-safety.sh                # on-chain script safety guarantees (cast is stubbed)
./scripts/sync-shared.sh              # re-vendor the shared ERC-8004 library
./scripts/sync-shared.sh --check      # fail if any vendored copy has drifted
```

Both suites run in CI on every push and pull request. See [CONTRIBUTING.md](CONTRIBUTING.md) before opening a PR.

Requires `bash`, `jq`, and `shellcheck`. The ERC-8004 scripts additionally need Foundry (`cast`) at runtime.

## Links

- [ERC-8004 Spec](https://eips.ethereum.org/EIPS/eip-8004)
- [erc-8004-contracts](https://github.com/erc-8004/erc-8004-contracts)
- [8004.org](https://www.8004.org) · [8004scan explorer](https://8004scan.io)

## License

Licensed under the Wolfcito Open / Commercial License (WOCL). Commercial use requires a separate agreement. See [LICENSE](LICENSE).
