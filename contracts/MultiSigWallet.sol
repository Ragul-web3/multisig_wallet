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
    modifier isOwnerMod() {
        require(isOwner[msg.sender], "This function requires owner access");
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
    ) public isOwnerMod returns (uint256 transactionId) {
        transactionId = addTransaction(destination, value, data);
        confirmTransaction(transactionId);
    }

    /**
     * @dev Allows an owner to confirm a transaction.
     * @param transactionId Transaction ID.
     */
    function confirmTransaction(uint256 transactionId) public isOwnerMod {
        // confirm transaction is not being sent to a null address
        require(
            transactions[transactionId].destination != address(0),
            "Specified transaction doesn't exist"
        );
        require(
            confirmations[transactionId][msg.sender] == false,
            "You have already confirmed this transaction"
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
    function executeTransaction(uint256 transactionId) public {
        require(
            transactions[transactionId].executed == false,
            "This transaction has already been executed"
        );

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
    ) internal returns (uint256 transactionId) {
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
