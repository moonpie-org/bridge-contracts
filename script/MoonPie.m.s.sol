// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Script, console} from "forge-std/Script.sol";
import {MoonPieV2} from "src/v2/MoonPieV2.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";

/* 
// assetchain
  MoonPieV2 Implementation deployed at: 0x5e033B7826C8C9d36bd80fFC926e65743c08c82c
  ProxyAdmin deployed at: 0xBc6fCD79E68F8a879A913702378e7064cBc323c5
  MoonPieV2 Proxy deployed at: 0x74CCa740af0EBB235057df8e441f0F2f9D21d8c3

//   arbitrum
    MoonPieV2 Implementation deployed at: 0x2B7C1342Cc64add10B2a79C8f9767d2667DE64B2
  ProxyAdmin deployed at: 0x582eDb9E96750C819791c0353f2233EcCC7d3313
  MoonPieV2 Proxy deployed at: 0xeD8AEcbA1743cBb01FAFE454524e8ee238C09c3B

//   base
  MoonPieV2 Implementation deployed at: 0x10244648dB5d97B2F8607fe8E012E78b73ca8b3F
  ProxyAdmin deployed at: 0x05F66cdE041477f3D7D1Da7C703B978f573BD9e5
  MoonPieV2 Proxy deployed at: 0x46e4450fcC5fE1b8C93694562a1330D5456b94A2

//   bsc
    MoonPieV2 Implementation deployed at: 0x17e0D1239eA25904C66CFD4D051Ed0592Ad42fCe
  ProxyAdmin deployed at: 0x991603DA1C59cAB3C49c37C506820f5bF07AdC55
  MoonPieV2 Proxy deployed at: 0x5d2451c57c167B1437635f77f00acc35c326BAf1

//   ethereum
    MoonPieV2 Implementation deployed at: 0x10244648dB5d97B2F8607fe8E012E78b73ca8b3F
  ProxyAdmin deployed at: 0x05F66cdE041477f3D7D1Da7C703B978f573BD9e5
  MoonPieV2 Proxy deployed at: 0x46e4450fcC5fE1b8C93694562a1330D5456b94A2

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

/* 
  //  bitlayer
  MoonPieV2 Implementation deployed at: 0x904d6bea6f53bb3fD7a4E6799B414B0b0Df0D0aa
  ProxyAdmin deployed at: 0xc62c54d2439cE43D767B7b44939744BA1606feB2
  MoonPieV2 Proxy deployed at: 0xFb727149C76dCa52F58b1AD73667eCe1d012FbBb
   */