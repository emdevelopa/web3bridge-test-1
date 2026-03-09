// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./EVStorage.sol";

abstract contract VaultCore is EvictionVaultStorage {
    
    receive() external payable {
        // replaced tx.origin to msg.sender over here
        balances[msg.sender] += msg.value;
        totalVaultValue += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    function deposit() external payable {
        balances[msg.sender] += msg.value;
        totalVaultValue += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint256 amount) external whenNotPaused {
        require(balances[msg.sender] >= amount, "Insufficient balance");

        balances[msg.sender] -= amount;

        totalVaultValue -= amount;
        
        // usin  .call intead of .transfer to prevent reverting on out-of-gas
        (bool s, ) = msg.sender.call{value: amount}("");

        require(s, "Transfer failed");
        
        emit Withdrawal(msg.sender, amount);
    }

    // using onlyVault modifier so as to  remove unauthorized draining
    function emergencyWithdrawAll() external onlyVault {
        uint256 vaultBal = address(this).balance;

        totalVaultValue = 0;
        
        (bool s, ) = msg.sender.call{value: vaultBal}("");
        
        require(s, "Transfer failed");
    }

    //   using onlyVault and removing single owner access 
    function pause() external onlyVault {
        paused = true;
    }

    // using onlyVault and removing single owner access 
    function unpause() external onlyVault {
        paused = false;
    }
}
