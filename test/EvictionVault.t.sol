// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {EvictionVault} from "../src/EvictionVault.sol";

contract EvictionVaultTest is Test {
    EvictionVault public vault;
    
    address owner1 = address(0x1);
    address owner2 = address(0x2);
    address owner3 = address(0x3);
    
    address user1 = address(0x4);
    address user2 = address(0x5);
    
    address[] owners;
    uint256 threshold = 2;

    function setUp() public {
        owners.push(owner1);
        owners.push(owner2);
        owners.push(owner3);
        
        vm.deal(owner1, 100 ether);
        vm.startPrank(owner1);
        vault = new EvictionVault{value: 10 ether}(owners, threshold);
        vm.stopPrank();
        
        vm.deal(user1, 10 ether);
        vm.deal(user2, 10 ether);
    }

    function test_Deposit() public {
        vm.startPrank(user1);
        vault.deposit{value: 5 ether}();
        vm.stopPrank();

        assertEq(vault.balances(user1), 5 ether);
        assertEq(vault.totalVaultValue(), 15 ether); 
    }

    function test_Withdraw() public {
        vm.startPrank(user1);
        vault.deposit{value: 5 ether}();
        
        uint256 balanceBefore = user1.balance;
        vault.withdraw(3 ether);
        vm.stopPrank();

        assertEq(vault.balances(user1), 2 ether);
        assertEq(user1.balance, balanceBefore + 3 ether);
    }

    function test_SubmitAndExecuteTransaction() public {
        vm.startPrank(owner1);
        vault.submitTransaction(user2, 2 ether, "");
        vm.stopPrank();
        
        // over here the confirmations = 1, threshold = 2, so it shouldn't be ready
        (, , , bool executed, uint256 confirmations, , uint256 executionTime) = vault.transactions(0);
        assertEq(confirmations, 1);
        // Not ready yet
        assertEq(executionTime, 0); 

        vm.startPrank(owner2);
        vault.confirmTransaction(0);
        vm.stopPrank();

        // Now it's ready, executionTime is set
        (, , , , confirmations, , executionTime) = vault.transactions(0);
        assertEq(confirmations, 2);
        assertTrue(executionTime > 0);

        // Trying to execute before timelock
        vm.expectRevert("Timelock active");
        vault.executeTransaction(0);

        // Fast forwarding the time
        vm.warp(block.timestamp + 1 hours + 1 seconds);

        uint256 balanceBefore = user2.balance;
        vault.executeTransaction(0);
        assertEq(user2.balance, balanceBefore + 2 ether);

        (, , , executed, , , ) = vault.transactions(0);
        assertTrue(executed);
    }

    function test_PauseUnpauseViaMultisig() public {
        assertFalse(vault.paused());

        // Constructing  calldata for vault.pause()
        bytes memory pauseData = abi.encodeWithSignature("pause()");

        vm.startPrank(owner1);
        vault.submitTransaction(address(vault), 0, pauseData);
        vm.stopPrank();

        vm.startPrank(owner2);
        vault.confirmTransaction(0);
        vm.stopPrank();

        vm.warp(block.timestamp + 1 hours + 1 seconds);
        vault.executeTransaction(0);

        assertTrue(vault.paused());
        
        // Verify we can't withdraw while paused
        vm.prank(user1);
        vm.expectRevert("Paused");
        vault.withdraw(0);
    }
}
