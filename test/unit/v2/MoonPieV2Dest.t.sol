// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Test} from "forge-std/Test.sol";
import "forge-std/console.sol";
import {MoonPieV2} from "src/v2/MoonPieV2.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import {IBridgeAssist} from "src/interfaces/IBridgeAssist.sol";
import "../../base/MoonPieDestBase.sol";

contract MoonPieV2Dest is MoonPieDestBase {
    function test_initialize() public view {
        assertEq(moonPie.RELAYER_ADDRESS(), RELAYER_ADDRESS);
    }

    function test_bridgeFulfillmentFailsIfNotRelayer() public {
        IBridgeAssist.FulfillTx memory fulfillTx = IBridgeAssist.FulfillTx({
            amount: 1 * 1e18,
            fromUser: Strings.toHexString(uint160(userAddress)),
            toUser: address(moonPie),
            fromChain: "evm.8453", // base
            nonce: 0
        });
        bytes[] memory signatures = _signTransaction(fulfillTx, mockBridgeAddress);

        vm.expectRevert(MoonPieV2.OnlyRelayerAllowed.selector);
        moonPie.completeBridge(
            "0",
            fulfillTx,
            signatures,
            address(ASSETCHAIN_USDT),
            mockBridgeAddress,
            userAddress
        );
    }

    function test_completeBridge_revertsIfDestinationTokenBridgeIsZero() public {
        IBridgeAssist.FulfillTx memory fulfillTx = IBridgeAssist.FulfillTx({
            amount: 1 * 1e18,
            fromUser: Strings.toHexString(uint160(userAddress)),
            toUser: address(moonPie),
            fromChain: "evm.8453", // base
            nonce: 0
        });
        bytes[] memory signatures = _signTransaction(fulfillTx, mockBridgeAddress);

        vm.startPrank(USDT_WHALE);
        ERC20(ASSETCHAIN_USDT).transfer(mockBridgeAddress, 10 * 1e18);
        vm.stopPrank();

        vm.startPrank(RELAYER_ADDRESS);
        vm.expectRevert(MoonPieV2.InvalidAddress.selector);
        moonPie.completeBridge(
            "0",
            fulfillTx,
            signatures,
            address(ASSETCHAIN_USDT),
            address(0),
            userAddress
        );
        vm.stopPrank();
    }

    function test_completeBridge_revertsIfRecipientIsZero() public {
        IBridgeAssist.FulfillTx memory fulfillTx = IBridgeAssist.FulfillTx({
            amount: 1 * 1e18,
            fromUser: Strings.toHexString(uint160(userAddress)),
            toUser: address(moonPie),
            fromChain: "evm.8453", // base
            nonce: 0
        });
        bytes[] memory signatures = _signTransaction(fulfillTx, mockBridgeAddress);

        vm.startPrank(USDT_WHALE);
        ERC20(ASSETCHAIN_USDT).transfer(mockBridgeAddress, 10 * 1e18);
        vm.stopPrank();

        vm.startPrank(RELAYER_ADDRESS);
        vm.expectRevert(MoonPieV2.InvalidAddress.selector);
        moonPie.completeBridge(
            "0",
            fulfillTx,
            signatures,
            address(ASSETCHAIN_USDT),
            mockBridgeAddress,
            address(0)
        );
        vm.stopPrank();
    }

    function test_completeBridge_revertsIfAmountIsZero() public {
        IBridgeAssist.FulfillTx memory fulfillTx = IBridgeAssist.FulfillTx({
            amount: 0,
            fromUser: Strings.toHexString(uint160(userAddress)),
            toUser: address(moonPie),
            fromChain: "evm.8453", // base
            nonce: 0
        });
        bytes[] memory signatures = _signTransaction(fulfillTx, mockBridgeAddress);

        vm.startPrank(USDT_WHALE);
        ERC20(ASSETCHAIN_USDT).transfer(mockBridgeAddress, 10 * 1e18);
        vm.stopPrank();

        vm.startPrank(RELAYER_ADDRESS);
        vm.expectRevert(MoonPieV2.InvalidZeroAmount.selector);
        moonPie.completeBridge(
            "0",
            fulfillTx,
            signatures,
            address(ASSETCHAIN_USDT),
            mockBridgeAddress,
            userAddress
        );
        vm.stopPrank();
    }

    function test_completeBridge_revertsIfSourceChainNotSupported() public {
        IBridgeAssist.FulfillTx memory fulfillTx = IBridgeAssist.FulfillTx({
            amount: 1 * 1e18,
            fromUser: Strings.toHexString(uint160(userAddress)),
            toUser: address(moonPie),
            fromChain: "evm.1234", // unsupported
            nonce: 0
        });
        bytes[] memory signatures = _signTransaction(fulfillTx, mockBridgeAddress);

        vm.startPrank(USDT_WHALE);
        ERC20(ASSETCHAIN_USDT).transfer(mockBridgeAddress,  10 * 1e18);
        vm.stopPrank();

        vm.startPrank(RELAYER_ADDRESS);
        vm.expectRevert(MoonPieV2.SourceChainNotSupported.selector);
        moonPie.completeBridge(
            "0",
            fulfillTx,
            signatures,
            address(ASSETCHAIN_USDT),
            mockBridgeAddress,
            userAddress
        );
        vm.stopPrank();
    }

    function test_bridgeFulfillmentSuccess() public {
        vm.startPrank(USDT_WHALE);
        ERC20(ASSETCHAIN_USDT).transfer(mockBridgeAddress, 10 * 1e18);
        vm.stopPrank();

        uint256 userUsdtBalanceBefore = ERC20(ASSETCHAIN_USDT).balanceOf(userAddress);

        IBridgeAssist.FulfillTx memory fulfillTx = IBridgeAssist.FulfillTx({
            amount: 1 * 1e18,
            fromUser: Strings.toHexString(uint160(userAddress)),
            toUser: userAddress,
            fromChain: "evm.8453", // base
            nonce: 0
        });
        bytes[] memory signatures = _signTransaction(fulfillTx, mockBridgeAddress);

        vm.startPrank(RELAYER_ADDRESS);
        moonPie.completeBridge(
            "0",
            fulfillTx,
            signatures,
            address(ASSETCHAIN_USDT),
            mockBridgeAddress,
            userAddress
        );
        vm.stopPrank();

        uint256 userUsdtBalanceAfter = ERC20(ASSETCHAIN_USDT).balanceOf(userAddress);
        assertGt(userUsdtBalanceAfter, userUsdtBalanceBefore);
    }

    function test_bridgeTokenSuccess() public {
        vm.startPrank(USDT_WHALE);
        ERC20(ASSETCHAIN_USDT).transfer(mockBridgeAddress, 10 * 1e18);
        vm.stopPrank();

        uint256 userUsdtBalanceBefore = ERC20(ASSETCHAIN_USDT).balanceOf(userAddress);

        IBridgeAssist.FulfillTx memory fulfillTx = IBridgeAssist.FulfillTx({
            amount: 1 * 1e18,
            fromUser: Strings.toHexString(uint160(userAddress)),
            toUser: userAddress,
            fromChain: "evm.8453", // base
            nonce: 0
        });
        bytes[] memory signatures = _signTransaction(fulfillTx, mockBridgeAddress);

        vm.startPrank(RELAYER_ADDRESS);
        moonPie.completeBridge(
            "0",
            fulfillTx,
            signatures,
            address(ASSETCHAIN_USDT),
            mockBridgeAddress,
            userAddress
        );
        vm.stopPrank();

        uint256 userUsdtBalanceAfter = ERC20(ASSETCHAIN_USDT).balanceOf(userAddress);
        assertGt(userUsdtBalanceAfter, userUsdtBalanceBefore);
    }

    function test_bridgeRWASuccess() public {
        vm.deal(mockNativeBridgeAddress, 20 * 1e18);

        uint256 userRwaBalanceBefore = userAddress.balance;

        IBridgeAssist.FulfillTx memory fulfillTx = IBridgeAssist.FulfillTx({
            amount: 1 * 1e18,
            fromUser: Strings.toHexString(uint160(userAddress)),
            toUser: userAddress,
            fromChain: "evm.42161", // arbitrum
            nonce: 0
        });
        bytes[] memory signatures = _signTransaction(fulfillTx, mockNativeBridgeAddress);

        vm.startPrank(RELAYER_ADDRESS);
        moonPie.completeBridge(
            "0",
            fulfillTx,
            signatures,
            address(NATIVE_RWA),
            mockNativeBridgeAddress,
            userAddress
        );
        vm.stopPrank();

        uint256 userRwaBalanceAfter = userAddress.balance;
        assertGt(userRwaBalanceAfter, userRwaBalanceBefore);
    }
}