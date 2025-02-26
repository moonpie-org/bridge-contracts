// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Test} from "forge-std/Test.sol";
import "forge-std/console.sol";
import {MoonPie} from "src/v1/MoonPie.sol";
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

contract MoonPieSource is MoonPieSourceBase {
    function test_initialize() public {
        MoonPie moonPie = new MoonPie(
            RELAYER_ADDRESS,
            TREASURY_ADDRESS,
            MoonPie.NETWORKS.ASSET_CHAIN
        );
        assertEq(moonPie.RELAYER_ADDRESS(), RELAYER_ADDRESS);
    }

    function test_bridgeFailsWithZeroAmount() public {
        MoonPie moonPie = new MoonPie(
            RELAYER_ADDRESS,
            TREASURY_ADDRESS,
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
}
