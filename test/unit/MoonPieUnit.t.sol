// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Test} from "forge-std/Test.sol";
import "forge-std/console.sol";
import {MoonPie} from "src/MoonPie.sol";
import {UsdcMock} from "../mocks/UsdcMock.sol";
import {BaseScript, stdJson, console2} from "script/base.s.sol";
import {UnsafeUpgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import {BridgeAssistTransferUpgradeable} from "../mocks/BridgeAssistTransferUpgradeable.sol";

contract MoonPieUnit_Fork is Test, BaseScript {
    using stdJson for string;

    UsdcMock public usdc;
    uint256 ownerPrivateKey;

    string RELAYER_ADDRESS_as_string;
    address RELAYER_ADDRESS;
    address TREASURY_ADDRESS;

    string deployConfigJson;

    // address usdcTokenAddress;
    address usdcBridgeAddress;

    address wethTokenAddress;
    address wethBridgeAddress;

    address userAddress;

    address mockTokenAddress;
    address mockBridgeAddress;

    function setUp() public {
        ownerPrivateKey = vm.envUint("OWNER_PRV_KEY");
        RELAYER_ADDRESS_as_string = vm.envString("RELAYER_ADDRESS");
        RELAYER_ADDRESS = vm.envAddress("RELAYER_ADDRESS");
        TREASURY_ADDRESS = vm.envAddress("TREASURY_ADDRESS");
        deployConfigJson = getDeployConfigJson();

        // usdcTokenAddress = deployConfigJson.readAddress(".usdc.tokenAddress");
        // usdcBridgeAddress = deployConfigJson.readAddress(".usdc.bridgeAddress");

        wethTokenAddress = deployConfigJson.readAddress(".weth.tokenAddress");
        wethBridgeAddress = deployConfigJson.readAddress(".weth.bridgeAddress");

        userAddress = address(this);

        // deplok mock usdc
        usdc = new UsdcMock();
        mockTokenAddress = address(usdc);
        usdc.mint(userAddress, 1_000_000 * 1e6);

        // Deploy bridge assist implementation first
        BridgeAssistTransferUpgradeable implementation = new BridgeAssistTransferUpgradeable();

        // Then deploy the transparent proxy
        address[] memory relayers = new address[](1);
        relayers[0] = RELAYER_ADDRESS;

        address bridgeAssistProxy = UnsafeUpgrades.deployTransparentProxy(
            address(implementation),
            address(this),
            abi.encodeCall(
                BridgeAssistTransferUpgradeable.initialize,
                (
                    mockTokenAddress,
                    1000 * 1e6,
                    TREASURY_ADDRESS,
                    0,
                    0,
                    address(this),
                    relayers,
                    1
                )
            )
        );
        mockBridgeAddress = bridgeAssistProxy;

        // Sets all subsequent calls' `msg.sender` to be the input address until `stopPrank` is called.
        vm.startPrank(address(this));

        // assign manager role
        BridgeAssistTransferUpgradeable(mockBridgeAddress).grantRole(
            BridgeAssistTransferUpgradeable(mockBridgeAddress).MANAGER_ROLE(),
            address(this)
        );

        // add chain
        string[] memory chains = new string[](1);
        chains[0] = "evm.42420";

        uint256[] memory exchangeRatesFromPow = new uint256[](1);
        exchangeRatesFromPow[0] = 1;
        BridgeAssistTransferUpgradeable(mockBridgeAddress).addChains(
            chains,
            exchangeRatesFromPow
        );
        vm.stopPrank();
    }

    function test_initialize() public {
        MoonPie moonPie = new MoonPie(
            RELAYER_ADDRESS_as_string,
            TREASURY_ADDRESS
        );
        assertEq(moonPie.RELAYER_ADDRESS(), RELAYER_ADDRESS_as_string);
    }

/*     function test_bridgeFailsWithoutApproval() public {
        MoonPie moonPie = new MoonPie(
            RELAYER_ADDRESS_as_string,
            TREASURY_ADDRESS
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
            RELAYER_ADDRESS_as_string,
            TREASURY_ADDRESS
        );
        // User inputs zero amount
        vm.expectRevert(MoonPie.InvalidZeroAmount.selector);
        moonPie.bridge(mockTokenAddress, mockBridgeAddress, 0);
    }

    function test_bridgeSuccessfullOnSourceChain() public {
        MoonPie moonPie = new MoonPie(
            RELAYER_ADDRESS_as_string,
            TREASURY_ADDRESS
        );
        uint256 beforeBalance = usdc.balanceOf(mockBridgeAddress);
        uint256 treasuryBalanceBefore = usdc.balanceOf(TREASURY_ADDRESS);

        usdc.approve(address(moonPie), usdc.balanceOf(userAddress));
        moonPie.bridge(mockTokenAddress, mockBridgeAddress, 10 * 1e6); // 20

        // ensure bridge received funds
        uint256 afterBalance = usdc.balanceOf(mockBridgeAddress);
        assertEq(afterBalance - beforeBalance, 99 * 1e5);

        // ensure moonpie treasury got expected fee
        uint256 treasuryBalanceAfter = usdc.balanceOf(TREASURY_ADDRESS);
        assertEq(treasuryBalanceAfter - treasuryBalanceBefore, 0.1 * 1e6); // 0.1

    assertEq(vm.load(address(moonPie).code), bytes("BridgeInitiated"));
    }
}
