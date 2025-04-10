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
}
