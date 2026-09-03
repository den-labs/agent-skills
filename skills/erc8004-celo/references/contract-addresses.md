# ERC-8004 Contract Addresses on Celo

> **No Validation Registry.** Only Identity and Reputation are deployed.
> No Validation Registry address exists on this or any other chain — that
> part of the ERC-8004 spec is still under revision with the TEE community.

> Addresses verified on-chain with `eth_getCode` on 2026-09-02. Re-check them
> yourself at any time with `./scripts/verify-addresses.sh` from the repo root.

## Celo Mainnet (Chain ID: 42220)

| Contract | Address | Explorer |
|---|---|---|
| Identity Registry | `0x8004A169FB4a3325136EB29fA0ceB6D2e539a432` | [Celoscan](https://celoscan.io/address/0x8004A169FB4a3325136EB29fA0ceB6D2e539a432) |
| Reputation Registry | `0x8004BAa17C55a88189AE136b182e5fdA19dE9b63` | [Celoscan](https://celoscan.io/address/0x8004BAa17C55a88189AE136b182e5fdA19dE9b63) |

## Celo Sepolia Testnet (Chain ID: 11142220)

| Contract | Address | Explorer |
|---|---|---|
| Identity Registry | `0x8004A818BFB912233c491871b3d84c89A494BD9e` | [Blockscout](https://celo-sepolia.blockscout.com/address/0x8004A818BFB912233c491871b3d84c89A494BD9e) |
| Reputation Registry | `0x8004B663056A597Dffe9eCcC1965A193B7388713` | [Blockscout](https://celo-sepolia.blockscout.com/address/0x8004B663056A597Dffe9eCcC1965A193B7388713) |

## RPC Endpoints

| Network | RPC URL | Chain ID |
|---|---|---|
| Mainnet | `https://forno.celo.org` | 42220 |
| Celo Sepolia Testnet | `https://forno.celo-sepolia.celo-testnet.org` | 11142220 |

## Agent Registry Identifiers

Used in registration files to globally identify agents:

- **Mainnet**: `eip155:42220:0x8004A169FB4a3325136EB29fA0ceB6D2e539a432`
- **Celo Sepolia**: `eip155:11142220:0x8004A818BFB912233c491871b3d84c89A494BD9e`

## Also Deployed On

ERC-8004 contracts are deployed across multiple chains with deterministic vanity addresses (`0x8004A...`, `0x8004B...`):

- Ethereum Mainnet (1)
- Sepolia (11155111)
- Avalanche (43114)
- Arbitrum (42161)
- Gnosis (100)
- And more...

Full list: https://www.8004.org
