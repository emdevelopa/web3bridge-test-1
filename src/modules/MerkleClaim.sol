// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./EvictionVaultStorage.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

abstract contract MerkleClaim is EvictionVaultStorage {
    using ECDSA for bytes32;

    // making Only the vault to set the merkle root.
    function setMerkleRoot(bytes32 root) external onlyVault {
        merkleRoot = root;
        emit MerkleRootSet(root);
    }

    function claim(
        bytes32[] calldata proof,
        uint256 amount
    ) external whenNotPaused {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, amount));

        bytes32 computed = MerkleProof.processProof(proof, leaf);

        require(computed == merkleRoot, "Invalid proof");
        require(!claimed[msg.sender], "Already claimed");

        claimed[msg.sender] = true;
        totalVaultValue -= amount;

        // Using .call instead of .transfer
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");

        emit Claim(msg.sender, amount);
    }

    function verifySignature(
        address signer,
        bytes32 messageHash,
        bytes memory signature
    ) external pure returns (bool) {
        return messageHash.recover(signature) == signer;
    }
}
