#!/usr/bin/env bash
# Avalanche network table for ERC-8004. Chain-specific — not shared between skills.
# shellcheck shell=bash
# shellcheck disable=SC2034  # every E8_* variable is consumed by the sourcing script

# e8_load_network [network] — populates E8_NETWORK, E8_CHAIN_ID, E8_RPC_URL,
# E8_EXPLORER, E8_IDENTITY_REGISTRY, E8_REPUTATION_REGISTRY, E8_NATIVE_TOKEN.
#
# Defaults to the testnet: registering on mainnet spends real funds, so it must
# be an explicit choice, never what you get by forgetting to set NETWORK.
e8_load_network() {
  E8_NETWORK="${1:-${NETWORK:-fuji}}"

  case "$E8_NETWORK" in
    mainnet|avalanche|c-chain)
      E8_NETWORK="mainnet"
      E8_CHAIN_ID="43114"
      E8_RPC_URL="${AVALANCHE_RPC_URL:-https://api.avax.network/ext/bc/C/rpc}"
      E8_EXPLORER="https://snowtrace.io"
      E8_IDENTITY_REGISTRY="0x8004A169FB4a3325136EB29fA0ceB6D2e539a432"
      E8_REPUTATION_REGISTRY="0x8004BAa17C55a88189AE136b182e5fdA19dE9b63"
      ;;
    fuji|testnet)
      E8_NETWORK="fuji"
      E8_CHAIN_ID="43113"
      E8_RPC_URL="${AVALANCHE_RPC_URL:-https://api.avax-test.network/ext/bc/C/rpc}"
      E8_EXPLORER="https://testnet.snowtrace.io"
      E8_IDENTITY_REGISTRY="0x8004A818BFB912233c491871b3d84c89A494BD9e"
      E8_REPUTATION_REGISTRY="0x8004B663056A597Dffe9eCcC1965A193B7388713"
      ;;
    *)
      e8_die "Unknown network '$E8_NETWORK'. Use 'mainnet' or 'fuji'."
      ;;
  esac

  E8_NATIVE_TOKEN="AVAX"
  E8_CHAIN_LABEL="Avalanche C-Chain"
}
