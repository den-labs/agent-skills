# Verificación de la ruta de escritura — 2026-09-03

Las escrituras se habían publicado sin ejecutarse nunca contra una cadena. Esto cierra ese hueco **sin faucet y sin fondos reales**, usando `anvil` para forkear la cadena real en local: contratos desplegados auténticos, cuentas financiadas de mentira.

```bash
anvil --fork-url https://api.avax.network/ext/bc/C/rpc --port 8546
```

## Las tres suposiciones sin probar — todas confirmadas

| Suposición | Resultado |
|---|---|
| `cast send --json` devuelve un `status` usable | ✅ Confirmado — el chequeo de estado pasó y reportó éxito |
| `register()` emite un `Transfer` de ERC-721 estándar | ✅ Confirmado — `e8_agent_id_from_receipt` decodificó **1813**, idéntico a lo que predijo `cast call` |
| El orden de argumentos del signer en `cast send` | ✅ Confirmado — firmó y envió sin error |

## Recorrido completo del ciclo de vida

| # | Acción | Resultado |
|---|---|---|
| 1 | `register.sh` con URI alcanzable | ✅ Agente **1813** creado, ID decodificado del receipt |
| 2 | `check-agent.sh` (sin Foundry) sobre 1813 | ✅ Owner y URI correctos |
| 3 | `update-agent.sh` cambia el URI | ✅ Tx confirmada |
| 4 | `check-agent.sh` revalida | ✅ El URI **cambió realmente** en cadena |
| 5 | `give-feedback.sh 1 92 starred` | ✅ Reviewers 5 → 6, valor 92 |
| 6 | `read-feedback.sh 1 starred` (sin Foundry) | ✅ Refleja el feedback nuevo |
| 7 | `revoke-feedback.sh 1 1` | ✅ Tx confirmada |
| 8 | `read-feedback.sh` tras revocar | ✅ Contador vuelve a **0** |

## Detección de revert — el punto crítico

`update-agent.sh` sobre un agente ajeno:

```
error: Transaction failed to send:
  ... execution reverted: Not authorized ... Error("Not authorized")
```

**Falló ruidosamente y no reportó éxito.** Ese era exactamente el objetivo del endurecimiento: la versión anterior imprimía `"Registration successful!"` siempre que existiera un receipt, y una tx revertida también tiene receipt.

## Hallazgo: anvil no puede forkear Celo para escrituras

En un fork de Celo mainnet las **lecturas funcionan** (`ownerOf(1)` devuelve el owner correcto) pero **toda escritura revierte con data vacía** — incluido `register()` sin argumentos, que no puede fallar por lógica de negocio.

No es un fallo de nuestros scripts. Celo es un L2 sobre OP Stack con tipos de transacción propios (CIP-64) que anvil no emula. El mismo código sobre un fork de Avalanche C-Chain funciona perfectamente.

**Consecuencia práctica:** el código de escritura es idéntico para ambas cadenas — mismo `lib.sh` vendorizado, sólo cambia `network.sh` — así que verificarlo en Avalanche verifica la lógica en las dos. Lo que queda sin probar en Celo es exclusivamente la interacción con su capa de transacciones, y eso sólo se cierra contra Celo Sepolia real con una cuenta de faucet.

## Lo que sigue sin verificarse

- Escrituras contra **Celo real** (Sepolia con faucet). El fork no sirve para esto.
- `register.sh ipfs` — requiere un `PINATA_JWT`.
- Firma con **keystore, Ledger y Trezor**. Sólo se probó la ruta `PRIVATE_KEY`.
- `get-signals.sh` y `get-events.sh` de trust-score — todo endpoint devuelve 401 sin API key.

## Reproducirlo

```bash
anvil --fork-url https://api.avax.network/ext/bc/C/rpc --port 8546 &

export NETWORK=mainnet ERC8004_YES=1
export AVALANCHE_RPC_URL=http://127.0.0.1:8546
export PRIVATE_KEY=<la clave de test pública de anvil>

cd skills/erc8004-avalanche/scripts
./register.sh "https://example.org/agent.json"
```

La clave usada es la primera cuenta de test de anvil, pública y documentada, sin valor alguno. No aparece en el repo.
