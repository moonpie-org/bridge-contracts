// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IBridgeAssist} from "./interfaces/IBridgeAssist.sol";
import "forge-std/console.sol";

contract MoonPie is Ownable, ReentrancyGuard {
    enum NETWORKS {
        ASSET_CHAIN,
        ARBITRUM,
        BASE
    }

    struct NetworkInfo {
        bool isExists;
        string network; // e.g., "evm.3133"
    }

    struct BridgeRequest {
        address user;
        address tokenAddress;
        uint256 amount;
        NETWORKS destinationChain;
    }

    IBridgeAssist public BRIDGE_ASSIST;
    uint256 public FEE_PERCENTAGE = 1; // 1% fee, adjust as needed (e.g., 100 for 1%)

    string public RELAYER_ADDRESS;
    address public TREASURY_ADDRESS;

    mapping(NETWORKS => NetworkInfo) public supportedNetwork;
    mapping(bytes32 => BridgeRequest) public bridgeRequests; // Store bridge requests

    // events
    event BridgeInitiated(
        bytes32 indexed requestId,
        address indexed user,
        address indexed tokenAddress,
        uint256 amount,
        NETWORKS destinationChain
    );
    event BridgeCompleted(
        bytes32 indexed requestId,
        address indexed user,
        address indexed tokenAddress,
        uint256 amount,
        NETWORKS destinationChain
    );

    // errors
    error InvalidRecipient();
    error InvalidZeroAmount();
    error TransferFailed();
    error DestinationChainNotSupported();
    error TransferFromFailed();
    error FeeTransferFailed();
    error InvalidRequestId();
    error TransferToUserFailed();

    constructor(
        string memory _relayerAddress,
        address _treasuryAddress
    ) Ownable(msg.sender) {
        RELAYER_ADDRESS = _relayerAddress;
        TREASURY_ADDRESS = _treasuryAddress;

        setSupportedNetwork(NETWORKS.ASSET_CHAIN, "evm.42420");
        setSupportedNetwork(NETWORKS.BASE, "evm.8453");
        setSupportedNetwork(NETWORKS.ARBITRUM, "evm.42161");
    }

    // modifier onlyRelayer() {
    //     require(
    //         msg.sender == RELAYER_ADDRESS,
    //         "Only relayer can call this function"
    //     );
    //     _;
    // }

    function bridge(
        address tokenAddress,
        address tokenBridgeAddress,
        uint256 amount
    ) public payable nonReentrant {
        if (amount == 0) {
            revert InvalidZeroAmount();
        }
        IERC20 token = IERC20(tokenAddress);
        if (!token.transferFrom(msg.sender, address(this), amount)) {
            revert TransferFromFailed();
        }

        uint256 fee = calculateFee(amount);
        uint256 amountToBridge = amount - fee;

        // Generate a unique request ID
        bytes32 requestId = keccak256(
            abi.encodePacked(
                msg.sender,
                tokenAddress,
                amount,
                NETWORKS.ASSET_CHAIN,
                block.timestamp
            )
        );

        bridgeRequests[requestId] = BridgeRequest(
            msg.sender,
            tokenAddress,
            amountToBridge,
            NETWORKS.ASSET_CHAIN
        );
]
        token.approve(tokenBridgeAddress, amountToBridge);

        // Call bridge contract's send function
        IBridgeAssist(tokenBridgeAddress).send(
            token.allowance(address(this), tokenBridgeAddress),
            RELAYER_ADDRESS,
            supportedNetwork[NETWORKS.ASSET_CHAIN].network
        );

        // Transfer fee to treasury
        if (!token.transfer(TREASURY_ADDRESS, fee)) {
            revert FeeTransferFailed();
        }

        emit BridgeInitiated(
            requestId,
            msg.sender,
            tokenAddress,
            amountToBridge,
            NETWORKS.ASSET_CHAIN
        );
    }

    // // Function to be called by the relayer on the destination chain
    // function completeBridge(
    //     bytes32 requestId,
    //     uint256 amount
    // ) public onlyRelayer nonReentrant {
    //     BridgeRequest storage request = bridgeRequests[requestId];
    //     if (request.user == address(0)) {
    //         revert InvalidRequestId();
    //     }

    //     IERC20 token = IERC20(request.tokenAddress);
    //     if (!token.transfer(request.user, amount)) {
    //         revert TransferToUserFailed();
    //     }

    //     emit BridgeCompleted(
    //         requestId,
    //         request.user,
    //         request.tokenAddress,
    //         amount,
    //         request.destinationChain
    //     );
    //     delete bridgeRequests[requestId]; // Clean up the request after completion
    // }

    // Allow setting the fee percentage
    function setFeePercentage(uint256 newFeePercentage) public onlyOwner {
        FEE_PERCENTAGE = newFeePercentage;
    }

    function setRelayerAddress(string memory _relayerAddress) public onlyOwner {
        RELAYER_ADDRESS = _relayerAddress;
    }

    function setTreasuryAddress(address _treasuryAddress) public onlyOwner {
        TREASURY_ADDRESS = _treasuryAddress;
    }

    function calculateFee(uint256 amount) internal view returns (uint256) {
        return (amount * FEE_PERCENTAGE) / 100;
    }

    function setSupportedNetwork(
        NETWORKS network,
        string memory networkId
    ) internal {
        supportedNetwork[network] = NetworkInfo({
            isExists: true,
            network: networkId
        });
    }
}
