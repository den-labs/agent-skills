#!/usr/bin/env bash
# Celo network table for ERC-8004. Chain-specific — not shared between skills.
# shellcheck shell=bash
# shellcheck disable=SC2034  # every E8_* variable is consumed by the sourcing script

# e8_load_network [network] — populates E8_NETWORK, E8_CHAIN_ID, E8_RPC_URL,
# E8_EXPLORER, E8_IDENTITY_REGISTRY, E8_REPUTATION_REGISTRY, E8_NATIVE_TOKEN.
#
# Defaults to the testnet: registering on mainnet spends real funds, so it must
# be an explicit choice, never what you get by forgetting to set NETWORK.
e8_load_network() {
  E8_NETWORK="${1:-${NETWORK:-sepolia}}"

  case "$E8_NETWORK" in
    mainnet|celo)
      E8_NETWORK="mainnet"
      E8_CHAIN_ID="42220"
      E8_RPC_URL="${CELO_RPC_URL:-https://forno.celo.org}"
      E8_EXPLORER="https://celoscan.io"
      E8_IDENTITY_REGISTRY="0x8004A169FB4a3325136EB29fA0ceB6D2e539a432"
      E8_REPUTATION_REGISTRY="0x8004BAa17C55a88189AE136b182e5fdA19dE9b63"
      ;;
    sepolia|celo-sepolia|testnet)
      E8_NETWORK="sepolia"
      E8_CHAIN_ID="11142220"
      E8_RPC_URL="${CELO_RPC_URL:-https://forno.celo-sepolia.celo-testnet.org}"
      E8_EXPLORER="https://celo-sepolia.blockscout.com"
      E8_IDENTITY_REGISTRY="0x8004A818BFB912233c491871b3d84c89A494BD9e"
      E8_REPUTATION_REGISTRY="0x8004B663056A597Dffe9eCcC1965A193B7388713"
      ;;
    *)
      e8_die "Unknown network '$E8_NETWORK'. Use 'mainnet' or 'sepolia'."
      ;;
  esac

  E8_NATIVE_TOKEN="CELO"
  E8_CHAIN_LABEL="Celo"
}
