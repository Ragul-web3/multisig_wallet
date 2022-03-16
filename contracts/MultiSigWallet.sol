// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "../node_modules/@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./IWallet.sol";

contract MultiSigWallet is IWallet {
    using SafeMath for uint256;

    /*
     * Events
     */
    // event Deposit(address indexed sender, uint256 value);
    // event Submission(uint256 indexed transactionId);
    // event Confirmation(address indexed sender, uint256 indexed transactionId);
    // event Execution(uint256 indexed transactionId);
    // event ExecutionFailure(uint256 indexed transactionId);
    // event Revocation(address indexed sender, uint256 indexed transactionId);
    event OwnerAddition(address indexed owner);
    event OwnerRemoval(address indexed owner);
    event QuorumUpdate(uint256 quorum);

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
    uint256 quorum;

    // track transaction ID and keep a mapping of the same
    uint256 public transactionCount;
    mapping(uint256 => Transaction) public transactions;
    Transaction[] public _validTransactions;

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

    modifier ownerExistsMod(address owner) {
        require(isOwner[owner] == true, "This owner doesn't exist");
        _;
    }

    modifier notOwnerExistsMod(address owner) {
        require(isOwner[owner] == false, "This owner already exists");
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
        uint256 num = SafeMath.mul(owners.length, 60);
        quorum = SafeMath.div(num, 100);
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
        notNull(transactions[transactionId].destination)
    {
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
    {
        if (isConfirmed(transactionId)) {
            // extrapolate struct to a variable
            Transaction storage txn = transactions[transactionId];
            // update variable executed state
            txn.executed = true;

            // transfer the value to the destination address, and get boolean of success/fail
            (bool success, ) = txn.destination.call{value: txn.value}(txn.data);

            if (success) {
                _validTransactions.push(txn);
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
        notNull(transactions[transactionId].destination)
    {
        confirmations[transactionId][msg.sender] = false;
        emit Revocation(msg.sender, transactionId);
    }

    /**
     * @dev Allows admin to add new owner to the wallet
     * @param owner Address of the new owner
     */
    function addOwner(address owner)
        public
        isOwnerMod(msg.sender)
        notNull(owner)
        notOwnerExistsMod(owner)
    {
        // add owner
        isOwner[owner] = true;
        owners.push(owner);

        // emit event
        emit OwnerAddition(owner);

        // update quorum
        updateQuorum(owners);
    }

    /**
     * @dev Allows admin to remove owner from the wallet
     * @param owner Address of the new owner
     */
    function removeOwner(address owner)
        public
        isOwnerMod(msg.sender)
        notNull(owner)
        ownerExistsMod(owner)
    {
        // remove owner
        isOwner[owner] = false;

        // iterate over owners and remove the current owner
        for (uint256 i = 0; i < owners.length - 1; i++)
            if (owners[i] == owner) {
                owners[i] = owners[owners.length - 1];
                break;
            }
        owners.pop();

        // update quorum
        updateQuorum(owners);
    }

    /**
     * @dev Allows admin to transfer owner from one wallet to  another
     * @param _from Address of the old owner
     * @param _to Address of the new owner
     */
    function transferOwner(address _from, address _to)
        public
        isOwnerMod(msg.sender)
        notNull(_from)
        notNull(_to)
        ownerExistsMod(_from)
        notOwnerExistsMod(_to)
    {
        // iterate over owners
        for (uint256 i = 0; i < owners.length; i++)
            // if the curernt owner
            if (owners[i] == _from) {
                // replace with new owner address
                owners[i] = _to;
                break;
            }

        // reset owner addresses
        isOwner[_from] = false;
        isOwner[_to] = true;

        // emit events
        emit OwnerRemoval(_from);
        emit OwnerAddition(_to);
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
            // if count reached the quorum specification then return true
            if (count >= quorum) return true;
        }
    }

    /**
     * @dev Updates the new quorum value
     * @param _owners List of address of the owners
     */
    function updateQuorum(address[] memory _owners) internal {
        uint256 num = SafeMath.mul(_owners.length, 60);
        quorum = SafeMath.div(num, 100);

        emit QuorumUpdate(quorum);
    }

    /**
     * Blockchain get functions
     */
    function getOwners() external view returns (address[] memory) {
        return owners;
    }

    function getValidTransactions()
        external
        view
        returns (Transaction[] memory)
    {
        return _validTransactions;
    }

    function getQuorum() external view returns (uint256) {
        return quorum;
    }
}
