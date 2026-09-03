---
name: erc8004-avalanche
metadata:
  version: "1.0.1"
description: Register and manage AI agent identities on Avalanche using ERC-8004 (Trustless Agents). Use this skill when the user wants to register an AI agent on-chain, give or read reputation feedback, or interact with the ERC-8004 identity and reputation registries on Avalanche C-Chain or Fuji testnet. Also covers what makes Avalanche distinct for autonomous agents — running an agent on its own Avalanche L1, cross-chain calls via Interchain Messaging and Teleporter, AvaCloud, and the Retro9000 grant program.
---

# ERC-8004: Trustless Agents on Avalanche

Give your AI agent a verifiable on-chain identity on Avalanche, so it can be discovered, build reputation, and be called from anywhere in the network.

## Why Avalanche for an autonomous agent

Avalanche's distinguishing move is that your agent does not have to share a chain with everyone else:

1. **Your agent can run on its own L1.** Since the Avalanche9000 (Etna) upgrade, what were called Subnets are **Avalanche L1s**, and launching one costs a flat fee from ~1.33 AVAX per validator per month instead of a 2,000 AVAX continuous stake. Validators no longer need to validate the Primary Network. A high-throughput agent gets dedicated blockspace and its own gas rules.
2. **Every L1 is reachable from every other.** Interchain Messaging (ICM) connects all Avalanche L1s, and Teleporter wraps it in a contract-level API. The useful pattern: keep the agent's **identity on the C-Chain**, where ERC-8004 is deployed and everyone can verify it, and run the agent's **execution on its own L1**, bridging calls over ICM.
3. **Infrastructure is funded.** Retro9000 is a $40M grant program for teams building Avalanche L1s.

See "Avalanche-specific capabilities" below.

## What is ERC-8004?

An Ethereum standard for trustless agent identity and reputation. It defines three registries:

| Registry | Status on Avalanche | What it does |
|---|---|---|
| **Identity Registry** | Deployed | ERC-721 agent IDs — your agent gets an NFT |
| **Reputation Registry** | Deployed | Feedback and trust signals from other agents and users |
| **Validation Registry** | **Not deployed** | Third-party verification of agent work |

> **The Validation Registry is not usable yet.** That section of the spec is still under active revision with the TEE community, and no Validation Registry address has been published on Avalanche or any other chain. `references/api-reference.md` documents the proposed interface for planning purposes only — do not build against it yet.

ERC-8004 itself is still a **Draft** EIP. The interfaces below are deployed and stable in practice, but the standard can still change.

Spec: https://eips.ethereum.org/EIPS/eip-8004 · Directory: https://www.8004.org · Explorer: https://8004scan.io

## Contract Addresses

Identity and Reputation are deterministic deployments — the same addresses appear on 40+ chains. Verified on-chain 2026-09-02.

| Chain | Identity Registry | Reputation Registry |
|---|---|---|
| Avalanche Mainnet (43114) | `0x8004A169FB4a3325136EB29fA0ceB6D2e539a432` | `0x8004BAa17C55a88189AE136b182e5fdA19dE9b63` |
| Avalanche Fuji (43113) | `0x8004A818BFB912233c491871b3d84c89A494BD9e` | `0x8004B663056A597Dffe9eCcC1965A193B7388713` |

These are C-Chain deployments. An agent living on its own L1 still registers its identity here.

Full detail, including how to re-verify these yourself: `references/contract-addresses.md`

## Quick Start

**Scripts default to Fuji.** Mainnet is always an explicit choice, and asks for confirmation before spending anything.

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

```bash
./scripts/check-agent.sh <agent-id>              # Fuji
NETWORK=mainnet ./scripts/check-agent.sh 1       # C-Chain — read-only, no signer needed
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

## Avalanche-specific capabilities

### Identity on the C-Chain, execution on your own L1

The recommended architecture for a serious agent on Avalanche:

```
    C-Chain                             Your Avalanche L1
 ┌──────────────────────┐            ┌──────────────────────┐
 │ ERC-8004 Identity    │            │ Agent execution      │
 │ ERC-8004 Reputation  │◄──  ICM  ──│ Custom gas token     │
 │ (public, verifiable) │            │ Dedicated throughput │
 └──────────────────────┘            └──────────────────────┘
