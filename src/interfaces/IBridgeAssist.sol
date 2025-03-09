// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title IBridgeAssist
 * @author kelviniot
 * @notice Part of the BridgeAssist contract interface
 */
interface IBridgeAssist {
    // Structure to represent a transaction to be fulfilled
    struct FulfillTx {
        uint256 amount; // Amount of tokens to be transferred
        string fromUser; // The user initiating the transaction, can be a solana address
        address toUser; // The Ethereum address of the recipient
        string fromChain; // The blockchain network where the transaction originated
        uint256 nonce; // A unique identifier for the transaction
    }

    /**
     * @dev Initializes the contract with various parameters
     * @param token_ The address of the token being bridged
     * @param limitPerSend_ The maximum amount that can be sent in a single transaction
     * @param feeWallet_ The wallet address that receives fees
     * @param feeSend_ The fee for sending tokens
     * @param feeFulfill_ The fee for fulfilling a transaction
     * @param owner The owner of the contract
     * @param relayers_ An array of relayer addresses
     * @param relayerConsensusThreshold_ The minimum number of relayers required for consensus
     */
    function initialize(
        address token_,
        uint256 limitPerSend_,
        address feeWallet_,
        uint256 feeSend_,
        uint256 feeFulfill_,
        address owner,
        address[] memory relayers_,
        uint256 relayerConsensusThreshold_
    ) external;

    /**
     * @dev Returns the address of the token being bridged
     * @return The address of the token
     */
    function TOKEN() external view returns (address);

    /**
     * @dev Initiates a token transfer across chains
     * @param amount The amount of tokens to be sent
     * @param toUser The recipient's address
     * @param toChain The blockchain network where the tokens are being sent
     */
    function send(
        uint256 amount,
        string memory toUser,
        string calldata toChain
    ) external payable;

    /**
     * @dev Fulfills a transaction based on the provided transaction details and signatures
     * @param transaction The transaction details
     * @param signatures The signatures from relayers to validate the transaction
     */
    function fulfill(
        FulfillTx calldata transaction,
        bytes[] calldata signatures
    ) external;

    /**
     * @dev Returns the maximum amount that can be sent in a single transaction
     * @return The maximum amount that can be sent
     */
    function limitPerSend() external view returns (uint256);


    /// @dev returns the amount of bridge transactions sent by `user`
    ///   from the current chain
    /// @param user user
    /// @return amount of transactions
    function getUserTransactionsAmount(address user) external view returns (uint256);
}
