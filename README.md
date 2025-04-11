## MoonPie Bridge Contract


## Foundry

https://book.getfoundry.sh/

## Usage

```shell
> forge build
> forge test
> forge fmt
> forge snapshot
> anvil
> forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
> forge test --mc ChainFork --fork-url https://arbitrum-sepolia.gateway.tenderly.co
> anvil --fork-url https://arbitrum-sepolia.gateway.tenderly.co
> forge test --match-path test/ContractB.t.sol
> forge test -vvv --fork-url https://mainnet.base.org
```
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
forge script script/MoonPie.s.sol --force --broadcast --rpc-url https://enugu-rpc.assetchain.org
```
```shell
forge script script/MoonPie.s.sol --force --broadcast --rpc-url https://arbitrum-sepolia.gateway.tenderly.co
```
```shell
forge script script/MoonPie.s.sol --force --broadcast --rpc-url https://sepolia.base.org
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
