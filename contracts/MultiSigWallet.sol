// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "../node_modules/@openzeppelin/contracts/utils/math/SafeMath.sol";

contract MultiSigWallet {
    using SafeMath for uint256;

    /*
     * Events
     */
    event Deposit(address indexed sender, uint256 value);

    /*
     * Storage
     */
    struct Transaction {
        bool executed;
        address destination;
        uint256 value;
        bytes data;
    }

    address[] public owners;
    uint256 public percentApproval = SafeMath.div(60, 100);
    uint256 public required = percentApproval * owners.length;
    mapping(address => bool) public isOwner;

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
}
