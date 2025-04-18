// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Test} from "forge-std/Test.sol";
import "forge-std/console.sol";
import {MoonPieV2} from "src/v2/MoonPieV2.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import {IBridgeAssist} from "src/interfaces/IBridgeAssist.sol";
import "../../base/MoonPieSourceBase.sol";

contract MoonPieV2Source is MoonPieSourceBase {
    function test_initialize() public view {
        assertEq(moonPie.RELAYER_ADDRESS(), RELAYER_ADDRESS);
    }

    function test_bridgeFailsWithZeroAmount() public {
        vm.startPrank(userAddress);
        vm.expectRevert(MoonPieV2.InvalidZeroAmount.selector);
        moonPie.bridge(
            mockTokenAddress,
            mockBridgeAddress,
            0,
            string.concat("0x", Strings.toHexString(uint160(address(1))))
        );
        vm.stopPrank();
    }

    function test_bridgeInitiatedWithSuccess() public {
        uint256 beforeBalance = usdc.balanceOf(mockBridgeAddress);
        uint256 treasuryBalanceBefore = usdc.balanceOf(TREASURY_ADDRESS);

        vm.startPrank(userAddress);
        usdc.approve(address(moonPie), usdc.balanceOf(userAddress));

        vm.expectEmit(false, false, false, true);
        emit MoonPieV2.BridgeInitiated(bytes32(0), "", 9.9 * 1e6);
        moonPie.bridge(
            mockTokenAddress,
            mockBridgeAddress,
            10 * 1e6,
            string.concat("0x", Strings.toHexString(uint160(address(1))))
        );
        vm.stopPrank();

        uint256 afterBalance = usdc.balanceOf(mockBridgeAddress);
        assertEq(afterBalance - beforeBalance, 9.9 * 1e6); // 10 - 1% fee

        uint256 treasuryBalanceAfter = usdc.balanceOf(TREASURY_ADDRESS);
        assertEq(treasuryBalanceAfter - treasuryBalanceBefore, 0.1 * 1e6); // 1% fee
    }

    function test_registerTokenAndCheckFeeTheExceedsCap() public {
        vm.startPrank(msg.sender);
        moonPie.registerToken(mockTokenAddress, 5 * 1e6); // 5 tokens as fee cap
        vm.stopPrank();

        uint256 amount = 1000 * 1e6; // 1000 tokens
        uint256 expectedFee = 5 * 1e6; // Fee capped at 5 tokens

        vm.startPrank(userAddress);
        usdc.approve(address(moonPie), amount);
        moonPie.bridge(
            mockTokenAddress,
            mockBridgeAddress,
            amount,
            string.concat("0x", Strings.toHexString(uint160(address(1))))
        );
        vm.stopPrank();

        uint256 treasuryBalanceAfter = usdc.balanceOf(TREASURY_ADDRESS);
        assertEq(treasuryBalanceAfter, expectedFee);
    }

    function test_RevertIfAmountIsBelowFeeCap() public {
        vm.startPrank(msg.sender);
        moonPie.registerToken(mockTokenAddress, 5 * 1e6); // 5 tokens as
    }

    // @dev simulate bridging tokens with large values like btc
    function test_shouldChargeFeeCap() public {
        vm.startPrank(msg.sender);

        // Register a token with a fee cap
        moonPie.registerToken(mockTokenAddress, 0.001 * 1e6); // 0.001 BTC as fee cap

        uint256 expectedFee = 0.001 * 1e6; // 0.001 BTC as fee

        vm.startPrank(userAddress);
        // Approve the token for the bridge
        usdc.approve(address(moonPie), usdc.balanceOf(userAddress));

        uint256 amount = 1 * 1e6; // 1
        moonPie.bridge(
            mockTokenAddress,
            mockBridgeAddress,
            amount,
            string.concat("0x", Strings.toHexString(uint160(address(1))))
        );

        uint256 treasuryBalanceAfter = usdc.balanceOf(TREASURY_ADDRESS);
        assertEq(treasuryBalanceAfter, expectedFee);
    }


    function test_nativeBridgeInitiatedWithSuccess() public {
        // Fund the user with some ETH
        vm.deal(userAddress, 10 ether);

        // Record initial balances
        uint256 treasuryBalanceBefore = address(TREASURY_ADDRESS).balance;
        uint256 bridgeBalanceBefore = address(mockNativeBridgeAddress).balance;

        vm.startPrank(userAddress);

        // Calculate expected amounts
        uint256 totalAmount = 1 ether;
        uint256 expectedFee = (totalAmount * moonPie.DEFAULT_FEE_PERCENTAGE()) /
            10000; // 1%
        uint256 expectedAmountAfterFee = totalAmount - expectedFee;

        // vm.expectEmit(false, false, false, true);
        // emit MoonPieV2.BridgeInitiated(bytes32(0), "", expectedAmountAfterFee);

        // Bridge native token with value equal to amount
        moonPie.bridge{value: totalAmount}(
            moonPie.NATIVE_TOKEN(),
            mockNativeBridgeAddress,
            totalAmount,
            string.concat("0x", Strings.toHexString(uint160(address(1))))
        );

        vm.stopPrank();

        // Verify treasury received the fee
        uint256 treasuryBalanceAfter = address(TREASURY_ADDRESS).balance;
        assertEq(
            treasuryBalanceAfter - treasuryBalanceBefore,
            expectedFee,
            "Treasury did not receive correct fee"
        );

        // Verify bridge received the tokens after fee
        uint256 bridgeBalanceAfter = address(mockNativeBridgeAddress).balance;
        assertEq(
            bridgeBalanceAfter - bridgeBalanceBefore,
            expectedAmountAfterFee,
            "Bridge did not receive correct amount"
        );

        // Verify user's balance was reduced correctly
        uint256 userBalanceAfter = address(userAddress).balance;
        assertEq(
            userBalanceAfter,
            9 ether,
            "User balance wasn't reduced correctly"
        );
    }

    function test_nativeBridgeFailsWithInsufficientValue() public {
        // Fund the user with some ETH
        vm.deal(userAddress, 10 ether);

        vm.startPrank(userAddress);

        // Try to bridge with value not matching amount
        uint256 sendValue = 0.5 ether;
        uint256 declaredAmount = 1 ether;

        address NATIVE = moonPie.NATIVE_TOKEN();

        // vm.expectRevert();
        vm.expectRevert(MoonPieV2.InvalidInputAmount.selector);
        // vm.expectRevert("InvalidInputAmount()");
        moonPie.bridge{value: sendValue}(
            NATIVE,
            mockNativeBridgeAddress,
            declaredAmount,
            string.concat("0x", Strings.toHexString(uint160(address(1))))
        );

        vm.stopPrank();
    }
    

    function test_nativeBridgeWithRegisteredTokenFeeCap() public {
        address NATIVE = moonPie.NATIVE_TOKEN();
        // Register native token with a fee cap
        vm.startPrank(msg.sender);
        moonPie.registerToken(NATIVE, 0.05 ether); // Cap at 0.05 ETH
        vm.stopPrank();

        // Fund the user with some ETH
        vm.deal(userAddress, 10 ether);

        // Record initial balances
        uint256 treasuryBalanceBefore = address(TREASURY_ADDRESS).balance;
        uint256 bridgeBalanceBefore = address(mockNativeBridgeAddress).balance;

        vm.startPrank(userAddress);

        // Bridge a large amount to test fee capping
        uint256 totalAmount = 10 ether;
        uint256 expectedFee = 0.05 ether; // Fee should be capped at 0.05 ETH
        uint256 expectedAmountAfterFee = totalAmount - expectedFee;

        moonPie.bridge{value: totalAmount}(
            NATIVE,
            mockNativeBridgeAddress,
            totalAmount,
            string.concat("0x", Strings.toHexString(uint160(address(1))))
        );

        vm.stopPrank();

        // Verify treasury received the capped fee
        uint256 treasuryBalanceAfter = address(TREASURY_ADDRESS).balance;
        assertEq(
            treasuryBalanceAfter - treasuryBalanceBefore,
            expectedFee,
            "Treasury did not receive correct capped fee"
        );

        // Verify bridge received the tokens after fee
        uint256 bridgeBalanceAfter = address(mockNativeBridgeAddress).balance;
        assertEq(
            bridgeBalanceAfter - bridgeBalanceBefore,
            expectedAmountAfterFee,
            "Bridge did not receive correct amount after capped fee"
        );
    }
}
