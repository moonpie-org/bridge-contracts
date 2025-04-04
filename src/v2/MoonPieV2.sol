// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import {IBridgeAssist} from "../interfaces/IBridgeAssist.sol";

/// @title MoonPieV2
/// @author Ebube Okorie - @kelviniot
/// @dev MoonPie v2 bridges tokens to token, no swapping to RWA.
contract MoonPieV2 is Ownable, ReentrancyGuard {
    enum NETWORKS {
        ASSET_CHAIN,
        ARBITRUM,
        BASE
    }

    struct NetworkInfo {
        bool isExists;
        string network; // e.g., "evm.3133"
    }

    struct BridgeTransaction {
        string recipient;
        address token;
        address tokenBridge;
        uint256 amountAfterFee;
        uint256 fee;
        string fromChain;
        string toChain;
        uint256 index;
    }
    uint256 public FEE_PERCENTAGE = 100; // 100 bps = 1% = 0.01, 500 bps = 5% = 0.05

    address public RELAYER_ADDRESS;
    address public TREASURY_ADDRESS;
    NETWORKS public CURRENT_CHAIN;

    mapping(NETWORKS => NetworkInfo) public supportedNetwork;
    mapping(bytes32 => BridgeTransaction) public bridgeTransactions;

    // events
    event BridgeInitiated(
        bytes32 indexed requestId,
        string indexed recipient,
        uint256 amount
    );
    event BridgeCompleted(
        bytes32 indexed requestId,
        address indexed recipient,
        uint256 amount
    );
    event FeePercentageUpdated(uint256 newFee);
    event RelayerUpdated(address newRelayer);
    event TreasuryUpdated(address newTreasury);
    event NetworkSupported(NETWORKS network, string networkId);

    // errors
    error InvalidRecipient();
    error InvalidAddress();
    error InvalidZeroAmount();
    error TransferFailed();
    error SourceChainNotSupported();
    error TransferFromFailed();
    error FeeTransferFailed();
    error InvalidRequestId();
    error TransferToUserFailed();
    error SwapFailed();
    error SwapPoolDoesNotExist();
    error OnlyRelayerAllowed();

    constructor(
        address _relayerAddress,
        address _treasuryAddress,
        NETWORKS _currentChain
    ) Ownable(msg.sender) {
        RELAYER_ADDRESS = _relayerAddress;
        TREASURY_ADDRESS = _treasuryAddress;
        CURRENT_CHAIN = _currentChain;
    }

    modifier onlyRelayer() {
        if (msg.sender != RELAYER_ADDRESS) {
            revert OnlyRelayerAllowed();
        }
        _;
    }

    /// @dev This method initiates the bridge transaction on the source chain.
    /// @dev It will only be called on the source chain.
    function bridge(
        address token,
        address tokenBridge,
        uint256 amount,
        string memory recipient
    ) public payable nonReentrant {
        if (amount == 0) {
            revert InvalidZeroAmount();
        }

        uint256 currentUserIndex = IBridgeAssist(tokenBridge)
            .getUserTransactionsAmount(address(this));

        // on other chains we're only bridging erc20 tokens
        // we only deal with native tokens on assetchain
        if (!IERC20(token).transferFrom(msg.sender, address(this), amount)) {
            revert TransferFromFailed();
        }

        uint256 fee = calculateMoonPieFee(amount);
        uint256 amountAfterFee = amount - fee;

        if (!IERC20(token).transfer(TREASURY_ADDRESS, fee)) {
            revert FeeTransferFailed();
        }

        bytes32 requestId = keccak256(
            abi.encodePacked(
                msg.sender,
                token,
                amount,
                NETWORKS.ASSET_CHAIN,
                block.timestamp
            )
        );

        bridgeTransactions[requestId] = BridgeTransaction(
            recipient,
            token,
            tokenBridge,
            amountAfterFee,
            fee,
            supportedNetwork[CURRENT_CHAIN].network,
            supportedNetwork[NETWORKS.ASSET_CHAIN].network,
            currentUserIndex
        );

        IERC20(token).approve(tokenBridge, amountAfterFee);
        IBridgeAssist(tokenBridge).send(
            amountAfterFee,
            recipient,
            supportedNetwork[NETWORKS.ASSET_CHAIN].network
        );

        emit BridgeInitiated(requestId, recipient, amountAfterFee);
    }

    /// @dev This method is called by the relayer to complete the bridge transaction.
    /// @dev It should only be called on the destination chain.
    function completeBridge(
        bytes32 sourceChainTxnId,
        IBridgeAssist.FulfillTx memory fulfillTx,
        bytes[] memory signatures,
        address token,
        address destinationTokenBridge,
        address recipient
) public onlyRelayer nonReentrant {
    // === Checks ===
    if (destinationTokenBridge == address(0)) revert InvalidAddress();
    if (recipient == address(0)) revert InvalidAddress();
    if (fulfillTx.amount == 0) revert InvalidZeroAmount();
    if (token == address(0)) revert InvalidAddress();

    if (
        getNetworkFromChainId(fulfillTx.fromChain) != NETWORKS.BASE &&
        getNetworkFromChainId(fulfillTx.fromChain) != NETWORKS.ARBITRUM
    ) {
        revert SourceChainNotSupported();
    }

    // === Effects ===
    // Update state before external call
    bridgeTransactions[sourceChainTxnId] = BridgeTransaction(
        Strings.toHexString(uint160(recipient)),
        token,
        destinationTokenBridge,
        fulfillTx.amount,
        0,
        fulfillTx.fromChain,
        supportedNetwork[CURRENT_CHAIN].network,
        0
    );

    emit BridgeCompleted(sourceChainTxnId, recipient, fulfillTx.amount);

    // === Interactions ===
    // External call last
    IBridgeAssist(destinationTokenBridge).fulfill(fulfillTx, signatures);
}

    function setFeePercentage(uint256 newFeePercentage) public onlyOwner {
        if (newFeePercentage > 1000) revert("Fee exceeds 10%");
        FEE_PERCENTAGE = newFeePercentage;
        emit FeePercentageUpdated(newFeePercentage);
    }

    function setRelayerAddress(address _relayerAddress) public onlyOwner {
        RELAYER_ADDRESS = _relayerAddress;
        emit RelayerUpdated(_relayerAddress);
    }

    function setTreasuryAddress(address _treasuryAddress) public onlyOwner {
        TREASURY_ADDRESS = _treasuryAddress;
        emit TreasuryUpdated(_treasuryAddress);
    }

    function setSupportedNetwork(
        NETWORKS network,
        string memory networkId
    ) public onlyOwner {
        supportedNetwork[network] = NetworkInfo({
            isExists: true,
            network: networkId
        });
        emit NetworkSupported(network, networkId);
    }

    function calculateMoonPieFee(uint256 amount) public view returns (uint256) {
        return (amount * FEE_PERCENTAGE) / 10000; // 10000 = 100%
    }

    function stringsMatch(
        string memory a,
        string memory b
    ) internal pure returns (bool) {
        return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    }

    function getNetworkFromChainId(
        string memory chainId
    ) public view returns (NETWORKS) {
        if (stringsMatch(chainId, supportedNetwork[NETWORKS.BASE].network)) {
            return NETWORKS.BASE;
        } else if (
            stringsMatch(chainId, supportedNetwork[NETWORKS.ARBITRUM].network)
        ) {
            return NETWORKS.ARBITRUM;
        } else if (
            stringsMatch(
                chainId,
                supportedNetwork[NETWORKS.ASSET_CHAIN].network
            )
        ) {
            return NETWORKS.ASSET_CHAIN;
        } else {
            revert SourceChainNotSupported();
        }
    }

    receive() external payable {}
}
