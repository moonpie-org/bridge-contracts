// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IBridgeAssist} from "./interfaces/IBridgeAssist.sol";
import "./interfaces/IWRWA.sol";
import "forge-std/console.sol";
import "./utils/UniswapPoolChecker.sol";

contract MoonPie is Ownable, ReentrancyGuard, UniswapPoolChecker {
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
        NETWORKS fromChain;
        NETWORKS toChain;
    }
    IWRWA public WRWA;
    ISwapRouter public SWAP_ROUTER;
    address public NATIVE_RWA_TOKEN;
    uint256 public FEE_PERCENTAGE = 1; // 1% moonpie fee

    address public RELAYER_ADDRESS;
    address public TREASURY_ADDRESS;
    NETWORKS public CURRENT_CHAIN;

    mapping(NETWORKS => NetworkInfo) public supportedNetwork;
    mapping(bytes32 => BridgeTransaction) public bridgeTransactions;

    // events
    event BridgeInitiated(bytes32 indexed requestId, uint256 amount);
    event BridgeCompleted(
        bytes32 indexed requestId,
        address indexed user,
        address indexed token,
        uint256 amount
    );

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
        address _wrwa,
        address _swapRouter,
        address _nativeRwaToken,
        NETWORKS _currentChain
    ) Ownable(msg.sender) {
        WRWA = IWRWA(_wrwa);
        SWAP_ROUTER = ISwapRouter(_swapRouter);
        NATIVE_RWA_TOKEN = _nativeRwaToken;
        RELAYER_ADDRESS = _relayerAddress;
        TREASURY_ADDRESS = _treasuryAddress;
        CURRENT_CHAIN = _currentChain;

        setSupportedNetwork(NETWORKS.ASSET_CHAIN, "evm.42420");
        setSupportedNetwork(NETWORKS.BASE, "evm.8453");
        setSupportedNetwork(NETWORKS.ARBITRUM, "evm.42161");
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
            CURRENT_CHAIN,
            NETWORKS.ASSET_CHAIN
        );

        IERC20(token).approve(tokenBridge, amountAfterFee);
        IBridgeAssist(tokenBridge).send(
            amountAfterFee,
            recipient,
            supportedNetwork[NETWORKS.ASSET_CHAIN].network
        );

        emit BridgeInitiated(requestId, amountAfterFee);
    }

    /// @dev This method is called by the relayer to complete the bridge transaction.
    /// @dev It should only be called on the destination chain.
    /// @param sourceChainTxnId The transaction ID on the source chain.
    /// @param fulfillTx The FulfillTx struct containing transaction details.
    /// @param signatures The signatures to verify the transaction.
    /// @param token The address of the token being bridged.
    /// @param destinationTokenBridge The address of the token bridge on the destination chain.
    /// @param recipient The address of the recipient on the destination chain.
    function completeBridge(
        bytes32 sourceChainTxnId,
        IBridgeAssist.FulfillTx memory fulfillTx,
        bytes[] memory signatures,
        address token,
        address destinationTokenBridge,
        address recipient
    ) public onlyRelayer nonReentrant {
        if (
            keccak256(abi.encodePacked(fulfillTx.fromUser)) ==
            keccak256(abi.encodePacked(address(0))) ||
            keccak256(abi.encodePacked(fulfillTx.toUser)) ==
            keccak256(abi.encodePacked(address(0)))
        ) {
            revert InvalidAddress();
        }

        if (
            !stringsMatch(
                fulfillTx.fromChain,
                supportedNetwork[NETWORKS.BASE].network
            ) &&
            !stringsMatch(
                fulfillTx.fromChain,
                supportedNetwork[NETWORKS.ARBITRUM].network
            )
        ) {
            revert SourceChainNotSupported();
        }

        if (fulfillTx.amount == 0) {
            revert InvalidZeroAmount();
        }

        IBridgeAssist(destinationTokenBridge).fulfill(fulfillTx, signatures);

        if (token == NATIVE_RWA_TOKEN) {
            payable(fulfillTx.toUser).transfer(fulfillTx.amount);
        } else {
            uint256 rwaAmount = swapAssetForRWA(
                token,
                fulfillTx.amount,
                recipient
            );

            emit BridgeCompleted(
                sourceChainTxnId,
                recipient,
                NATIVE_RWA_TOKEN,
                rwaAmount
            );
        }
    }

    function swapAssetForRWA(
        address token,
        uint256 amount,
        address _recipient
    ) internal returns (uint256) {
        IERC20(token).approve(address(SWAP_ROUTER), amount);

        (bool exists, ) = checkPool(token, address(WRWA), 3000);
        if (!exists) {
            revert SwapPoolDoesNotExist();
        }

        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: token,
                tokenOut: address(WRWA),
                fee: 3000, // 0.3%
                recipient: address(this),
                deadline: block.timestamp + 300, // 5 min
                amountIn: amount,
                amountOutMinimum: 0, // use an oracle to choose a safer value
                sqrtPriceLimitX96: 0 // 0 to ensures we swap our exact input amount.
            });

        try SWAP_ROUTER.exactInputSingle(params) returns (uint256 amountOut) {
            WRWA.withdraw(amountOut);

            (bool success, ) = _recipient.call{value: amountOut}("");
            if (!success) {
                revert TransferFailed();
            }

            return amountOut;
        } catch {
            revert SwapFailed();
        }
    }

    // Allow setting the fee percentage
    function setFeePercentage(uint256 newFeePercentage) public onlyOwner {
        FEE_PERCENTAGE = newFeePercentage;
    }

    function setRelayerAddress(address _relayerAddress) public onlyOwner {
        RELAYER_ADDRESS = _relayerAddress;
    }

    function setTreasuryAddress(address _treasuryAddress) public onlyOwner {
        TREASURY_ADDRESS = _treasuryAddress;
    }

    function calculateMoonPieFee(uint256 amount) public view returns (uint256) {
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

    function stringsMatch(
        string memory a,
        string memory b
    ) internal pure returns (bool) {
        return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    }

    receive() external payable {}
}
