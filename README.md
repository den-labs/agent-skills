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

## erc8004-avalanche

Register your AI agent on Avalanche C-Chain with a verifiable on-chain identity, making it discoverable and enabling trust signals through reputation and validation.

**What it does:**
- Register AI agents on-chain (ERC-721 NFT identity)
- Give and read reputation feedback
- Request third-party validation
- Full support for Avalanche Mainnet and Fuji Testnet

**Contract Addresses (Avalanche Mainnet):**
- Identity Registry: `0x8004A169FB4a3325136EB29fA0ceB6D2e539a432`
- Reputation Registry: `0x8004BAa17C55a88189AE136b182e5fdA19dE9b63`

**Links:**
- [ERC-8004 Spec](https://eips.ethereum.org/EIPS/eip-8004)
- [8004.org](https://www.8004.org)

## Compatibility

Works with 20+ AI agents including:

Claude Code, Cursor, Windsurf, Cline, GitHub Copilot, Gemini CLI, and more.

## License

This project is licensed under the Wolfcito Open / Commercial License (WOCL).
Commercial use requires a separate agreement.
