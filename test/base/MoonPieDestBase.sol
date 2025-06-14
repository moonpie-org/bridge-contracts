pragma solidity ^0.8.22;

import {Test} from "forge-std/Test.sol";
import "forge-std/console.sol";
import {UsdcMock} from "../mocks/UsdcMock.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import {IBridgeAssist} from "src/interfaces/IBridgeAssist.sol";
import {BaseScript, stdJson, console2} from "script/base.s.sol";
import {UnsafeUpgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import {BridgeAssistTransferUpgradeable} from "../mocks/BridgeAssistTransferUpgradeable.sol";
import {BridgeAssistNativeUpgradeable} from "../mocks/BridgeAssistNativeUpgradeable.sol";
import {EIP712Upgradeable} from "@openzeppelin/contracts-upgradeable/utils/cryptography/EIP712Upgradeable.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {MoonPieV2} from "src/v2/MoonPieV2.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";

contract MoonPieDestBase is Test, BaseScript {
    using stdJson for string;
    using ECDSA for bytes32;

    bytes32 public constant FULFILL_TX_TYPEHASH =
        keccak256(
            "FulfillTx(uint256 amount,string fromUser,address toUser,string fromChain,uint256 nonce)"
        );
    // UsdcMock public usdc;
    string deployConfigJson;
    address usdtTokenAddress;
    address usdtBridgeAddress;
    address public WRWA_ADDRESS;
    address public SWAP_ROUTER_ADDRESS;
    address public NATIVE_RWA;
    uint256 ownerPrivateKey = vm.envUint("OWNER_PRV_KEY");
    address RELAYER_ADDRESS = vm.envAddress("RELAYER_ADDRESS");
    address TREASURY_ADDRESS = vm.envAddress("TREASURY_ADDRESS");
    string ASSETCHAIN_RPC_URL = vm.envString("ASSETCHAIN_RPC_URL");
    address usdcBridgeAddress;
    address userAddress = vm.addr(1);
    address mockBridgeAddress;
    address payable mockNativeBridgeAddress;
    uint256 assetChainFork;
    address RWA_BRIDGE_ADDRESS; // assetchain
    address constant ASSETCHAIN_USDT =
        0x26E490d30e73c36800788DC6d6315946C4BbEa24;
    address constant USDT_WHALE = 0xfb1B5ABC46aB3A191c800056514098D9e720F5A8; // assetchain
    address constant RWA_WHALE = 0x5195aD65E40C79E11661486B39978ff268f3B342; // assetchain

    // Proxy-related state
    MoonPieV2 public moonPie; // Proxy instance
    address public proxyAdmin;

    function setUp() public {
        assetChainFork = vm.createFork(ASSETCHAIN_RPC_URL);
        deployConfigJson = getDeployConfigJson();
        usdtTokenAddress = deployConfigJson.readAddress(".usdt.tokenAddress");
        usdtBridgeAddress = deployConfigJson.readAddress(".usdt.bridgeAddress");
        RWA_BRIDGE_ADDRESS = deployConfigJson.readAddress(".rwa.bridgeAddress");
        WRWA_ADDRESS = deployConfigJson.readAddress(".wrwaAddress");
        SWAP_ROUTER_ADDRESS = deployConfigJson.readAddress(
            ".swapRouterAddress"
        );
        NATIVE_RWA = deployConfigJson.readAddress(".nativeRwaTokenAddress");

        // Deploy MoonPieV2 as a proxy
        vm.startPrank(msg.sender);
        MoonPieV2 moonPieImpl = new MoonPieV2();
        ProxyAdmin admin = new ProxyAdmin(msg.sender);
        bytes memory initData = abi.encodeWithSelector(
            MoonPieV2.initialize.selector,
            RELAYER_ADDRESS,
            TREASURY_ADDRESS,
            MoonPieV2.NETWORKS.ASSET_CHAIN
        );
        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(
            address(moonPieImpl),
            address(admin),
            initData
        );
        moonPie = MoonPieV2(payable(address(proxy))); // Cast proxy to MoonPieV2
        proxyAdmin = address(admin);
        addSupportedNetworks(moonPie);

        deployBridgeAssistMock();
        deployNativeBridge();
    }

    function deployBridgeAssistMock() internal {
        BridgeAssistTransferUpgradeable implementation = new BridgeAssistTransferUpgradeable();
        address[] memory relayers = new address[](1);
        relayers[0] = RELAYER_ADDRESS;
        address bridgeAssistProxy = UnsafeUpgrades.deployTransparentProxy(
            address(implementation),
            address(this),
            abi.encodeCall(
                BridgeAssistTransferUpgradeable.initialize,
                (
                    ASSETCHAIN_USDT,
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
        string[] memory chains = new string[](3);
        chains[0] = "evm.42420";
        chains[1] = "evm.42161";
        chains[2] = "evm.8453";

        uint256[] memory exchangeRatesFromPow = new uint256[](3);
        exchangeRatesFromPow[0] = 0;
        exchangeRatesFromPow[1] = 0;
        exchangeRatesFromPow[2] = 0;
        BridgeAssistTransferUpgradeable(mockBridgeAddress).addChains(
            chains,
            exchangeRatesFromPow
        );
        vm.stopPrank();
    }

    function deployNativeBridge() internal {
        BridgeAssistNativeUpgradeable implementation = new BridgeAssistNativeUpgradeable();
        address[] memory relayers = new address[](1);
        relayers[0] = RELAYER_ADDRESS;
        address nativeBridgeProxy = UnsafeUpgrades.deployTransparentProxy(
            address(implementation),
            address(this),
            abi.encodeCall(
                BridgeAssistNativeUpgradeable.initialize,
                (
                    NATIVE_RWA,
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
        mockNativeBridgeAddress = payable(nativeBridgeProxy);

        // Sets all subsequent calls' `msg.sender` to be the input address until `stopPrank` is called.
        vm.startPrank(address(this));
        // assign manager role
        BridgeAssistNativeUpgradeable(mockNativeBridgeAddress).grantRole(
            BridgeAssistNativeUpgradeable(mockNativeBridgeAddress)
                .MANAGER_ROLE(),
            address(this)
        );

        // add chain
        string[] memory chains = new string[](3);
        chains[0] = "evm.42420";
        chains[1] = "evm.42161";
        chains[2] = "evm.8453";

        uint256[] memory exchangeRatesFromPow = new uint256[](3);
        exchangeRatesFromPow[0] = 0;
        exchangeRatesFromPow[1] = 0;
        exchangeRatesFromPow[2] = 0;
        BridgeAssistNativeUpgradeable(mockNativeBridgeAddress).addChains(
            chains,
            exchangeRatesFromPow
        );
        vm.stopPrank();
    }

    function addSupportedNetworks(MoonPieV2 _moonPie) public {
        _moonPie.setSupportedNetwork(
            MoonPieV2.NETWORKS.ASSET_CHAIN,
            "evm.42420"
        );
        _moonPie.setSupportedNetwork(MoonPieV2.NETWORKS.BASE, "evm.8453");
        _moonPie.setSupportedNetwork(MoonPieV2.NETWORKS.ARBITRUM, "evm.42161");
    }

    function _signTransaction(
        IBridgeAssist.FulfillTx memory fulfillTx,
        address bridgeAssistAddress
    ) internal view returns (bytes[] memory) {
        bytes32 DOMAIN_TYPEHASH = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );

        bytes32 domainSeparator = keccak256(
            abi.encode(
                DOMAIN_TYPEHASH,
                keccak256(bytes("BridgeAssist")),
                keccak256(bytes("1.0")),
                block.chainid,
                bridgeAssistAddress
            )
        );

        // Exactly matching the TypeScript fields order
        bytes32 structHash = keccak256(
            abi.encode(
                keccak256(
                    "FulfillTx(uint256 amount,string fromUser,address toUser,string fromChain,uint256 nonce)"
                ),
                fulfillTx.amount,
                keccak256(bytes(fulfillTx.fromUser)),
                fulfillTx.toUser,
                keccak256(bytes(fulfillTx.fromChain)),
                fulfillTx.nonce
            )
        );

        // Get the final hash (same as _hashTypedDataV4)
        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", domainSeparator, structHash)
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPrivateKey, digest);
        bytes memory signature = abi.encodePacked(r, s, v);
        bytes[] memory signatures = new bytes[](1);
        signatures[0] = signature;

        return signatures;
    }
}
