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
## Verify
```shell
forge verify-contract 0x9c92D85821aDadC8B079b7EA018761a1798B15c2 src/v2/MoonPieV2.sol:MoonPieV2 --rpc-url https://enugu-rpc.assetchain.org --verifier blockscout --verifier-url https://scan-testnet.assetchain.org/api --chain-id 42421
```

## Deployments
| Network | Implementation Contract | ProxyAdmin Contract | Proxy Contract | Treasury Address |
| --- | --- | --- | --- | --- |
| Asset Chain Testnet | 0x9c92D85821aDadC8B079b7EA018761a1798B15c2 | 0xfd9D0FCCa509210e4C5c0903a9c1DbD13250e01e | 0xBECe8b1D79204adEC55D74EfE8E4b15796437B8f | 0x377123Ed74fBE8ddb47E30aEbCf267c55EFa7b33 |
| Arbitrum Sepolia | 0x260EfB8F40eAEfb6C062fB1a28B27987CB96003F | 0x7D4057d2A19f685C43323426b06CF0fa46b0792f | 0x0e68b1f2AE192F92d9e0C6FbDC4e2d17F3A7516C | 0x377123Ed74fBE8ddb47E30aEbCf267c55EFa7b33 |
| Base Sepolia | 0x2262e53F537E7805EB70FBA91d55241fc571BBfA | 0x17878B5a24a7DDf3B2725894feaC1909b0d060c4 | 0x41daC6aD742DD5BA7681c70B03699227E8840989 | 0x377123Ed74fBE8ddb47E30aEbCf267c55EFa7b33 |
