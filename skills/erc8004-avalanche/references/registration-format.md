# ERC-8004 Registration File Format

## Full Registration File

```json
{
  "type": "https://eips.ethereum.org/EIPS/eip-8004#registration-v1",
  "name": "My Avalanche Agent",
  "description": "A natural language description of the Agent",
  "image": "https://example.com/agentimage.png",
  "services": [
    {
      "name": "web",
      "endpoint": "https://web.myagent.com/"
    },
    {
      "name": "A2A",
      "endpoint": "https://myagent.com/.well-known/agent-card.json",
      "version": "0.3.0"
    },
    {
      "name": "MCP",
      "endpoint": "https://mcp.myagent.com/",
      "version": "2025-06-18"
    },
    {
      "name": "OASF",
      "endpoint": "ipfs://{cid}",
      "version": "0.8"
    },
    {
      "name": "ENS",
      "endpoint": "myagent.eth",
      "version": "v1"
    },
    {
      "name": "email",
      "endpoint": "agent@myagent.com"
    }
  ],
  "x402Support": false,
  "active": true,
  "registrations": [
    {
      "agentId": 1,
      "agentRegistry": "eip155:43114:0x8004A169FB4a3325136EB29fA0ceB6D2e539a432"
    }
  ],
  "supportedTrust": ["reputation", "crypto-economic", "tee-attestation"]
}
```

## Required Fields

| Field | Type | Description |
|---|---|---|
| `type` | string | Must be `https://eips.ethereum.org/EIPS/eip-8004#registration-v1` |
| `name` | string | Agent display name |
| `description` | string | Natural language description |
| `image` | string | Avatar/image URL |

## Optional Fields

| Field | Type | Description |
|---|---|---|
| `services` | array | List of service endpoints (A2A, MCP, web, etc.) |
| `x402Support` | boolean | Whether the agent supports x402 payments |
| `active` | boolean | Whether the agent is currently active |
| `registrations` | array | List of on-chain registrations across chains |
| `supportedTrust` | array | Trust models: `reputation`, `crypto-economic`, `tee-attestation` |

## Service Types

| Service Name | Description | Version Example |
|---|---|---|
| `web` | Web interface URL | - |
| `A2A` | Agent-to-Agent protocol endpoint | `0.3.0` |
| `MCP` | Model Context Protocol endpoint | `2025-06-18` |
| `OASF` | Open Agent Service Framework | `0.8` |
| `ENS` | Ethereum Name Service handle | `v1` |
| `DID` | Decentralized Identifier | `v1` |
| `email` | Contact email | - |

## Hosting Options

1. **IPFS** (recommended): Upload to Pinata/IPFS, use `ipfs://` URI
2. **HTTPS**: Host at any URL, use `https://` URI
3. **On-chain**: Base64-encode as `data:application/json;base64,...` URI

## Domain Verification (Optional)

Prove control of a domain by publishing:
```
https://{your-domain}/.well-known/agent-registration.json
```

This file should contain at minimum the `registrations` array matching your on-chain agent.

## Feedback File Format (Off-chain)

Optional JSON file for detailed feedback:

```json
{
  "agentRegistry": "eip155:43114:0x8004A169FB4a3325136EB29fA0ceB6D2e539a432",
  "agentId": 1,
  "clientAddress": "eip155:43114:0xYourAddress",
  "createdAt": "2025-09-23T12:00:00Z",
  "value": 85,
  "valueDecimals": 0,
  "tag1": "starred",
  "tag2": "",
  "endpoint": "https://agent.example.com/api",
  "mcp": { "tool": "ToolName" },
  "a2a": {
    "skills": ["skill-id"],
    "contextId": "ctx-123",
    "taskId": "task-456"
  },
  "proofOfPayment": {
    "fromAddress": "0x...",
    "toAddress": "0x...",
    "chainId": "43114",
    "txHash": "0x..."
  }
}
```
