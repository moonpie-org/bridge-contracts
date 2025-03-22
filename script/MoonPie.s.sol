// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Script, console} from "forge-std/Script.sol";
import {MoonPieV2} from "src/v2/MoonPieV2.sol";

contract MoonPieScript is Script {
    uint256 ownerPrivateKey = vm.envUint("OWNER_PRV_KEY");

    address RELAYER_ADDRESS = vm.envAddress("RELAYER_ADDRESS");
    address TREASURY_ADDRESS = vm.envAddress("TREASURY_ADDRESS");

    // set up initial conditions or requirements
    function setUp() public {}

    // main entry point of the script
    function run() public {
        vm.startBroadcast(ownerPrivateKey);
        MoonPieV2 moonPie = new MoonPieV2(
            RELAYER_ADDRESS,
            TREASURY_ADDRESS,
            MoonPieV2.NETWORKS.ASSET_CHAIN // this needs to be changed on deployment, depending on the network being deployed to.
        );
        console.log("MOONPIE", address(moonPie));

        moonPie.setFeePercentage(2); // Set the fee percentage to 2%

        moonPie.setSupportedNetwork(MoonPieV2.NETWORKS.ASSET_CHAIN, "evm.42421");
        moonPie.setSupportedNetwork(MoonPieV2.NETWORKS.BASE, "evm.84532");
        moonPie.setSupportedNetwork(MoonPieV2.NETWORKS.ARBITRUM, "evm.421614");

        vm.stopBroadcast();
    }
}
