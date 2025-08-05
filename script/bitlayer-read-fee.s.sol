// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Script, console} from "forge-std/Script.sol";
import {MoonPieV2} from "src/v2/MoonPieV2.sol";

contract BitlayerReadFeeScript is Script {
    // BitLayer mainnet deployed contract address
    address public constant CONTRACT_ADDRESS = 0x665Ae728eDa90cFAF13702f434E35B5b91e8C443; // BitLayer proxy
    
    function run() public {
        // Cast the address to your contract interface using payable
        MoonPieV2 moonPie = MoonPieV2(payable(address(CONTRACT_ADDRESS)));
        
        // Read the current fee percentage
        uint256 currentFee = moonPie.DEFAULT_FEE_PERCENTAGE();
        console.log("=== BitLayer Mainnet ===");
        console.log("Current fee percentage (basis points):", currentFee);
        console.log("Current fee percentage (%):", currentFee / 100, ".", currentFee % 100);
        
        address owner = moonPie.owner();
        console.log("Owner:", owner);
        // console.log("Relayer address:", relayer);
        // console.log("Treasury address:", treasury);
        // console.log("Current chain:", uint8(currentChain));
        
        // // Read supported networks
        // console.log("\n=== Supported Networks ===");
        // for (uint8 i = 0; i < 6; i++) {
        //     MoonPieV2.NETWORKS network = MoonPieV2.NETWORKS(i);
        //     MoonPieV2.NetworkInfo memory info = moonPie.supportedNetwork(network);
        //     if (info.isExists) {
        //         console.log("Network", i, ":", info.network);
        //     }
        // }
    }
} 