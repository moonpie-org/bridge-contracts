// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "forge-std/console.sol";

contract UniswapPoolChecker {
    IUniswapV3Factory public constant FACTORY =
        IUniswapV3Factory(0xa9d53862D01190e78dDAf924a8F497b4F8bb5163); // Assetchain swap factory

    function _orderTokens(
        address tokenA,
        address tokenB
    ) internal pure returns (address token0, address token1) {
        return tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
    }

    function checkPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) public view returns (bool exists, address poolAddress) {
        (address token0, address token1) = _orderTokens(tokenA, tokenB);
        poolAddress = FACTORY.getPool(token0, token1, fee);
        exists = poolAddress != address(0);
    }

    function checkAllFeeTiers(
        address tokenA,
        address tokenB
    ) public view returns (bool[4] memory exists, address[4] memory pools) {
        uint24[4] memory feeTiers = [
            uint24(100), // 0.01%
            uint24(500), // 0.05%
            uint24(3000), // 0.3%
            uint24(10000) // 1%
        ];

        (address token0, address token1) = _orderTokens(tokenA, tokenB);

        for (uint i = 0; i < feeTiers.length; i++) {
            (exists[i], pools[i]) = checkPool(token0, token1, feeTiers[i]);
        }
    }

    function getPoolLiquidity(address pool) public view returns (uint128) {
        if (pool == address(0)) return 0;

        try IUniswapV3Pool(pool).liquidity() returns (uint128 liquidity) {
            return liquidity;
        } catch {
            return 0;
        }
    }

    function findBestPool(
        address tokenA,
        address tokenB
    ) public view returns (address bestPool, uint24 fee, uint128 liquidity) {
        uint24[4] memory feeTiers = [
            uint24(100), // 0.01%
            uint24(500), // 0.05%
            uint24(3000), // 0.3%
            uint24(10000) // 1%
        ];
        uint128 maxLiquidity = 0;

        (address token0, address token1) = _orderTokens(tokenA, tokenB);

        for (uint i = 0; i < feeTiers.length; i++) {
            address pool = FACTORY.getPool(token0, token1, feeTiers[i]);
            if (pool != address(0)) {
                uint128 poolLiquidity = getPoolLiquidity(pool);
                if (poolLiquidity > maxLiquidity) {
                    maxLiquidity = poolLiquidity;
                    bestPool = pool;
                    fee = feeTiers[i];
                    liquidity = poolLiquidity;
                }
            }
        }
    }
}
