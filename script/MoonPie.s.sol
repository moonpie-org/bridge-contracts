// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Script, console} from "forge-std/Script.sol";
import {MoonPie} from "src/v1/MoonPie.sol";

contract MoonPieScript is Script {
    uint256 ownerPrivateKey = vm.envUint("OWNER_PRV_KEY");

    address RELAYER_ADDRESS = vm.envAddress("RELAYER_ADDRESS");
    address TREASURY_ADDRESS = vm.envAddress("TREASURY_ADDRESS");
    address WRWA_ADDRESS = vm.envAddress("WRWA_ADDRESS");
    address SWAP_ROUTER_ADDRESS = vm.envAddress("SWAP_ROUTER_ADDRESS");
    address NATIVE_RWA_TOKEN_ADDRESS =
        vm.envAddress("NATIVE_RWA_TOKEN_ADDRESS");

    // set up initial conditions or requirements
    function setUp() public {}

    // main entry point of the script
    function run() public {
        vm.startBroadcast(ownerPrivateKey);
        new MoonPie(
            RELAYER_ADDRESS,
            TREASURY_ADDRESS,
            MoonPie.NETWORKS.BASE
        );

        vm.stopBroadcast();
    }
}
