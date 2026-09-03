---
name: erc8004-celo
metadata:
  version: "1.1.0"
description: Register and manage AI agent identities on Celo using ERC-8004 (Trustless Agents). Use this skill when the user wants to register an AI agent on-chain, give or read reputation feedback, or interact with the ERC-8004 identity and reputation registries on Celo mainnet or Celo Sepolia testnet. Also covers what makes Celo distinct for autonomous agents — paying gas in stablecoins via CIP-64 fee abstraction, x402 agent payments, Self proof-of-humanity, and the Celo Agent Visa and Divvi builder programs.
---

# ERC-8004: Trustless Agents on Celo

Give your AI agent a verifiable on-chain identity on Celo, so it can be discovered, build reputation, and get paid.

## Why Celo for an autonomous agent

Registering on Celo is not just "the same registry with a different chain ID". Three things matter for agents specifically:

1. **Your agent can pay gas in stablecoins.** Celo's CIP-64 fee abstraction lets a transaction specify a `feeCurrency`, so an agent holding only cUSD never needs a CELO balance to operate. This removes the most common way an autonomous agent silently dies.
2. **x402 gives agents a native payment rail.** Celo supports x402, which activates HTTP 402 "Payment Required" for permissionless stablecoin micropayments between agents.
3. **There is a funded on-ramp for agent builders** — the Celo Agent Visa program and Divvi's usage-based Proof of Impact rewards.

See "Celo-specific capabilities" below for how to use each.

## What is ERC-8004?

An Ethereum standard for trustless agent identity and reputation. It defines three registries:

| Registry | Status on Celo | What it does |
|---|---|---|
| **Identity Registry** | Deployed | ERC-721 agent IDs — your agent gets an NFT |
| **Reputation Registry** | Deployed | Feedback and trust signals from other agents and users |
| **Validation Registry** | **Not deployed** | Third-party verification of agent work |

> **The Validation Registry is not usable yet.** That section of the spec is still under active revision with the TEE community, and no Validation Registry address has been published on Celo or any other chain. `references/api-reference.md` documents the proposed interface for planning purposes only — do not build against it yet.

ERC-8004 itself is still a **Draft** EIP. The interfaces below are deployed and stable in practice, but the standard can still change.

Spec: https://eips.ethereum.org/EIPS/eip-8004 · Directory: https://www.8004.org · Explorer: https://8004scan.io

## Contract Addresses

Identity and Reputation are deterministic deployments — the same addresses appear on 40+ chains. Verified on-chain 2026-09-02.

| Chain | Identity Registry | Reputation Registry |
|---|---|---|
| Celo Mainnet (42220) | `0x8004A169FB4a3325136EB29fA0ceB6D2e539a432` | `0x8004BAa17C55a88189AE136b182e5fdA19dE9b63` |
| Celo Sepolia (11142220) | `0x8004A818BFB912233c491871b3d84c89A494BD9e` | `0x8004B663056A597Dffe9eCcC1965A193B7388713` |

Full detail, including how to re-verify these yourself: `references/contract-addresses.md`

## Quick Start

**Scripts default to Celo Sepolia.** Mainnet is always an explicit choice, and asks for confirmation before spending anything.

### 1. Set up a signer

Prefer an encrypted keystore over a raw key in your environment:

```bash
cast wallet import my-agent --interactive   # prompts for the key, then a passphrase
export ERC8004_ACCOUNT=my-agent
```

Hardware wallets work too: `export ERC8004_LEDGER=1`. A raw `PRIVATE_KEY` is still accepted but warns.

### 2. Register your agent

```bash
# Against a registration file you already host
./scripts/register.sh "https://myagent.xyz/agent.json"

# Or build the file and pin it to IPFS in one step
export PINATA_JWT="your-pinata-jwt"
AGENT_NAME="My Agent" AGENT_DESCRIPTION="Does a useful thing" \
  ./scripts/register.sh ipfs
```

The script waits for a confirmation, fails loudly if the transaction reverts, and prints the new agent ID decoded from the ERC-721 `Transfer` event.

### 3. Check a registration

