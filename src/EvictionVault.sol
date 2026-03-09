// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./modules/VaultCore.sol";
import "./modules/MultisigCore.sol";
import "./modules/MerkleClaim.sol";

// inheriting logics from VaultCore, MultiSigCore, MerkleClaim Contract
contract EvictionVault is VaultCore, MultisigCore, MerkleClaim {
    
    constructor(address[] memory _owners, uint256 _threshold) payable {
        require(_owners.length > 0, "no owners");

        require(_threshold > 0 && _threshold <= _owners.length, "invalid threshold");
        
        threshold = _threshold;

        for (uint i = 0; i < _owners.length; i++) {
            address o = _owners[i];

            
            require(o != address(0), "zero address owner");

            // checking to ensure no duplicate user
            require(!isOwner[o], "duplicate owner"); 
            isOwner[o] = true;
            owners.push(o);
        }
        
        if (msg.value > 0) {
            balances[msg.sender] += msg.value;
            totalVaultValue = msg.value;
        }
    }
}