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
```shell
forge script script/MoonPie.s.sol --force --broadcast --rpc-url https://arbitrum-sepolia.gateway.tenderly.co
```
```shell
forge script script/MoonPie.s.sol --force --broadcast --rpc-url https://sepolia.base.org
```
## Verify
```shell
forge verify-contract 0x25a71bc19f47d010018f3fA331B2C428ADA83618 src/v2/MoonPieV2.sol:MoonPieV2 --rpc-url https://enugu-rpc.assetchain.org --verifier blockscout --verifier-url https://scan-testnet.assetchain.org/api --chain-id 42421
```