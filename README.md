## Overview of Architecture

The single monolithic `EvictionVault.sol` file has been decomposed and abstracted into modules, utilizing inheritance to minimize proxy overhead:

- `src/EvictionVault.sol` : 
            Main entrypoint which unites the abstract modules.

- `src/interfaces/IEvictionVault.sol`: 
            Handles structure definitions (`Transaction`) and Events.

- `src/modules/EvictionVaultStorage.sol`: 
            Contains common state variables and modifiers (`onlyVault`, `onlyOwner`, `whenNotPaused`).

- `src/modules/VaultCore.sol`: 
            Handles simple ETH operations (`deposit`, `withdraw`, `emergencyWithdrawAll`) and pause toggles.

- `src/modules/MultisigCore.sol`: 
            Contains Multisig proposal and execution functionality.

- `src/modules/MerkleClaim.sol`: 
            Resolves Merkle Tree whitelisting and distribution.

## Fixes I implemented

The following critical vulnerabilities have been successfully addressed:

1. **`setMerkleRoot` Callable by Anyone**: implementing an `onlyVault` modifier. It can now only be set via an approved execution of a multisig transaction.

2. **`emergencyWithdrawAll` Public Drain**: Added the `onlyVault` modifier to prevent arbitrary draining.

3. **`pause/unpause` Single Owner Control**: changed from a single owner `require` to an `onlyVault` requirement, correctly binding the protocol state to the multisig consensus.

4. **`receive()` Uses `tx.origin`**: Swapped `tx.origin` with the secure standard `msg.sender` to prevent potential phishing vectors.

5. **`withdraw` & `claim` Uses `.transfer`**: Replaced `.transfer()` with `.call{value: ...}("")`, which prevents breaking on specific gas limit changes and acts as a security best practice (checks-effects-interactions is respected to prevent Reentrancy).

6. **Timelock Execution Bypass**: Updated `submitTransaction` to immediately set an `executionTime` constraint (`block.timestamp + TIMELOCK_DURATION`) if the `threshold` is `1`. This resolves the skip vulnerability.

## Command Usage

```bash
# to build the project..
forge build

# runnin the test 
forge test -vvv

# for more details on the test..
forge test -vvvv
```
