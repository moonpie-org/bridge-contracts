// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Test} from "forge-std/Test.sol";
import "forge-std/console.sol";
import {MoonPie} from "src/MoonPie.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import {IBridgeAssist} from "src/interfaces/IBridgeAssist.sol";
import {BaseScript, stdJson, console2} from "script/base.s.sol";
import {UnsafeUpgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import {BridgeAssistTransferUpgradeable} from "../mocks/BridgeAssistTransferUpgradeable.sol";
import {EIP712Upgradeable} from "@openzeppelin/contracts-upgradeable/utils/cryptography/EIP712Upgradeable.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "forge-std/console2.sol";
import "../base/MoonPieDestBase.sol";

contract MoonPieDest is MoonPieDestBase {
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

    function test_bridgeFulfillmentFailsIfNotRelayer() public {
        MoonPie moonPie = new MoonPie(
            RELAYER_ADDRESS,
            TREASURY_ADDRESS,
            WRWA_ADDRESS,
            SWAP_ROUTER_ADDRESS,
            NATIVE_RWA_TOKEN_ADDRESS,
            MoonPie.NETWORKS.ASSET_CHAIN
        );
        IBridgeAssist.FulfillTx memory fulfillTx = IBridgeAssist.FulfillTx({
            amount: 1 * 1e18,
            fromUser: Strings.toHexString(uint160(userAddress)),
            toUser: address(moonPie),
            fromChain: "evm.8453", // base
            nonce: 0
        });
        bytes[] memory signatures = _signTransaction(fulfillTx);

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

    /* function test_invalidTokenAddressReverts() public {
        MoonPie moonPie = new MoonPie(
            RELAYER_ADDRESS,
            TREASURY_ADDRESS,
            WRWA_ADDRESS,
            SWAP_ROUTER_ADDRESS,
            NATIVE_RWA_TOKEN_ADDRESS,
            MoonPie.NETWORKS.ASSET_CHAIN
        );
        IBridgeAssist.FulfillTx memory fulfillTx = IBridgeAssist.FulfillTx({
            amount: 1 * 1e18,
            fromUser: Strings.toHexString(uint160(address(0))),
            toUser: address(moonPie),
            fromChain: "evm.8453", // base
            nonce: 0
        });
        bytes[] memory signatures = _signTransaction(fulfillTx);

        vm.startPrank(USDT_WHALE);
        ERC20(ASSETCHAIN_USDT).transfer(mockBridgeAddress, 10 * 1e18);
        vm.stopPrank();

        vm.startPrank(RELAYER_ADDRESS);
        vm.expectRevert(MoonPie.InvalidAddress.selector);
        moonPie.completeBridge(
            "0",
            fulfillTx,
            signatures,
            address(ASSETCHAIN_USDT),
            mockBridgeAddress,
            userAddress
        );
        vm.stopPrank();
    } */

    /// @dev Fulfill a bridge transaction, from Base to Asset Chain mainnet.
    function test_bridgeFulfillmentSuccess() public {
        vm.startPrank(USDT_WHALE);
        ERC20(ASSETCHAIN_USDT).transfer(mockBridgeAddress, 10 * 1e18);
        vm.stopPrank();

        uint256 userRwaBalanceBefore = userAddress.balance;

        MoonPie moonPie = new MoonPie(
            RELAYER_ADDRESS,
            TREASURY_ADDRESS,
            WRWA_ADDRESS,
            SWAP_ROUTER_ADDRESS,
            NATIVE_RWA_TOKEN_ADDRESS,
            MoonPie.NETWORKS.ASSET_CHAIN
        );
        IBridgeAssist.FulfillTx memory fulfillTx = IBridgeAssist.FulfillTx({
            amount: 1 * 1e18,
            fromUser: Strings.toHexString(uint160(userAddress)),
            toUser: address(moonPie),
            fromChain: "evm.8453", // base
            nonce: 0
        });
        bytes[] memory signatures = _signTransaction(fulfillTx);

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
}
