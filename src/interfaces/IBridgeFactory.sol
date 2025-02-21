 // SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBridgeFactory {

 function getBridgeByToken(
        address token,
        uint256 index
    ) external view returns (address);

}