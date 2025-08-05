// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Script, console} from "forge-std/Script.sol";
import {MoonPieV2} from "src/v2/MoonPieV2.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";

/* 
  // base
  MoonPieV2 Implementation deployed at: 0x5F9bdfDe65D462Af41E7AB0FEA909B3292d75259
  ProxyAdmin deployed at: 0x8582Fb323e32C5A4539063130eC56b0eD2FF3b85
  MoonPieV2 Proxy deployed at: 0x9d5d330C18FDb3Af2BC99187Ab19645CA395ACD5

  // assetchain
    MoonPieV2 Implementation deployed at: 0x13cC0012863C34f7ba7ff4da6Ad79bdA65B70276
  ProxyAdmin deployed at: 0x4567d57F18eF5fc30769a335Ebb1054E148e690a
  MoonPieV2 Proxy deployed at: 0x3ef2Dfe905502b82b1f47bCF5D4B13C0Fc7CE10f

  // arbitrum
    MoonPieV2 Implementation deployed at: 0x8091Ff2549836719B2275a55975D4AFc013Be6C6
  ProxyAdmin deployed at: 0x3A425EEF8376a6B6BFA38eaA2B374Bf71163486F
  MoonPieV2 Proxy deployed at: 0x3B030B479116D4AC55793968e677d07660C0C0d5

  // bsc
    MoonPieV2 Implementation deployed at: 0xEf680bDad22708741591558f83c9dCDf25f65203
  ProxyAdmin deployed at: 0x0d7C16FE961833a999342Ba1206E36F99e6377A4
  MoonPieV2 Proxy deployed at: 0x665Ae728eDa90cFAF13702f434E35B5b91e8C443

  // bitlayer
  MoonPieV2 Implementation deployed at: 0xEf680bDad22708741591558f83c9dCDf25f65203
  ProxyAdmin deployed at: 0x0d7C16FE961833a999342Ba1206E36F99e6377A4
  MoonPieV2 Proxy deployed at: 0x665Ae728eDa90cFAF13702f434E35B5b91e8C443

  // ETHEREUM
    MoonPieV2 Implementation deployed at: 0xEf680bDad22708741591558f83c9dCDf25f65203
  ProxyAdmin deployed at: 0x0d7C16FE961833a999342Ba1206E36F99e6377A4
  MoonPieV2 Proxy deployed at: 0x665Ae728eDa90cFAF13702f434E35B5b91e8C443

 */

/// @title MoonPie mainnet deployment script
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
            MoonPieV2.NETWORKS.ETHEREUM // Adjust based on deployment network
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
            "evm.42420"
        );
        moonPie.setSupportedNetwork(MoonPieV2.NETWORKS.BASE, "evm.8453");
        moonPie.setSupportedNetwork(MoonPieV2.NETWORKS.ARBITRUM, "evm.42161");

        moonPie.setSupportedNetwork(MoonPieV2.NETWORKS.ETHEREUM, "evm.1");
        moonPie.setSupportedNetwork(MoonPieV2.NETWORKS.BITLAYER, "evm.200901");
        moonPie.setSupportedNetwork(MoonPieV2.NETWORKS.BSC, "evm.56");

        // Verify some settings
        console.log(
            "Default Fee Percentage:",
            moonPie.DEFAULT_FEE_PERCENTAGE()
        );
        console.log("Treasury Address:", moonPie.TREASURY_ADDRESS());

        vm.stopBroadcast();
    }
}
