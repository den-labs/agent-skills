---
name: trust-score
license: Wolfcito Open / Commercial License (WOCL). See LICENSE.
compatibility: Requires bash, curl and jq, plus a DenScope or Ayni API key for every endpoint.
metadata:
  version: "1.2.0"
description: Query ERC-8004 agent trust scores from DenScope (Celo) and Ayni (Avalanche). Use this skill when you need to check if an AI agent is trustworthy, get reputation data, view risk signals, or search for registered agents on-chain.
---

# Trust Score — ERC-8004 Reputation Index

Query trust scores, reputation data, and risk signals for autonomous AI agents registered under ERC-8004.

## What This Does

This skill queries DenScope or Ayni for an agent's trust score, reputation and risk signals. Use it before interacting with an unknown agent, when evaluating reliability, or when building trust-aware workflows.

**These are indexers, not oracles.** They read ERC-8004 events from chain, index them, and compute scores served over HTTP. Nothing they produce is written back on-chain — an oracle moves data the other way. The name matters when deciding what to trust: their scores are a service's interpretation, while the underlying feedback is on-chain fact anyone can verify.

## Indexers and the chains they cover

| Indexer | Chains | Base URL |
|---|---|---|
| **DenScope** | Celo (42220), Celo Sepolia (11142220), SKALE Base (1187947933) | `www.denscope.xyz` |
| **Ayni** | Avalanche C-Chain (43114), Fuji (43113) | `ayni.denscope.xyz` |

Chain names accepted by the scripts: `celo`, `celo-sepolia`, `skale-base`,
`avalanche`, `fuji`, or any numeric chain ID.

> **Both hosts have moved.** DenScope was `denscope.vercel.app`; Ayni was
> `ayni-alpha.vercel.app`. The old hosts still redirect, but the scripts call
> the canonical domains directly.

## Reading from the chain instead

The ERC-8004 skills read reputation straight from the Reputation Registry with
no API key and no third party:

```bash
# from the erc8004-celo or erc8004-avalanche skill
NETWORK=mainnet scripts/read-feedback.sh 1
```

Use that for ground truth about one agent. Use an indexer for what the chain
does not give cheaply: an aggregated score, risk signals, sybil detection, and
search across agents.

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

### Risk Signals and Event History

```bash
./scripts/get-signals.sh denscope celo 1     # reputation drops, sybil, spikes
./scripts/get-events.sh denscope celo 1 20   # on-chain event history
```

> The response shape for these two endpoints could not be verified against a
> live API — every `/api/v1/*` path returns 401 without a key, and none was
> available when they were written. They follow the documented schema and the
> same request path as the verified scripts; if a field name differs, the
> script prints the raw body rather than failing silently.

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
