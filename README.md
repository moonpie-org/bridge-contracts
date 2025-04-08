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
forge test --match-path test/unit/v1/MoonPieSource.t.sol -vv --fork-url https://mainnet-rpc.assetchain.org
```
```shell
forge test --match-path test/unit/v1/MoonPieDest.t.sol -vv --fork-url https://mainnet-rpc.assetchain.org
```
```shell
forge test --match-path test/unit/v2/MoonPieV2Source.t.sol -vv --fork-url https://mainnet-rpc.assetchain.org
```
```shell
forge test --match-path test/unit/v2/MoonPieV2Dest.t.sol -vv --fork-url https://mainnet-rpc.assetchain.org
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
forge verify-contract 0xAF7858FF8ed9B7EB3F1db39C7F6dA3A20426c599 src/v2/MoonPieV2.sol:MoonPieV2 --rpc-url https://enugu-rpc.assetchain.org --verifier blockscout --verifier-url https://scan-testnet.assetchain.org/api --chain-id 42421
```