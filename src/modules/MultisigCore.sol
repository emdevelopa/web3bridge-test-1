// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./EvictionVaultStorage.sol";

abstract contract MultisigCore is EvictionVaultStorage {
    
    function submitTransaction(address to, uint256 value, bytes calldata data) external whenNotPaused onlyOwner {
        uint256 id = txCount++;
        
        uint256 executeAt = 0;
        // condition checking If threshold is 1, then set execution time immediately to enforce timelock
        if (threshold == 1) {
            executeAt = block.timestamp + TIMELOCK_DURATION;
        }

        transactions[id] = Transaction({
            to: to,
            value: value,
            data: data,
            executed: false,
            confirmations: 1,
            submissionTime: block.timestamp,
            executionTime: executeAt
        });
        
        confirmed[id][msg.sender] = true;
        emit Submission(id);
    }

    function confirmTransaction(uint256 txId) external whenNotPaused onlyOwner {
        Transaction storage txn = transactions[txId];

        require(!txn.executed, "Already executed");
        require(!confirmed[txId][msg.sender], "Already confirmed");
        
        confirmed[txId][msg.sender] = true;
        txn.confirmations++;
        


        if (txn.confirmations == threshold) {
            txn.executionTime = block.timestamp + TIMELOCK_DURATION;
        }
        
        emit Confirmation(txId, msg.sender);
    }

    function executeTransaction(uint256 txId) external {
        Transaction storage txn = transactions[txId];

        require(txn.confirmations >= threshold, "Wait for threshold");
        require(!txn.executed, "Already executed");
        require(block.timestamp >= txn.executionTime, "Timelock active");
        
        txn.executed = true;
        
        (bool success,) = txn.to.call{value: txn.value}(txn.data);

        require(success, "Execution failed");
        
        emit Execution(txId);
    }
}
