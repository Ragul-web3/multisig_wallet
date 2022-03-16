// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "../node_modules/@openzeppelin/contracts/utils/math/SafeMath.sol";

interface IWallet {
    /*
     * Events
     */
    event Deposit(address indexed sender, uint256 value);
    event Submission(uint256 indexed transactionId);
    event Confirmation(address indexed sender, uint256 indexed transactionId);
    event Execution(uint256 indexed transactionId);
    event ExecutionFailure(uint256 indexed transactionId);
    event Revocation(address indexed sender, uint256 indexed transactionId);

    /**
     * @dev Allows admin to add new owner to the wallet
     * @param owner Address of the new owner
     */
    function addOwner(address owner) external;

    /**
     * @dev Allows admin to remove owner from the wallet
     * @param owner Address of the new owner
     */
    function removeOwner(address owner) external;

    /**
     * @dev Allows admin to transfer owner from one wallet to  another
     * @param _from Address of the old owner
     * @param _to Address of the new owner
     */
    function transferOwner(address _from, address _to) external;
}
