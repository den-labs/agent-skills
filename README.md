# DEN Labs Agent Skills

A collection of skills for AI agents. Skills are packaged instructions and scripts that extend agent capabilities.

## Installation

```bash
npx skills add den-labs/agent-skills
```

## Available Skills

| Skill | Type | Description |
|---|---|---|
| **erc8004-avalanche** | Blockchain | Register and manage AI agent identities on Avalanche using ERC-8004 (Trustless Agents) |
| **erc8004-celo** | Blockchain | Register and manage AI agent identities on Celo using ERC-8004 (Trustless Agents) |

## erc8004-avalanche

Register your AI agent on Avalanche C-Chain with a verifiable on-chain identity, making it discoverable and enabling trust signals through reputation and validation.

**Contract Addresses (Avalanche Mainnet):**
- Identity Registry: `0x8004A169FB4a3325136EB29fA0ceB6D2e539a432`
- Reputation Registry: `0x8004BAa17C55a88189AE136b182e5fdA19dE9b63`

## erc8004-celo

Register your AI agent on Celo with a verifiable on-chain identity, making it discoverable and enabling trust signals through reputation and validation.

**Contract Addresses (Celo Mainnet):**
- Identity Registry: `0x8004A169FB4a3325136EB29fA0ceB6D2e539a432`
- Reputation Registry: `0x8004BAa17C55a88189AE136b182e5fdA19dE9b63`

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
