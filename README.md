# MoonPie Bridge Contract

## Overview
MoonPieV2 is an upgradable, secure Solidity smart contract designed to facilitate cross-chain token bridging in a trustless and efficient manner. It interacts with a core bridging contract (IBridgeAssist) to handle the actual token transfer across chains

<img src="./PRD.png" alt="MoonPie System Architecture" width="700">



## Key Features  
**Cross-Chain Bridging:** Enables token transfers between supported networks, including Ethereum, Arbitrum, BSC, Base, Bitlayer, and a custom Asset Chain. The contract interfaces with a core bridging contract (IBridgeAssist) that executes the actual cross-chain transfer.

**Relayer System:** <br>
- MoonPie Relayer: A designated relayer address, set by the contract owner, is responsible for completing bridge transactions on the destination chain by calling completeBridge. This ensures secure finalization of transfers.<br>
- Core Bridge Relayer: The core bridging contract relies on its own relayers to validate and sign transactions, providing cryptographic signatures that MoonPieV2 verifies during transaction fulfillment.

**Token Support:** 
- Handles both ERC20 tokens and native tokens (e.g., ETH on Ethereum).
- Allows the owner to register tokens with custom fee caps to enforce minimum transaction amounts and control fee structures.

## How It Works  
**Bridge Initiation (Source Chain):** 
- Users call the bridge function, specifying the token, amount, recipient address, and core bridge contract (tokenBridge).

- MoonPieV2 calculates and deducts the applicable fee, transferring it to the treasury address.

- The remaining amount is sent to the core bridging contract (IBridgeAssist) for cross-chain transfer, either as native tokens (with msg.value) or ERC20 tokens (after approval).

- A unique requestId is generated, and the transaction details are stored in bridgeTransactions for tracking.

- The BridgeInitiated event is emitted.

**Bridge Completion (Destination Chain):** 
- The MoonPie relayer calls completeBridge, providing the source chain transaction ID, transaction details (FulfillTx), and signatures from the core bridge relayers.

- MoonPieV2 verifies the signatures and destination chain details, then instructs the core bridge contract (destinationTokenBridge) to fulfill the transfer to the recipient.

- The transaction is recorded, and the BridgeCompleted event is emitted.

## Foundry

https://book.getfoundry.sh/

## Tests
```shell
forge test --match-path test/unit/v2/MoonPieV2Source.t.sol -vv --fork-url https://mainnet-rpc.assetchain.org
```
```shell
forge test --match-path test/unit/v2/MoonPieV2Dest.t.sol -vv --fork-url https://mainnet-rpc.assetchain.org
```
```shell
forge test --match-path test/unit/v2/MoonPieV2Source.t.sol -vv --fork-url https://mainnet-rpc.assetchain.org && forge test --match-path test/unit/v2/MoonPieV2Dest.t.sol -vv --fork-url https://mainnet-rpc.assetchain.org
```

## Deployment
```shell
forge script script/MoonPie.t.s.sol --force --broadcast --rpc-url https://enugu-rpc.assetchain.org
```
```shell
forge script script/MoonPie.t.s.sol --force --broadcast --rpc-url https://arbitrum-sepolia.gateway.tenderly.co
```
```shell
forge script script/MoonPie.t.s.sol --force --broadcast --rpc-url https://sepolia.base.org
```
```shell
forge script script/MoonPie.t.s.sol --force --broadcast --rpc-url https://ethereum-sepolia-rpc.publicnode.com
```
```shell
forge script script/MoonPie.t.s.sol --force --broadcast --rpc-url https://testnet-rpc.bitlayer.org --legacy
```
```shell
forge script script/MoonPie.t.s.sol --force --broadcast --rpc-url https://bsc-testnet-rpc.publicnode.com
```

