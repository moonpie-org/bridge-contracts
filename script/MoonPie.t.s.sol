// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Script, console} from "forge-std/Script.sol";
import {MoonPieV2} from "src/v2/MoonPieV2.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";

/* 
// assetchain
  MoonPieV2 Implementation deployed at: 0x9ed45ce94395d3a8c6e96ACDbF2d17fc8DBDd140
  ProxyAdmin deployed at: 0x68982592dB2533d5F8e9Af7ef42Bb923858BeEDf
  MoonPieV2 Proxy deployed at: 0x55bd049f934b20805609fE484Aa500ef51B0ee8A

// arbitrum
    MoonPieV2 Implementation deployed at: 0x4f625f42BfA4796F0CA2A204dccd76364E2C433B
  ProxyAdmin deployed at: 0x93F5A066d2F256051Aad563D1DC6b11Ed26f0304
  MoonPieV2 Proxy deployed at: 0x381AFE71090cf71B75a886EA8833dfc9683c57b6

// base
  MoonPieV2 Implementation deployed at: 0x1b577D56F0EffCd7808e9e7579CAaB27D7ae951B
  ProxyAdmin deployed at: 0x338B432fD6E26f518F70450452bC81ab5911ddD9
  MoonPieV2 Proxy deployed at: 0xC442e76df720456535dfE53BDc6100C48a4A9CBf

// bitlayer
  MoonPieV2 Implementation deployed at: 0x231e9744b6FfD9Ecda91eA0Efc4d999003ffCAc0
  ProxyAdmin deployed at: 0xd31bf7b1A41C63e0ecE8c50D7DA8E109352b888B
  MoonPieV2 Proxy deployed at: 0xDe0c2ECF19BeDDE01ea0e139224b1319460BC7d1

 */

/// @title MoonPie testnet deployment script
contract MoonPieScript is Script {
    uint256 ownerPrivateKey = vm.envUint("OWNER_PRV_KEY");

    address RELAYER_ADDRESS = vm.envAddress("RELAYER_ADDRESS");
    address TREASURY_ADDRESS = vm.envAddress("TREASURY_ADDRESS");

    // Set up initial conditions or requirements
    function setUp() public {}

    // Main entry point of the script
    function run() public {
        vm.startBroadcast(ownerPrivateKey);

        console.log("msg.sender");
        console.log(msg.sender);

        // Step 1: Deploy the implementation contract
        MoonPieV2 moonPieImpl = new MoonPieV2();
        console.log(
            "MoonPieV2 Implementation deployed at:",
            address(moonPieImpl)
        );

        // Step 2: Deploy the ProxyAdmin (controls upgrades)
        ProxyAdmin proxyAdmin = new ProxyAdmin(msg.sender);
        console.log("ProxyAdmin deployed at:", address(proxyAdmin));

        // Step 3: Prepare initialization data
        bytes memory initData = abi.encodeWithSelector(
            MoonPieV2.initialize.selector,
            RELAYER_ADDRESS,
            TREASURY_ADDRESS,
            MoonPieV2.NETWORKS.BITLAYER // Adjust based on deployment network
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

        moonPie.setSupportedNetwork(
            MoonPieV2.NETWORKS.ETHEREUM,
            "evm.11155111"
        );
        moonPie.setSupportedNetwork(MoonPieV2.NETWORKS.BITLAYER, "evm.200810");
        moonPie.setSupportedNetwork(MoonPieV2.NETWORKS.BSC, "evm.97");

        // Verify some settings
        console.log(
            "Default Fee Percentage:",
            moonPie.DEFAULT_FEE_PERCENTAGE()
        );
        console.log("Treasury Address:", moonPie.TREASURY_ADDRESS());

        vm.stopBroadcast();
    }
}
