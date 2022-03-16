// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "../node_modules/@openzeppelin/contracts/utils/math/SafeMath.sol";

contract MultiSigWallet {
    using SafeMath for uint256;

    /*
     * Events
     */
    event Deposit(address indexed sender, uint256 value);
    event Submission(uint256 indexed transactionId);
    event Confirmation(address indexed sender, uint256 indexed transactionId);
    event Execution(uint256 indexed transactionId);
    event ExecutionFailure(uint256 indexed transactionId);
    event Revocation(address indexed sender, uint256 indexed transactionId);

    /*
     * Storage
     */
    struct Transaction {
        bool executed;
        address destination;
        uint256 value;
        bytes data;
    }

    // track addresses of owners
    address[] public owners;
    mapping(address => bool) public isOwner;

    // define the requirement for this wallet
    uint256 public percentApproval = SafeMath.div(60, 100);
    uint256 public required = percentApproval * owners.length;

    // track transaction ID and keep a mapping of the same
    uint256 public transactionCount;
    mapping(uint256 => Transaction) public transactions;

    // track transactions ID to which owner addresses have confirmed
    mapping(uint256 => mapping(address => bool)) public confirmations;

    /*
     * Fallback function allows to deposit ether.
     */
    fallback() external payable {
        if (msg.value > 0) {
            emit Deposit(msg.sender, msg.value);
        }
    }

    receive() external payable {
        if (msg.value > 0) {
            emit Deposit(msg.sender, msg.value);
        }
    }

    /*
     * Modifiers
     */
    modifier isOwnerMod(address owner) {
        require(
            isOwner[owner] == true,
            "You are not authorized for this action."
        );
        _;
    }

    modifier isConfirmedMod(uint256 transactionId, address owner) {
        require(
            confirmations[transactionId][owner] == false,
            "You have already confirmed this transaction."
        );
        _;
    }

    modifier isExecutedMod(uint256 transactionId) {
        require(
            transactions[transactionId].executed == false,
            "This transaction has already been executed."
        );
        _;
    }

    modifier notNull(address _address) {
        require(_address != address(0), "Specified destination doesn't exist");
        _;
    }

    /**
     * @dev Contract constructor sets initial owners
     * @param _owners List of initial owners.
     */
    constructor(address[] memory _owners) {
        require(
            _owners.length >= 3,
            "There need to be atleast 3 initial signatories for this wallet"
        );
        for (uint256 i = 0; i < _owners.length; i++) {
            isOwner[_owners[i]] = true;
        }
        owners = _owners;
    }

    /*
     * Public Functions
     */

    /**
     * @dev Allows an owner to submit and confirm a transaction.
     * @param destination Transaction target address.
     * @param value Transaction ether value.
     * @param data Transaction data payload.
     * @return transactionId Transaction ID.
     */

    function submitTransaction(
        address destination,
        uint256 value,
        bytes memory data
    ) public isOwnerMod(msg.sender) returns (uint256 transactionId) {
        transactionId = addTransaction(destination, value, data);
        confirmTransaction(transactionId);
    }

    /**
     * @dev Allows an owner to confirm a transaction.
     * @param transactionId Transaction ID.
     */
    function confirmTransaction(uint256 transactionId)
        public
        isOwnerMod(msg.sender)
        isConfirmedMod(transactionId, msg.sender)
    {
        // confirm transaction is not being sent to a null address
        require(
            transactions[transactionId].destination != address(0),
            "Specified destination doesn't exist"
        );

        // update confirmation
        confirmations[transactionId][msg.sender] = true;
        emit Confirmation(msg.sender, transactionId);

        // on confirmation, execute transaction
        executeTransaction(transactionId);
    }

    /**
     * @dev Allows anyone to execute a confirmed transaction.
     * @param transactionId Transaction ID.
     */
    function executeTransaction(uint256 transactionId)
        public
        isOwnerMod(msg.sender)
        isExecutedMod(transactionId)
        isConfirmedMod(transactionId, msg.sender)
    {
        if (isConfirmed(transactionId)) {
            // extrapolate struct to a variable
            Transaction storage txn = transactions[transactionId];
            // update variable executed state
            txn.executed = true;

            // transfer the value to the destination address
            (bool success, ) = txn.destination.call{value: txn.value}(txn.data);

            if (success) {
                emit Execution(transactionId);
            } else {
                emit ExecutionFailure(transactionId);
                txn.executed = false;
            }
        }
    }

    /**
     * @dev Allows an owner to revoke a confirmation for a transaction.
     * @param transactionId Transaction ID.
     */
    function revokeTransaction(uint256 transactionId)
        external
        isOwnerMod(msg.sender)
        isConfirmedMod(transactionId, msg.sender)
        isExecutedMod(transactionId)
    {
        confirmations[transactionId][msg.sender] = false;
        emit Revocation(msg.sender, transactionId);
    }

    /**
     * Internal Functions
     */

    /**
     * @dev Adds a new transaction to the transaction mapping, if transaction does not exist yet.
     * @param destination Transaction target address.
     * @param value Transaction ether value.
     * @param data Transaction data payload.
     * @return transactionId Transaction ID.
     */
    function addTransaction(
        address destination,
        uint256 value,
        bytes memory data
    ) internal notNull(destination) returns (uint256 transactionId) {
        // assign ID to count
        transactionId = transactionCount;

        // update transactions mapping with the transaction struct
        transactions[transactionId] = Transaction({
            destination: destination,
            value: value,
            data: data,
            executed: false
        });

        // update new count
        transactionCount += 1;

        // emit event
        emit Submission(transactionId);
    }

    /**
     * @dev Returns the confirmation status of a transaction.
     * @param transactionId Transaction ID.
     * @return _isConfirmed Confirmation status.
     */
    function isConfirmed(uint256 transactionId)
        internal
        view
        returns (bool _isConfirmed)
    {
        uint256 count = 0;

        // iterate over the array of owners
        for (uint256 i = 0; i < owners.length; i++) {
            // if owner has confirmed the transaction
            if (confirmations[transactionId][owners[i]]) count += 1;
            // if count reached the required specification then return true, as transaction is confirmed
            if (count == required) return true;
        }
    }
}
