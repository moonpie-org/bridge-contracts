// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.22;

import {Script, console2} from "forge-std/Script.sol";
import {stdJson} from "forge-std/StdJson.sol";

abstract contract BaseScript is Script {
    constructor() {
        if (block.chainid == 31337) {
            currentChain = Chains.Localnet;
        } else if (block.chainid == 8453) {
            currentChain = Chains.Base;
        } else if (block.chainid == 84532) {
            currentChain = Chains.Arbitrum;
        } else if (block.chainid == 42420) {
            currentChain = Chains.AssetChain;
        }  else {
            revert("Unsupported chain for deployment");
        }
    }

    Chains currentChain;

    enum Chains {
        Localnet,
        Base,
        Arbitrum,
        AssetChain
    }

    function getDeployConfigJson() internal view returns (string memory json) {
        if (currentChain == Chains.Base) {
            json = vm.readFile(string.concat(vm.projectRoot(), "/deploy-configs/base.json"));
        } else if (currentChain == Chains.Arbitrum) {
            json = vm.readFile(string.concat(vm.projectRoot(), "/deploy-configs/arbitrum.json"));
        } else if (currentChain == Chains.AssetChain) {
            json = vm.readFile(string.concat(vm.projectRoot(), "/deploy-configs/assetchain.json"));
        } else {
            json = vm.readFile(string.concat(vm.projectRoot(), "/deploy-configs/local.json"));
        }
    }
}
