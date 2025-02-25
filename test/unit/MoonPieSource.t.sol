// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Test} from "forge-std/Test.sol";
import "forge-std/console.sol";
import {MoonPie} from "src/MoonPie.sol";
import {UsdcMock} from "../mocks/UsdcMock.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import {IBridgeAssist} from "src/interfaces/IBridgeAssist.sol";
import {BaseScript, stdJson, console2} from "script/base.s.sol";
import {UnsafeUpgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import {BridgeAssistTransferUpgradeable} from "../mocks/BridgeAssistTransferUpgradeable.sol";
import {EIP712Upgradeable} from "@openzeppelin/contracts-upgradeable/utils/cryptography/EIP712Upgradeable.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "forge-std/console2.sol";
import "../base/MoonPieSourceBase.sol";

contract MoonPieSource is MoonPieSourceBase {
    function test_initialize() public {
        MoonPie moonPie = new MoonPie(
            RELAYER_ADDRESS,
            TREASURY_ADDRESS,
            WRWA_ADDRESS,
            SWAP_ROUTER_ADDRESS,
            NATIVE_RWA_TOKEN_ADDRESS,
            MoonPie.NETWORKS.ASSET_CHAIN
        );
        assertEq(moonPie.RELAYER_ADDRESS(), RELAYER_ADDRESS);
    }

    /*     function test_bridgeFailsWithoutApproval() public {
        MoonPie moonPie = new MoonPie(
            RELAYER_ADDRESS,
            TREASURY_ADDRESS,
            WRWA_ADDRESS,
            SWAP_ROUTER_ADDRESS,
            NATIVE_RWA_TOKEN_ADDRESS
        );

        // Use expectRevert with the encoded error including parameters
        vm.expectRevert(
            abi.encodeWithSelector(
                MoonPie.ERC20InsufficientAllowance.selector,
                address(moonPie), // spender
                0, // allowance
                10 * 1e6 // needed
            )
        );
        moonPie.bridge(mockTokenAddress, mockBridgeAddress, 10 * 1e6);
    } */

    function test_bridgeFailsWithZeroAmount() public {
        MoonPie moonPie = new MoonPie(
            RELAYER_ADDRESS,
            TREASURY_ADDRESS,
            WRWA_ADDRESS,
            SWAP_ROUTER_ADDRESS,
            NATIVE_RWA_TOKEN_ADDRESS,
            MoonPie.NETWORKS.BASE
        );
        // User inputs zero amount
        vm.expectRevert(MoonPie.InvalidZeroAmount.selector);
        moonPie.bridge(
            mockTokenAddress,
            mockBridgeAddress,
            0,
            string.concat("0x", Strings.toHexString(uint160(address(1))))
        );
    }

    function test_bridgeInitiatedWithSuccess() public {
        MoonPie moonPie = new MoonPie(
            RELAYER_ADDRESS,
            TREASURY_ADDRESS,
            WRWA_ADDRESS,
            SWAP_ROUTER_ADDRESS,
            NATIVE_RWA_TOKEN_ADDRESS,
            MoonPie.NETWORKS.BASE
        );
        uint256 beforeBalance = usdc.balanceOf(mockBridgeAddress);
        uint256 treasuryBalanceBefore = usdc.balanceOf(TREASURY_ADDRESS);

        usdc.approve(address(moonPie), usdc.balanceOf(userAddress));

        // Only check that a BridgeInitiated event was emitted, ignore parameter values
        vm.expectEmit(false, false, false,false);
        emit MoonPie.BridgeInitiated(bytes32(0),"", 0);
        moonPie.bridge(
            mockTokenAddress,
            mockBridgeAddress,
            10 * 1e6,
            string.concat("0x", Strings.toHexString(uint160(address(1))))
        );

        // ensure bridge received funds
        uint256 afterBalance = usdc.balanceOf(mockBridgeAddress);
        assertEq(afterBalance - beforeBalance, 99 * 1e5);   //  9.9

        // ensure moonpie treasury got expected fee
        uint256 treasuryBalanceAfter = usdc.balanceOf(TREASURY_ADDRESS);
        assertEq(treasuryBalanceAfter - treasuryBalanceBefore, 0.1 * 1e6); // 0.1
    }

    /* /// @dev Fulfill a bridge transaction, from Base to Asset Chain mainnet.
    function test_bridgeFulfillmentSuccess() public {
        vm.startPrank(USDC_WHALE);

        string memory BASE = "evm.8453";
        MoonPie moonPie = new MoonPie(RELAYER_ADDRESS, TREASURY_ADDRESS);

        // fund destination bridge with token
        // usdc.transfer(mockBridgeAddress, 100 * 1e6);
        usdc.transfer(mockBridgeAddress, 100 * 1e6);


        IBridgeAssist.FulfillTx memory fulfillTx = IBridgeAssist.FulfillTx({
            amount: 99 * 1e5,
            fromUser: Strings.toHexString(uint160(userAddress)),
            toUser: userAddress,
            fromChain: BASE,
            nonce: 0
        });

        bytes[] memory signatures = _signTransaction(fulfillTx);

        vm.startPrank(RELAYER_ADDRESS);
        moonPie.completeBridge(
            "0",
            fulfillTx,
            signatures,
            address(usdc),
            mockBridgeAddress
        );
    } */

    /* function test_bridgeFulfillmentFailsWithInvalidSignature() public {
        MoonPie moonPie = new MoonPie(
            RELAYER_ADDRESS_as_string,
            TREASURY_ADDRESS
        );
        // Set up the transaction details
        address fromUser = address(0x123);
        address toUser = userAddress;
        uint256 amount = 10 * 1e6; // Assuming the token has 6 decimals
        uint256 timestamp = 666;
        string memory fromChain = "nearChain";
        string memory toChain = "evmChain";
        uint256 nonce = 0;

        // Prepare the transaction
        bytes memory txData = abi.encode(
            fromUser,
            toUser,
            amount,
            timestamp,
            fromChain,
            toChain,
            nonce
        );

        // Sign the transaction with an invalid key
        bytes memory invalidSignature = vm.sign(address(0).code, txData);

        // Attempt to fulfill the transaction with the invalid signature
        vm.expectRevert(MoonPie.InvalidSignature.selector);
        moonPie.fulfill(txData, invalidSignature);
    } */
}
