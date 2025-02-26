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
> forge test --match-path test/unit/v1/MoonPieSource.t.sol -vv --fork-url https://mainnet-rpc.assetchain.org
> forge test --match-path test/unit/v1/MoonPieSource.t.sol -vv --fork-url https://mainnet-rpc.assetchain.org
> forge test --match-path test/unit/v1/MoonPieDest.t.sol -vv --fork-url https://mainnet-rpc.assetchain.org
> forge test --match-path test/unit/v2/MoonPieV2Dest.t.sol -vv --fork-url https://mainnet-rpc.assetchain.org
```