No signer, no gas, no Foundry — just `curl` and `jq`.

```bash
./scripts/check-agent.sh <agent-id>              # Celo Sepolia
NETWORK=mainnet ./scripts/check-agent.sh 1       # Celo mainnet — read-only, no signer needed
```

### 4. Give feedback

```bash
./scripts/give-feedback.sh <agent-id> 85 starred
VALUE_DECIMALS=2 ./scripts/give-feedback.sh 1 9950 uptime   # 99.50%
```

### Going to mainnet

```bash
NETWORK=mainnet ./scripts/register.sh "https://myagent.xyz/agent.json"
# → prompts: "This will send a real transaction on mainnet and spend gas."
```

In CI or any non-interactive shell the scripts refuse to touch mainnet unless you set `ERC8004_YES=1` deliberately.

## Celo-specific capabilities

### Pay gas in stablecoins (CIP-64 fee abstraction)

Celo transactions accept a `feeCurrency` field naming an ERC-20 to pay gas in, so an agent funded only in cUSD can transact. This is the single most useful Celo feature for an unattended agent — it never strands itself for lack of the native token.

```typescript
import { createWalletClient, http } from 'viem'
import { celo } from 'viem/chains'

const client = createWalletClient({ chain: celo, transport: http() })

// cUSD on Celo mainnet
const cUSD = '0x765DE816845861e75A25fCA122bb6898B8B1282a'

await client.sendTransaction({
  account,
  to: identityRegistry,
  data: encodedRegisterCall,
  feeCurrency: cUSD,   // gas is paid in cUSD, not CELO
})
```

Supported fee currencies are governed on-chain and include cUSD, cEUR and USDT. Ledger supports CIP-64 signing. Note that `cast` does not expose `feeCurrency`, so the bundled scripts pay gas in CELO — use viem for a stablecoin-funded agent.

Reference: https://docs.celo.org/developer/fee-abstraction

### x402 — getting the agent paid

x402 turns HTTP 402 into a working payment rail: your agent's endpoint answers `402 Payment Required`, the caller pays in stablecoin, and the request proceeds. If your agent charges for anything, set `x402Support: true` in its registration file so callers can discover that.

```json
{ "x402Support": true }
```

Reference: https://docs.celo.org/build-on-celo/build-with-ai/x402

### Self — proof of humanity as a trust signal

Self is Celo's proof-of-humanity protocol. ERC-8004 reputation answers "has this agent behaved well"; Self answers "is a verified human accountable for it". Listing Self in `supportedTrust` alongside `reputation` is a stronger claim than reputation alone.

### MiniPay — distribution to real users

MiniPay has processed 420M+ stablecoin transactions and supports 25 stablecoins, 14 of them local-currency. It uses fee abstraction natively. If your agent serves end users rather than other agents, this is the distribution channel.

### Funding programs

- **Celo Agent Visa** — a program aimed specifically at agent builders, with DeFi incentives.
- **Divvi Proof of Impact** — real-time rewards based on actual usage once your app is live on Celo mainnet.

Start at https://www.celopg.eco/insights/build-your-agent-on-celo

### Celo is an L2

Celo migrated from its own L1 to an Ethereum L2 on the OP Stack in March 2025. Practical consequences: finality and bridging follow OP Stack semantics, not the old Celo L1's. Recent and upcoming upgrades — Jovian (Q1 2026, OP Stack alignment), faster finality via Espresso pre-confirmations (H1 2026), and Fusaka (Q2 2026).

## Registration File Format

See `assets/templates/registration.json` and `references/registration-format.md`.

```json
{
  "type": "https://eips.ethereum.org/EIPS/eip-8004#registration-v1",
  "name": "My Celo Agent",
  "description": "An AI agent operating on Celo",
  "image": "https://example.com/avatar.png",
  "services": [
    { "name": "web", "endpoint": "https://myagent.xyz/" },
    { "name": "A2A", "endpoint": "https://myagent.xyz/.well-known/agent-card.json", "version": "0.3.0" },
    { "name": "MCP", "endpoint": "https://mcp.myagent.xyz/", "version": "2025-06-18" }
  ],
  "x402Support": true,
  "active": true,
  "registrations": [
    {
      "agentId": 1,
      "agentRegistry": "eip155:42220:0x8004A169FB4a3325136EB29fA0ceB6D2e539a432"
    }
  ],
  "supportedTrust": ["reputation"]
}
```

