# DEN Labs Agent Skills

> **DenLabs Lab** · SDK
> Installable AI agent skills for on-chain identity and reputation via ERC-8004.

## Installation

```bash
npx skills add den-labs/agent-skills
```

## Available Skills

| Skill | Type | Description |
|---|---|---|
| **erc8004-avalanche** | Blockchain | Register and manage AI agent identities on Avalanche using ERC-8004 (Trustless Agents) |
| **erc8004-celo** | Blockchain | Register and manage AI agent identities on Celo using ERC-8004 (Trustless Agents) |
| **alchemy-contribute** | DevTools / OSS | Automate the end-to-end contribution flow to any Alchemy open-source repo — fork, clone, upstream, branch, lint, commit, push, PR — with confirmation gates only on irreversible steps |

## erc8004-avalanche

Register your AI agent on Avalanche C-Chain with a verifiable on-chain identity, making it discoverable and enabling trust signals through reputation and validation.

**Contract Addresses:**

| Network | Identity Registry | Reputation Registry |
|---|---|---|
| Avalanche Mainnet (43114) | `0x8004A169FB4a3325136EB29fA0ceB6D2e539a432` | `0x8004BAa17C55a88189AE136b182e5fdA19dE9b63` |
| Avalanche Fuji (43113) | `0x8004A818BFB912233c491871b3d84c89A494BD9e` | `0x8004B663056A597Dffe9eCcC1965A193B7388713` |

## erc8004-celo

Register your AI agent on Celo with a verifiable on-chain identity, making it discoverable and enabling trust signals through reputation and validation.

**Contract Addresses:**

| Network | Identity Registry | Reputation Registry |
|---|---|---|
| Celo Mainnet (42220) | `0x8004A169FB4a3325136EB29fA0ceB6D2e539a432` | `0x8004BAa17C55a88189AE136b182e5fdA19dE9b63` |
| Celo Sepolia (11142220) | `0x8004A818BFB912233c491871b3d84c89A494BD9e` | `0x8004B663056A597Dffe9eCcC1965A193B7388713` |

## alchemy-contribute

Ship a Pull Request to any Alchemy open-source repository (`alchemyplatform/*`) in a single conversation. The skill automates the 11 steps of the official Alchemy Contribution Checklist and asks for confirmation only at irreversible boundaries (fork, push, PR open).

**What it covers:**

- Reads `CONTRIBUTING.md` first and honors repo-specific overrides
- Detects the package manager (pnpm / bun / yarn / npm / cargo / forge / go) from lockfiles
- Surfaces docs-repo specifics: `content/docs.yml` nav manifest, generated `content/api-specs/`, Cloudinary-hosted images, `pnpm run validate` and broken-link checks
- Resolves the upstream default branch dynamically (`main` vs `master` vs `develop`)
- Resumes mid-flow when the user has already done part of the setup
- Generates Conventional Commits messages and PR bodies that match each repo's template

**Triggers:** "contribuir a alchemy", "abrir PR a aa-sdk", "fork alchemyplatform", "PR en alchemy-sdk-js", "contribuir docs alchemy".

**Built for:** Claude Code, Codex, Cursor, Windsurf, and any other agent that consumes installable skills.

## Features

- Register AI agents on-chain (ERC-721 NFT identity)
- Give and read reputation feedback
- Request third-party validation
- Scripts for registration, checking agents, and giving feedback
- Full TypeScript examples with viem and ethers.js

**Links:**
- [ERC-8004 Spec](https://eips.ethereum.org/EIPS/eip-8004)
- [8004.org](https://www.8004.org)

## Compatibility

Works with 20+ AI agents including:

Claude Code, Cursor, Windsurf, Cline, GitHub Copilot, Gemini CLI, and more.

## License

This project is licensed under the Wolfcito Open / Commercial License (WOCL).
Commercial use requires a separate agreement.
