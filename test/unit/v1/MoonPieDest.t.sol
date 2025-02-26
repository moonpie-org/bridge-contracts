// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Test} from "forge-std/Test.sol";
import "forge-std/console.sol";
import {MoonPie} from "src/v1/MoonPie.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import {IBridgeAssist} from "src/interfaces/IBridgeAssist.sol";
import {BaseScript, stdJson, console2} from "script/base.s.sol";
import {UnsafeUpgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import {BridgeAssistTransferUpgradeable} from "../../mocks/BridgeAssistTransferUpgradeable.sol";
import {EIP712Upgradeable} from "@openzeppelin/contracts-upgradeable/utils/cryptography/EIP712Upgradeable.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "forge-std/console2.sol";
import "../../base/MoonPieDestBase.sol";

contract MoonPieDest is MoonPieDestBase {
    function test_initialize() public {
        MoonPie moonPie = new MoonPie(
            RELAYER_ADDRESS,
            TREASURY_ADDRESS,
            MoonPie.NETWORKS.ASSET_CHAIN
        );
        assertEq(moonPie.RELAYER_ADDRESS(), RELAYER_ADDRESS);
    }

    function test_bridgeFulfillmentFailsIfNotRelayer() public {
        MoonPie moonPie = new MoonPie(
            RELAYER_ADDRESS,
            TREASURY_ADDRESS,
            MoonPie.NETWORKS.ASSET_CHAIN
        );
        IBridgeAssist.FulfillTx memory fulfillTx = IBridgeAssist.FulfillTx({
            amount: 1 * 1e18,
            fromUser: Strings.toHexString(uint160(userAddress)),
            toUser: address(moonPie),
            fromChain: "evm.8453", // base
            nonce: 0
        });
        bytes[] memory signatures = _signTransaction(fulfillTx,mockBridgeAddress);

        // Use expectRevert with the encoded error including parameters
        vm.expectRevert(MoonPie.OnlyRelayerAllowed.selector);
        moonPie.completeBridge(
            "0",
            fulfillTx,
            signatures,
            address(ASSETCHAIN_USDT),
            mockBridgeAddress,
            userAddress
        );
    }

    function test_completeBridge_revertsIfDestinationTokenBridgeIsZero()
        public
    {
        MoonPie moonPie = new MoonPie(
            RELAYER_ADDRESS,
            TREASURY_ADDRESS,
            MoonPie.NETWORKS.ASSET_CHAIN
        );
        IBridgeAssist.FulfillTx memory fulfillTx = IBridgeAssist.FulfillTx({
            amount: 1 * 1e18,
            fromUser: Strings.toHexString(uint160(userAddress)),
            toUser: address(moonPie),
            fromChain: "evm.8453", // base
            nonce: 0
        });
        bytes[] memory signatures = _signTransaction(fulfillTx,mockBridgeAddress);

        vm.startPrank(USDT_WHALE);
        ERC20(ASSETCHAIN_USDT).transfer(mockBridgeAddress, 10 * 1e18);
        vm.stopPrank();

        vm.startPrank(RELAYER_ADDRESS);
        // Use expectRevert with the encoded error including parameters
        vm.expectRevert(MoonPie.InvalidAddress.selector);
        moonPie.completeBridge(
            "0",
            fulfillTx,
            signatures,
            address(ASSETCHAIN_USDT),
            address(0),
            userAddress
        );
    }

    function test_completeBridge_revertsIfRecipientIsZero() public {
        MoonPie moonPie = new MoonPie(
            RELAYER_ADDRESS,
            TREASURY_ADDRESS,
            MoonPie.NETWORKS.ASSET_CHAIN
        );
        IBridgeAssist.FulfillTx memory fulfillTx = IBridgeAssist.FulfillTx({
            amount: 1 * 1e18,
            fromUser: Strings.toHexString(uint160(userAddress)),
            toUser: address(moonPie),
            fromChain: "evm.8453", // base
            nonce: 0
        });
        bytes[] memory signatures = _signTransaction(fulfillTx,mockBridgeAddress);

        vm.startPrank(USDT_WHALE);
        ERC20(ASSETCHAIN_USDT).transfer(mockBridgeAddress, 10 * 1e18);
        vm.stopPrank();

        vm.startPrank(RELAYER_ADDRESS);
        // Use expectRevert with the encoded error including parameters
        vm.expectRevert(MoonPie.InvalidAddress.selector);
        moonPie.completeBridge(
            "0",
            fulfillTx,
            signatures,
            address(ASSETCHAIN_USDT),
            mockBridgeAddress,
            address(0) // Setting recipient to zero
        );
    }

    function test_completeBridge_revertsIfAmountIsZero() public {
        MoonPie moonPie = new MoonPie(
            RELAYER_ADDRESS,
            TREASURY_ADDRESS,
            MoonPie.NETWORKS.ASSET_CHAIN
        );
        IBridgeAssist.FulfillTx memory fulfillTx = IBridgeAssist.FulfillTx({
            amount: 0, // Setting amount to zero
            fromUser: Strings.toHexString(uint160(userAddress)),
            toUser: address(moonPie),
            fromChain: "evm.8453", // base
            nonce: 0
        });
        bytes[] memory signatures = _signTransaction(fulfillTx,mockBridgeAddress);

        vm.startPrank(USDT_WHALE);
        ERC20(ASSETCHAIN_USDT).transfer(mockBridgeAddress, 10 * 1e18);
        vm.stopPrank();

        vm.startPrank(RELAYER_ADDRESS);
        // Use expectRevert with the encoded error including parameters
        vm.expectRevert(MoonPie.InvalidZeroAmount.selector);
        moonPie.completeBridge(
            "0",
            fulfillTx,
            signatures,
            address(ASSETCHAIN_USDT),
            mockBridgeAddress,
            userAddress
        );
    }

    function test_completeBridge_revertsIfSourceChainNotSupported() public {
        MoonPie moonPie = new MoonPie(
            RELAYER_ADDRESS,
            TREASURY_ADDRESS,
            MoonPie.NETWORKS.ASSET_CHAIN
        );
        IBridgeAssist.FulfillTx memory fulfillTx = IBridgeAssist.FulfillTx({
            amount: 1 * 1e18, // Setting amount to a non-zero value
            fromUser: Strings.toHexString(uint160(userAddress)),
            toUser: address(moonPie),
            fromChain: "evm.1234", // Setting fromChain to an unsupported network
            nonce: 0
        });
        bytes[] memory signatures = _signTransaction(fulfillTx,mockBridgeAddress);

        vm.startPrank(USDT_WHALE);
        ERC20(ASSETCHAIN_USDT).transfer(mockBridgeAddress, 10 * 1e18);
        vm.stopPrank();

        vm.startPrank(RELAYER_ADDRESS);
        // Use expectRevert with the encoded error including parameters
        vm.expectRevert(MoonPie.SourceChainNotSupported.selector);
        moonPie.completeBridge(
            "0",
            fulfillTx,
            signatures,
            address(ASSETCHAIN_USDT),
            mockBridgeAddress,
            userAddress
        );
    }

    /// @dev Fulfill a bridge transaction, from Base to Asset Chain mainnet.
    function test_bridgeFulfillmentSuccess() public {
        vm.startPrank(USDT_WHALE);
        ERC20(ASSETCHAIN_USDT).transfer(mockBridgeAddress, 10 * 1e18);
        vm.stopPrank();

        uint256 userRwaBalanceBefore = userAddress.balance;

        MoonPie moonPie = new MoonPie(
            RELAYER_ADDRESS,
            TREASURY_ADDRESS,
            MoonPie.NETWORKS.ASSET_CHAIN
        );
        IBridgeAssist.FulfillTx memory fulfillTx = IBridgeAssist.FulfillTx({
            amount: 1 * 1e18, // 1
            fromUser: Strings.toHexString(uint160(userAddress)),
            toUser: address(moonPie),
            fromChain: "evm.8453", // base
            nonce: 0
        });
        bytes[] memory signatures = _signTransaction(fulfillTx,mockBridgeAddress);

        vm.startPrank(RELAYER_ADDRESS);
        moonPie.completeBridge(
            "0",
            fulfillTx,
            signatures,
            address(ASSETCHAIN_USDT),
            mockBridgeAddress,
            userAddress
        );

        uint256 userRwaBalanceAfter = userAddress.balance;
        assertGt(userRwaBalanceAfter, userRwaBalanceBefore);
    }

    /* 
  amountIn 1.000000000000000000 USDT
  amountOut 19.473365128436706527 RWA
   */
    function test_bridgeTokenToRWA() public {
        vm.startPrank(USDT_WHALE);
        ERC20(ASSETCHAIN_USDT).transfer(mockBridgeAddress, 10 * 1e18);
        vm.stopPrank();

        uint256 userRwaBalanceBefore = userAddress.balance;

        MoonPie moonPie = new MoonPie(
            RELAYER_ADDRESS,
            TREASURY_ADDRESS,
            MoonPie.NETWORKS.ASSET_CHAIN
        );
        IBridgeAssist.FulfillTx memory fulfillTx = IBridgeAssist.FulfillTx({
            amount: 1 * 1e18, // 1
            fromUser: Strings.toHexString(uint160(userAddress)),
            toUser: address(moonPie),
            fromChain: "evm.8453", // base
            nonce: 0
        });
        bytes[] memory signatures = _signTransaction(fulfillTx,mockBridgeAddress);

        vm.startPrank(RELAYER_ADDRESS);
        moonPie.completeBridge(
            "0",
            fulfillTx,
            signatures,
            address(ASSETCHAIN_USDT),
            mockBridgeAddress,
            userAddress
        );

        uint256 userRwaBalanceAfter = userAddress.balance;
        assertGt(userRwaBalanceAfter, userRwaBalanceBefore);
    }


    function test_bridgeRWAToRWA() public {
        vm.deal(mockNativeBridgeAddress, 20 * 1e18);
        uint256 userRwaBalanceBefore = userAddress.balance;
        
        MoonPie moonPie = new MoonPie(
            RELAYER_ADDRESS,
            TREASURY_ADDRESS,
            MoonPie.NETWORKS.ASSET_CHAIN
        );
        IBridgeAssist.FulfillTx memory fulfillTx = IBridgeAssist.FulfillTx({
            amount: 1 * 1e18, // 1
            fromUser: Strings.toHexString(uint160(userAddress)),
            toUser: address(moonPie),
            fromChain: "evm.42161", // arbitrum
            nonce: 0
        });
        bytes[] memory signatures = _signTransaction(fulfillTx,mockNativeBridgeAddress);

        vm.startPrank(RELAYER_ADDRESS);
        moonPie.completeBridge(
            "0",
            fulfillTx,
            signatures,
            address(NATIVE_RWA),
            mockNativeBridgeAddress,
            userAddress
        );

        uint256 userRwaBalanceAfter = userAddress.balance;
        assertGt(userRwaBalanceAfter, userRwaBalanceBefore);
    }
}