```

Identity and reputation stay where everyone already looks for them; the agent's own workload gets blockspace it does not have to compete for. Reference the L1 in the agent's registration file under `services` so callers can find it.

### Interchain Messaging (ICM) and Teleporter

ICM is the message layer between Avalanche L1s; Teleporter is the Solidity framework on top of it. An agent on one L1 can call a contract on another — or read its own ERC-8004 reputation from the C-Chain — without a third-party bridge.

Use it when your agent's reputation lives on the C-Chain but its logic runs elsewhere.

### AvaCloud

A managed portal for launching an L1 without running validator infrastructure yourself. Includes interoperability, gas relaying, Safe multisig, VRF, and wallet-as-a-service. This is the fastest path from "my agent needs its own chain" to a running chain.

https://build.avax.network/integrations/avacloud

### Avalanche9000 in one paragraph

The Etna upgrade activated on mainnet in December 2024 and is the largest change since launch. Subnets became L1s, the economics of running one dropped by orders of magnitude, and validators were decoupled from the Primary Network. If you are reading older material that describes Subnets and a 2,000 AVAX stake, it predates this.

### Retro9000

A $40M retroactive grant program rewarding teams that build Avalanche L1s. Relevant if the agent you are registering is the front end of real infrastructure.

### Tooling worth knowing

HyperSDK for custom VMs, Vryx for throughput, Firewood for state storage, and Avalanche Warp Messaging (AWM) as the primitive underneath ICM.

## Registration File Format

See `assets/templates/registration.json` and `references/registration-format.md`.

```json
{
  "type": "https://eips.ethereum.org/EIPS/eip-8004#registration-v1",
  "name": "My Avalanche Agent",
  "description": "An AI agent operating on Avalanche",
  "image": "https://example.com/avatar.png",
  "services": [
    { "name": "web", "endpoint": "https://myagent.xyz/" },
    { "name": "A2A", "endpoint": "https://myagent.xyz/.well-known/agent-card.json", "version": "0.3.0" },
    { "name": "MCP", "endpoint": "https://mcp.myagent.xyz/", "version": "2025-06-18" }
  ],
  "x402Support": false,
  "active": true,
  "registrations": [
    {
      "agentId": 1,
      "agentRegistry": "eip155:43114:0x8004A169FB4a3325136EB29fA0ceB6D2e539a432"
    }
  ],
  "supportedTrust": ["reputation"]
}
```

## Key Concepts

### Agent Identity (ERC-721 NFT)
- Each agent gets a unique `agentId` (tokenId) at registration.
- The NFT owner controls the agent's profile and metadata; transferring the NFT transfers control.
- Agents are globally addressed as `eip155:43114:0x8004A169FB4a3325136EB29fA0ceB6D2e539a432` plus `agentId`.

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
| `NETWORK` | `fuji` or `mainnet` | `fuji` |
| `ERC8004_YES` | Set to `1` to skip the mainnet confirmation in automation | unset |
| `AVALANCHE_RPC_URL` | Override the RPC endpoint | public Avalanche RPC |
| `PINATA_JWT` | Pinata JWT, only for IPFS registration | — |
| `AGENT_NAME` | Agent display name — required for `register.sh ipfs` | — |
| `AGENT_DESCRIPTION` | Agent description | empty |
| `AGENT_IMAGE` | Avatar URL | empty |
| `AGENT_SERVICES` | JSON array of service endpoints | `[]` |
| `AGENT_X402_SUPPORT` | `true` or `false` | `false` |
| `AGENT_SUPPORTED_TRUST` | Comma-separated trust models | `reputation` |
| `VALUE_DECIMALS` | Decimal places for a feedback value | `0` |

## Avalanche Network Details

| Parameter | Mainnet (C-Chain) | Fuji Testnet |
|---|---|---|
| Chain ID | 43114 | 43113 |
| RPC URL | `https://api.avax.network/ext/bc/C/rpc` | `https://api.avax-test.network/ext/bc/C/rpc` |
| Explorer | https://snowtrace.io | https://testnet.snowtrace.io |
| Currency | AVAX | AVAX (test) |
| Faucet | — | https://faucet.avax.network |

## Prerequisites

- **Foundry** (`cast`) — `curl -L https://foundry.paradigm.xyz | bash && foundryup`
- **jq** — `brew install jq`
- A funded account on the target network.

## Using with viem / ethers.js

See `references/api-reference.md` for complete TypeScript examples.

## Links

- [ERC-8004 Spec](https://eips.ethereum.org/EIPS/eip-8004)
- [erc-8004-contracts](https://github.com/erc-8004/erc-8004-contracts)
- [8004.org](https://www.8004.org) · [8004scan explorer](https://8004scan.io)
- [Building on Avalanche9000](https://avax.network/blog/building-on-avalanche9000)
- [Avalanche Builder Hub](https://build.avax.network) · [AvaCloud](https://build.avax.network/integrations/avacloud)
- [Retro9000 grants](https://avax.network/blog/retro9000-a-40m-grant-program-rewards-developers-building-avalanche-l1s)
- [Snowtrace](https://snowtrace.io)