## Mainnet Deployment
```shell
forge script script/MoonPie.m.s.sol --force --broadcast --rpc-url https://mainnet-rpc.assetchain.org
```
```shell
forge script script/MoonPie.m.s.sol --force --broadcast --rpc-url https://arb1.arbitrum.io/rpc
```
```shell
forge script script/MoonPie.m.s.sol --force --broadcast --rpc-url https://mainnet.base.org
```
```shell
forge script script/MoonPie.m.s.sol --force --broadcast --rpc-url https://ethereum-rpc.publicnode.com
```
```shell
forge script script/MoonPie.m.s.sol --force --broadcast --rpc-url https://rpc.bitlayer.org --legacy
```
```shell
forge script script/MoonPie.m.s.sol --force --broadcast --rpc-url https://bsc-rpc.publicnode.com
```
## Verify
```shell
forge verify-contract 0x5e033B7826C8C9d36bd80fFC926e65743c08c82c src/v2/MoonPieV2.sol:MoonPieV2 --rpc-url https://mainnet-rpc.assetchain.org --verifier blockscout --verifier-url https://scan.assetchain.org/api --chain-id 42420
```
```shell
forge verify-contract 0x55bd049f934b20805609fE484Aa500ef51B0ee8A TransparentUpgradeableProxy --rpc-url https://enugu-rpc.assetchain.org --verifier blockscout --verifier-url https://scan-testnet.assetchain.org/api --chain-id 42421
```
```shell
forge verify-contract 0x231e9744b6FfD9Ecda91eA0Efc4d999003ffCAc0 src/v2/MoonPieV2.sol:MoonPieV2 --rpc-url https://testnet-rpc.bitlayer.org --verifier blockscout --verifier-url https://api-testnet.bitlayer.org/scan/api --chain-id 200810
```
```shell
forge verify-contract 0x5d2451c57c167B1437635f77f00acc35c326BAf1 TransparentUpgradeableProxy --rpc-url https://bsc-rpc.publicnode.com --verifier etherscan --verifier-url https://api.bscscan.com/api  --etherscan-api-key FJ6SZDHMXKAKAZEU1537SQMBBXNC1S98E8 --chain-id 56
```

## Testnet Deployments
| Network | Implementation Contract | ProxyAdmin Contract | Proxy Contract |
| --- | --- | --- | --- |
| Asset Chain Testnet | 0x9ed45ce94395d3a8c6e96ACDbF2d17fc8DBDd140 | 0x68982592dB2533d5F8e9Af7ef42Bb923858BeEDf | 0x55bd049f934b20805609fE484Aa500ef51B0ee8A |
| Arbitrum Sepolia | 0x4f625f42BfA4796F0CA2A204dccd76364E2C433B | 0x93F5A066d2F256051Aad563D1DC6b11Ed26f0304 | 0x381AFE71090cf71B75a886EA8833dfc9683c57b6 |
| Base Sepolia | 0x1b577D56F0EffCd7808e9e7579CAaB27D7ae951B | 0x338B432fD6E26f518F70450452bC81ab5911ddD9 | 0xC442e76df720456535dfE53BDc6100C48a4A9CBf |
| Bitlayer Testnet | 0x231e9744b6FfD9Ecda91eA0Efc4d999003ffCAc0 | 0xd31bf7b1A41C63e0ecE8c50D7DA8E109352b888B | 0xDe0c2ECF19BeDDE01ea0e139224b1319460BC7d1 |

## Mainnet Deployments
| Network | Implementation Contract | ProxyAdmin Contract | Proxy Contract |
| --- | --- | --- | --- |
| Asset Chain | 0x5e033B7826C8C9d36bd80fFC926e65743c08c82c | 0xBc6fCD79E68F8a879A913702378e7064cBc323c5 | 0x74CCa740af0EBB235057df8e441f0F2f9D21d8c3 |
| Arbitrum | 0x2B7C1342Cc64add10B2a79C8f9767d2667DE64B2 | 0x582eDb9E96750C819791c0353f2233EcCC7d3313 | 0xeD8AEcbA1743cBb01FAFE454524e8ee238C09c3B |
| Base | 0x10244648dB5d97B2F8607fe8E012E78b73ca8b3F | 0x05F66cdE041477f3D7D1Da7C703B978f573BD9e5 | 0x46e4450fcC5fE1b8C93694562a1330D5456b94A2 |
| BSC | 0x17e0D1239eA25904C66CFD4D051Ed0592Ad42fCe | 0x991603DA1C59cAB3C49c37C506820f5bF07AdC55 | 0x5d2451c57c167B1437635f77f00acc35c326BAf1 |
| Ethereum | 0x10244648dB5d97B2F8607fe8E012E78b73ca8b3F | 0x05F66cdE041477f3D7D1Da7C703B978f573BD9e5 | 0x46e4450fcC5fE1b8C93694562a1330D5456b94A2 |
| Bitlayer | 0x904d6bea6f53bb3fD7a4E6799B414B0b0Df0D0aa | 0xc62c54d2439cE43D767B7b44939744BA1606feB2 | 0xFb727149C76dCa52F58b1AD73667eCe1d012FbBb |


