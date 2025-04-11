// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Script, console} from "forge-std/Script.sol";
import {MoonPieV2} from "src/v2/MoonPieV2.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";

/* 
// assetchain
  MoonPieV2 Implementation deployed at: 0x9c92D85821aDadC8B079b7EA018761a1798B15c2
  ProxyAdmin deployed at: 0xfd9D0FCCa509210e4C5c0903a9c1DbD13250e01e
  MoonPieV2 Proxy deployed at: 0xBECe8b1D79204adEC55D74EfE8E4b15796437B8f
  Default Fee Percentage: 100
  Treasury Address: 0x377123Ed74fBE8ddb47E30aEbCf267c55EFa7b33


// aribitrum
  ProxyAdmin deployed at: 0x7D4057d2A19f685C43323426b06CF0fa46b0792f
  MoonPieV2 Proxy deployed at: 0x0e68b1f2AE192F92d9e0C6FbDC4e2d17F3A7516C
  Default Fee Percentage: 100
  Treasury Address: 0x377123Ed74fBE8ddb47E30aEbCf267c55EFa7b33


// base
  MoonPieV2 Implementation deployed at: 0x2262e53F537E7805EB70FBA91d55241fc571BBfA
  ProxyAdmin deployed at: 0x17878B5a24a7DDf3B2725894feaC1909b0d060c4
  MoonPieV2 Proxy deployed at: 0x41daC6aD742DD5BA7681c70B03699227E8840989
  Default Fee Percentage: 100
  Treasury Address: 0x377123Ed74fBE8ddb47E30aEbCf267c55EFa7b33

 */

contract MoonPieScript is Script {
    uint256 ownerPrivateKey = vm.envUint("OWNER_PRV_KEY");

    address RELAYER_ADDRESS = vm.envAddress("RELAYER_ADDRESS");
    address TREASURY_ADDRESS = vm.envAddress("TREASURY_ADDRESS");

    // Set up initial conditions or requirements
    function setUp() public {}

    // Main entry point of the script
    function run() public {
        vm.startBroadcast(ownerPrivateKey);

        console.log('msg.sender');
        console.log(msg.sender);

        // Step 1: Deploy the implementation contract
        MoonPieV2 moonPieImpl = new MoonPieV2();
        console.log(
            "MoonPieV2 Implementation deployed at:",
            address(moonPieImpl)
        );

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

        moonPie.setSupportedNetwork(
            MoonPieV2.NETWORKS.ASSET_CHAIN,
            "evm.42421"
        );
        moonPie.setSupportedNetwork(MoonPieV2.NETWORKS.BASE, "evm.84532");
        moonPie.setSupportedNetwork(MoonPieV2.NETWORKS.ARBITRUM, "evm.421614");

        // Verify some settings
        console.log(
            "Default Fee Percentage:",
            moonPie.DEFAULT_FEE_PERCENTAGE()
        );
        console.log("Treasury Address:", moonPie.TREASURY_ADDRESS());

        vm.stopBroadcast();
    }
}
