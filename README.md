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
forge test --match-path test/unit/v1/MoonPieSource.t.sol -vv --fork-url https://mainnet-rpc.assetchain.org
```
```shell
forge test --match-path test/unit/v1/MoonPieDest.t.sol -vv --fork-url https://mainnet-rpc.assetchain.org
```
```shell
forge test --match-path test/unit/v2/MoonPieV2Dest.t.sol -vv --fork-url https://mainnet-rpc.assetchain.org
```
## Deployment
```shell
forge script script/MoonPie.s.sol --force --broadcast --rpc-url https://enugu-rpc.assetchain.org
```
## Verify
```shell
forge verify-contract 0x344678563cE8c83a0bd2FBb01BEa14b4a65e4c7a src/v2/MoonPieV2.sol:MoonPieV2 --rpc-url https://enugu-rpc.assetchain.org --verifier blockscout --verifier-url https://scan-testnet.assetchain.org/api --chain-id 42421
```