## Key Concepts

### Agent Identity (ERC-721 NFT)
- Each agent gets a unique `agentId` (tokenId) at registration.
- The NFT owner controls the agent's profile and metadata; transferring the NFT transfers control.
- Agents are globally addressed as `eip155:42220:0x8004A169FB4a3325136EB29fA0ceB6D2e539a432` plus `agentId`.

### Reputation
- Anyone can give feedback except the agent owner.
- Feedback carries a value (`int128`) with decimals (0–18) plus up to two tags.
- Common tags: `starred` (quality 0–100), `reachable` (binary), `uptime` (percentage, `VALUE_DECIMALS=2`).
- The original submitter can revoke their feedback; the agent can append a response.
- Feedback is public and permanent. The scripts say so before you send it on mainnet.

## Environment Variables

### Signing — set exactly one

| Variable | Description |
|---|---|
| `ERC8004_ACCOUNT` | Encrypted keystore account name (recommended) |
| `ERC8004_LEDGER` | Set to `1` to sign with a Ledger |
| `ERC8004_TREZOR` | Set to `1` to sign with a Trezor |
| `ERC8004_HD_PATH` | Optional derivation path for a hardware wallet |
| `PRIVATE_KEY` | Raw hex key — discouraged, warns when used |

### Everything else

| Variable | Description | Default |
|---|---|---|
| `NETWORK` | `sepolia` or `mainnet` | `sepolia` |
| `ERC8004_YES` | Set to `1` to skip the mainnet confirmation in automation | unset |
| `CELO_RPC_URL` | Override the RPC endpoint | public Forno RPC |
| `PINATA_JWT` | Pinata JWT, only for IPFS registration | — |
| `AGENT_NAME` | Agent display name — required for `register.sh ipfs` | — |
| `AGENT_DESCRIPTION` | Agent description | empty |
| `AGENT_IMAGE` | Avatar URL | empty |
| `AGENT_SERVICES` | JSON array of service endpoints | `[]` |
| `AGENT_X402_SUPPORT` | `true` or `false` | `false` |
| `AGENT_SUPPORTED_TRUST` | Comma-separated trust models | `reputation` |
| `VALUE_DECIMALS` | Decimal places for a feedback value | `0` |

## Celo Network Details

| Parameter | Mainnet | Celo Sepolia Testnet |
|---|---|---|
| Chain ID | 42220 | 11142220 |
| RPC URL | `https://forno.celo.org` | `https://forno.celo-sepolia.celo-testnet.org` |
| Explorer | https://celoscan.io | https://celo-sepolia.blockscout.com |
| Currency | CELO (or any fee currency) | CELO (test) |
| Faucet | — | https://faucet.celo.org/celo-sepolia |

## Prerequisites

**Reading** (`check-agent.sh`) needs only `curl` and `jq`. Anyone can verify an
agent without installing a toolchain.

**Writing** (`register.sh`, `give-feedback.sh`) additionally needs Foundry,
which signs the transaction and manages keystores and hardware wallets:

```bash
curl -L https://foundry.paradigm.xyz | bash && foundryup
```

Plus a funded account on the target network.

## Using with viem / ethers.js

See `references/api-reference.md` for complete TypeScript examples.

## Links

- [ERC-8004 Spec](https://eips.ethereum.org/EIPS/eip-8004)
- [erc-8004-contracts](https://github.com/erc-8004/erc-8004-contracts)
- [8004.org](https://www.8004.org) · [8004scan explorer](https://8004scan.io)
- [Build your Agent on Celo](https://www.celopg.eco/insights/build-your-agent-on-celo)
- [Celo fee abstraction](https://docs.celo.org/developer/fee-abstraction) · [x402 on Celo](https://docs.celo.org/build-on-celo/build-with-ai/x402)
- [Celoscan](https://celoscan.io)
