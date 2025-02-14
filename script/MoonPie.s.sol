// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Script, console} from "forge-std/Script.sol";
import {MoonPie} from "src/MoonPie.sol";

contract MoonPieScript is Script {
    uint256 ownerPrivateKey = vm.envUint("OWNER_PRV_KEY");

    string RELAYER_ADDRESS = vm.envString("RELAYER_ADDRESS");
    address TREASURY_ADDRESS = vm.envAddress("TREASURY_ADDRESS");

    // set up initial conditions or requirements
    function setUp() public {}

    // main entry point of the script
    function run() public {
        vm.startBroadcast(ownerPrivateKey);

        new MoonPie(RELAYER_ADDRESS, TREASURY_ADDRESS);

        vm.stopBroadcast();
    }
}
