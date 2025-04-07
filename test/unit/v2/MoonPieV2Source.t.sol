// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Test} from "forge-std/Test.sol";
import "forge-std/console.sol";
import {MoonPieV2} from "src/v2/MoonPieV2.sol";
import {UsdcMock} from "../../mocks/UsdcMock.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import {IBridgeAssist} from "src/interfaces/IBridgeAssist.sol";
import {BaseScript, stdJson, console2} from "script/base.s.sol";
import {UnsafeUpgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import {BridgeAssistTransferUpgradeable} from "../../mocks/BridgeAssistTransferUpgradeable.sol";
import {EIP712Upgradeable} from "@openzeppelin/contracts-upgradeable/utils/cryptography/EIP712Upgradeable.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "forge-std/console2.sol";
import "../../base/MoonPieSourceBase.sol";

contract MoonPieV2Source is MoonPieSourceBase {
    function test_initialize() public {
        MoonPieV2 moonPie = new MoonPieV2(
            RELAYER_ADDRESS,
            TREASURY_ADDRESS,
            MoonPieV2.NETWORKS.ASSET_CHAIN
        );
        assertEq(moonPie.RELAYER_ADDRESS(), RELAYER_ADDRESS);
    }

    function test_bridgeFailsWithZeroAmount() public {
        MoonPieV2 moonPie = new MoonPieV2(
            RELAYER_ADDRESS,
            TREASURY_ADDRESS,
            MoonPieV2.NETWORKS.BASE
        );
        // User inputs zero amount
        vm.expectRevert(MoonPieV2.InvalidZeroAmount.selector);
        moonPie.bridge(
            mockTokenAddress,
            mockBridgeAddress,
            0,
            string.concat("0x", Strings.toHexString(uint160(address(1))))
        );
    }

    function test_bridgeInitiatedWithSuccess() public {
        MoonPieV2 moonPie = new MoonPieV2(
            RELAYER_ADDRESS,
            TREASURY_ADDRESS,
            MoonPieV2.NETWORKS.BASE
        );

        moonPie.setSupportedNetwork(MoonPieV2.NETWORKS.BASE, "evm.8453");
        moonPie.setSupportedNetwork(
            MoonPieV2.NETWORKS.ASSET_CHAIN,
            "evm.42420"
        );

        uint256 beforeBalance = usdc.balanceOf(mockBridgeAddress);
        uint256 treasuryBalanceBefore = usdc.balanceOf(TREASURY_ADDRESS);

        usdc.approve(address(moonPie), usdc.balanceOf(userAddress));

        // Only check that a BridgeInitiated event was emitted, ignore parameter values
        vm.expectEmit(false, false, false, false);
        emit MoonPieV2.BridgeInitiated(bytes32(0), "", 0);
        moonPie.bridge(
            mockTokenAddress,
            mockBridgeAddress,
            10 * 1e6,
            string.concat("0x", Strings.toHexString(uint160(address(1))))
        );

        // ensure bridge received funds
        uint256 afterBalance = usdc.balanceOf(mockBridgeAddress);
        assertEq(afterBalance - beforeBalance, 99 * 1e5); //  9.9

        // ensure moonpie treasury got expected fee
        uint256 treasuryBalanceAfter = usdc.balanceOf(TREASURY_ADDRESS);
        assertEq(treasuryBalanceAfter - treasuryBalanceBefore, 0.1 * 1e6); // 0.1
    }

    // @dev if amount is too large, we should exforce cap
    function test_registerTokenAndCheckFeeTheExceedsCap() public {
        MoonPieV2 moonPie = new MoonPieV2(
            RELAYER_ADDRESS,
            TREASURY_ADDRESS,
            MoonPieV2.NETWORKS.BASE
        );

        // Register a token with a fee cap
        moonPie.registerToken(mockTokenAddress, 5 * 1e6); // 5 tokens as fee cap

        // Set up the bridge
        moonPie.setSupportedNetwork(MoonPieV2.NETWORKS.BASE, "evm.8453");
        moonPie.setSupportedNetwork(
            MoonPieV2.NETWORKS.ASSET_CHAIN,
            "evm.42420"
        );

        uint256 amount = 1000 * 1e6; // 1000 tokens
        // Approve the token for the bridge
        usdc.approve(address(moonPie), amount);

        // Bridge with an amount more than cap
        uint256 expectedFee = 5000000; // 5 token as fee

        // Test bridging
        moonPie.bridge(
            mockTokenAddress,
            mockBridgeAddress,
            amount,
            string.concat("0x", Strings.toHexString(uint160(address(1))))
        );
        uint256 treasuryBalanceAfter = usdc.balanceOf(TREASURY_ADDRESS);

        assertEq(treasuryBalanceAfter, expectedFee);
    }

    // @dev amount being bridge is lower than the max fee cap
    function test_RevertIfAmountIsBelowFeeCap() public {
        MoonPieV2 moonPie = new MoonPieV2(
            RELAYER_ADDRESS,
            TREASURY_ADDRESS,
            MoonPieV2.NETWORKS.BASE
        );

        // Register a token with a fee cap
        moonPie.registerToken(mockTokenAddress, 5 * 1e6); // 5 tokens as fee cap

        // Set up the bridge
        moonPie.setSupportedNetwork(MoonPieV2.NETWORKS.BASE, "evm.8453");
        moonPie.setSupportedNetwork(
            MoonPieV2.NETWORKS.ASSET_CHAIN,
            "evm.42420"
        );

        // Approve the token for the bridge
        usdc.approve(address(moonPie), usdc.balanceOf(userAddress));

        // Bridge with an amount below the fee cap
        uint256 amount = 4 * 1e6; // 4 tokens, below the fee cap of 5 tokens
        vm.expectRevert(MoonPieV2.AmountBelowFeeCap.selector);
        moonPie.bridge(
            mockTokenAddress,
            mockBridgeAddress,
            amount,
            string.concat("0x", Strings.toHexString(uint160(address(1))))
        );
    }

    // @dev simulate bridging tokens with large values like btc
    function test_shouldChargeFeeCap() public {
        MoonPieV2 moonPie = new MoonPieV2(
            RELAYER_ADDRESS,
            TREASURY_ADDRESS,
            MoonPieV2.NETWORKS.BASE
        );

        // Register a token with a fee cap
        moonPie.registerToken(mockTokenAddress, 0.001 * 1e6); // 0.001 BTC as fee cap

        // Set up the bridge
        moonPie.setSupportedNetwork(MoonPieV2.NETWORKS.BASE, "evm.8453");
        moonPie.setSupportedNetwork(
            MoonPieV2.NETWORKS.ASSET_CHAIN,
            "evm.42420"
        );

        uint256 expectedFee = 0.001 * 1e6; // 0.001 BTC as fee

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
