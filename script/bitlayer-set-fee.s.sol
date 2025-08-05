// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Script, console} from "forge-std/Script.sol";
import {MoonPieV2} from "src/v2/MoonPieV2.sol";

contract BitlayerSetFeeScript is Script {
    // BitLayer mainnet deployed contract address
    address public constant CONTRACT_ADDRESS = 0x665Ae728eDa90cFAF13702f434E35B5b91e8C443; // BitLayer proxy
    
    function run() public {
        // Start broadcasting transactions
        vm.startBroadcast();
        
        // Cast the address to your contract interface using payable(address(proxy))
        MoonPieV2 moonPie = MoonPieV2(payable(address(CONTRACT_ADDRESS)));
        
        // Read current fee
        uint256 currentFee = moonPie.DEFAULT_FEE_PERCENTAGE();
        console.log("=== BitLayer Mainnet ===");
        console.log("Current fee percentage (basis points):", currentFee);
        console.log("Current fee percentage (%):", currentFee / 100, ".", currentFee % 100);
        
        // Set new fee (50 bps = 0.5%)
        uint256 newFee = 50;
        moonPie.setDefaultFeePercentage(newFee);
        console.log("Fee updated to:", newFee, "basis points (0.5%)");
        
        // Verify the change
        uint256 updatedFee = moonPie.DEFAULT_FEE_PERCENTAGE();
        console.log("Verified fee percentage:", updatedFee);
        
        vm.stopBroadcast();
    }
} 