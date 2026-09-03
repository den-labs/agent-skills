---
name: trust-score
metadata:
  version: "1.0.1"
description: Query ERC-8004 agent trust scores from DenScope (Celo) and Ayni (Avalanche). Use this skill when you need to check if an AI agent is trustworthy, get reputation data, view risk signals, or search for registered agents on-chain.
---

# Trust Score — ERC-8004 Agent Trust Oracle

Query trust scores, reputation data, and risk signals for autonomous AI agents registered under ERC-8004.

## What This Does

This skill lets you check the trustworthiness of any ERC-8004 agent by querying DenScope (Celo) or Ayni (Avalanche) trust oracles. Use it before interacting with an unknown agent, when evaluating agent reliability, or when building trust-aware workflows.

## Supported Oracles

| Oracle | Chain | Chain ID | Base URL |
|---|---|---|---|
| DenScope | Celo Mainnet | 42220 | www.denscope.xyz |
| DenScope | Celo Sepolia | 11142220 | www.denscope.xyz |
| Ayni | Avalanche C-Chain | 43114 | ayni-alpha.vercel.app |
| Ayni | Fuji Testnet | 43113 | ayni-alpha.vercel.app |

> **DenScope moved to `www.denscope.xyz`.** The old `denscope.vercel.app`
> host still 301-redirects, but the scripts now call the canonical domain
> directly and follow redirects.

## Quick Start

### Get Trust Score (API key mode)

```bash
# Set your API key
export TRUST_API_KEY="ds_your_key_here"

# Query trust score for agent #1 on Celo
./scripts/get-score.sh denscope celo 1

# Query trust score for agent #74 on Fuji
./scripts/get-score.sh ayni fuji 74
```

### Get Agent Profile

```bash
./scripts/get-agent.sh denscope celo 1
```

### Search Agents

```bash
./scripts/search-agents.sh denscope celo
```

## Interpreting Trust Scores

| Score Range | Level | Meaning |
|---|---|---|
| 80-100 | High Trust | Verified track record, strong positive feedback |
| 50-79 | Moderate Trust | Active agent, building history |
| 25-49 | Low Trust | Limited data or mixed signals |
| 0-24 | Minimal Data | New agent or insufficient feedback |

**Confidence levels:**
- `high` — 10+ feedbacks, reliable score
- `medium` — 3-9 feedbacks, directional
- `low` — 0-2 feedbacks, too early to judge

## Score Breakdown

The trust score (0-100) is computed from:

| Component | Weight | What It Measures |
|---|---|---|
| Positive Ratio | 40% | Percentage of positive feedback |
| Age Score | 20% | How long the agent has existed (max at 90 days) |
| Activity Score | 20% | Feedback frequency relative to age |
| Incident Penalty | 10% | Deduction for critical/warning incidents |
| Sybil Penalty | 10% | Deduction if sybil behavior detected |

## Using with TypeScript/JavaScript

```bash
npm install @denlabs/trust-sdk    # For Celo (DenScope)
npm install @denlabs/ayni-sdk     # For Avalanche (Ayni)
```

```typescript
import { DenScope } from '@denlabs/trust-sdk'

const ds = new DenScope({ apiKey: process.env.TRUST_API_KEY })
const { score } = await ds.getScore(42220, 1)
console.log(`Trust: ${score.value}/100 (${score.confidence})`)
```

## Using as MCP Server

Add to your Claude Desktop / Cursor / IDE config:

```json
{
  "mcpServers": {
    "trust": {
      "command": "npx",
      "args": ["@denlabs/trust-mcp-server"],
      "env": {
        "DENSCOPE_API_KEY": "ds_your_key_here"
      }
    }
  }
}
```

Then ask: "Check the trust score for agent 1 on Celo"

## Environment Variables

| Variable | Description | Required |
|---|---|---|
| `TRUST_API_KEY` | API key for DenScope or Ayni (ds_xxx) | Yes for score/signals |
| `DENSCOPE_API_KEY` | Alternative: DenScope-specific key | No |
| `AYNI_API_KEY` | Alternative: Ayni-specific key | No |

## API Endpoints

| Method | Auth Required | Description |
|---|---|---|
| Get Agent | Yes | Agent profile, owner, metadata, feedback counts |
| Get Score | Yes | Trust score 0-100 with breakdown |
| Get Signals | Yes | Risk signals (reputation drops, sybil, spikes) |
| Get Events | Yes | On-chain event history |
| Search | Yes | Find agents by chain, owner, or query |

> **All endpoints require an API key.** Verified 2026-09-02: every `/api/v1/*`
> path on both DenScope and Ayni returns HTTP 401 without an `Authorization`
> header, including Get Agent and Search, which earlier versions of this skill
> documented as public. The scripts now ask for the key up front rather than
> failing mid-request.

## Links

- [Trust SDK on npm](https://www.npmjs.com/package/@denlabs/trust-sdk)
- [Ayni SDK on npm](https://www.npmjs.com/package/@denlabs/ayni-sdk)
- [GitHub: den-labs/trust-sdk](https://github.com/den-labs/trust-sdk)
- [DenScope Explorer](https://www.denscope.xyz)
- [ERC-8004 Spec](https://eips.ethereum.org/EIPS/eip-8004)
