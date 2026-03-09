// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../interfaces/IEvictionVault.sol";

abstract contract EvictionVaultStorage is IEvictionVault {

    // arrayss of owners
    address[] public owners;

    // using mapping to set the owner => true/false
    mapping(address => bool) public isOwner;

    uint256 public threshold;

    mapping(uint256 => mapping(address => bool)) public confirmed;

    mapping(uint256 => Transaction) public transactions;

    uint256 public txCount;

    mapping(address => uint256) public balances;


    bytes32 public merkleRoot;


    mapping(address => bool) public claimed;

    mapping(bytes32 => bool) public usedHashes;

    uint256 public constant TIMELOCK_DURATION = 1 hours;

    uint256 public totalVaultValue;

    bool public paused;

    modifier onlyOwner() {
        require(isOwner[msg.sender], "Not an owner");
        _;
    }

    modifier onlyVault() {
        require(msg.sender == address(this), "Not vault");
        _;
    }

    
    modifier whenNotPaused() {
        require(!paused, "Paused");
        _;
    }
}
