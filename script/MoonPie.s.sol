// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Script, console} from "forge-std/Script.sol";
import {MoonPieV2} from "src/v2/MoonPieV2.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";

contract MoonPieScript is Script {
    uint256 ownerPrivateKey = vm.envUint("OWNER_PRV_KEY");

    address RELAYER_ADDRESS = vm.envAddress("RELAYER_ADDRESS");
    address TREASURY_ADDRESS = vm.envAddress("TREASURY_ADDRESS");

    // Set up initial conditions or requirements
    function setUp() public {}

    // Main entry point of the script
    function run() public {
        vm.startBroadcast(ownerPrivateKey);

        // Step 1: Deploy the implementation contract
        MoonPieV2 moonPieImpl = new MoonPieV2();
        console.log("MoonPieV2 Implementation deployed at:", address(moonPieImpl));

        // Step 2: Deploy the ProxyAdmin (controls upgrades)
        ProxyAdmin proxyAdmin = new ProxyAdmin(msg.sender); // Set treasury as admin, or use msg.sender
        console.log("ProxyAdmin deployed at:", address(proxyAdmin));

        // Step 3: Prepare initialization data
        bytes memory initData = abi.encodeWithSelector(
            MoonPieV2.initialize.selector,
            RELAYER_ADDRESS,
            TREASURY_ADDRESS,
            MoonPieV2.NETWORKS.ASSET_CHAIN // Adjust based on deployment network
        );

        // Step 4: Deploy the TransparentUpgradeableProxy
        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(
            address(moonPieImpl),
            address(proxyAdmin),
            initData
        );
        console.log("MoonPieV2 Proxy deployed at:", address(proxy));

        // Step 5: Interact with the proxy as MoonPieV2
        MoonPieV2 moonPie = MoonPieV2(payable(address(proxy)));

        // Step 6: Configure the contract
        // moonPie.setDefaultFeePercentage(100); // Set the fee percentage to 1%

        moonPie.setSupportedNetwork(MoonPieV2.NETWORKS.ASSET_CHAIN, "evm.42421");
        moonPie.setSupportedNetwork(MoonPieV2.NETWORKS.BASE, "evm.84532");
        moonPie.setSupportedNetwork(MoonPieV2.NETWORKS.ARBITRUM, "evm.421614");

        // Verify some settings
        console.log("Default Fee Percentage:", moonPie.DEFAULT_FEE_PERCENTAGE());
        console.log("Treasury Address:", moonPie.TREASURY_ADDRESS());

        vm.stopBroadcast();
    }
}