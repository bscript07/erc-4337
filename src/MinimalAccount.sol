// SPDX-License-Identifier: MIT

pragma solidity 0.8.30;

import {IAccount} from "lib/account-abstraction/contracts/interfaces/IAccount.sol";
import {PackedUserOperation} from "lib/account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {SIG_VALIDATION_FAILED, SIG_VALIDATION_SUCCESS} from "lib/account-abstraction/contracts/core/Helpers.sol";
import {IEntryPoint} from "lib/account-abstraction/contracts/interfaces/IEntryPoint.sol";

contract MinimalAccount is IAccount, Ownable {
    // Custom errors for better clarity
    error CannotFund();
    error NotFromEntryPointOrOwner();
    error CallFailed(bytes);
    error CannotDeposit();

    // Interface of entry point
    IEntryPoint private immutable i_entryPoint;

    // Require from entry point or from owner modifier
    modifier requireFromEntryPointOrOwner() {
        require(msg.sender == address(i_entryPoint) || msg.sender == owner(), NotFromEntryPointOrOwner());
        _;
    }

    // Set initial owner with entry point interface
    constructor(address entryPoint, address initialOwner) Ownable(initialOwner) {
        i_entryPoint = IEntryPoint(entryPoint);
    }

    // Only owner can deposit ETH in minimal account contract
    function deposit() external payable {
        require(msg.sender == owner(), CannotDeposit());
    }

    function execute(address destination, uint256 value, bytes calldata functionData)
        external
        requireFromEntryPointOrOwner
    {
        // Transfer ETH to `destination` address with `functionData` hash
        (bool success, bytes memory result) = destination.call{value: value}(functionData);
        require(success, CallFailed(result));
    }

    // A signature is valid, if it's the minimal account owner
    function validateUserOp(PackedUserOperation calldata userOp, bytes32 userOpHash, uint256 missingAccountFunds)
        external
        returns (uint256 validationData)
    {
        // Assign validation data for valid user operation and user operation hash
        validationData = _validateSignature(userOp, userOpHash);

        // Prefund missing account funds
        _payPrefund(missingAccountFunds);
    }

    // EIP-191 version of the signed hash
    function _validateSignature(PackedUserOperation calldata userOp, bytes32 userOpHash)
        internal
        view
        returns (uint256 validationData)
    {
        // Sign user operation hash transaction
        bytes32 ethSignedMessageHash = MessageHashUtils.toEthSignedMessageHash(userOpHash);
        // Sign transaction
        address signer = ECDSA.recover(ethSignedMessageHash, userOp.signature);

        // Condition for signer on transaction
        if (signer != owner()) {
            return SIG_VALIDATION_FAILED;
        } else {
            return SIG_VALIDATION_SUCCESS;
        }
    }

    function _payPrefund(uint256 missingAccountFunds) internal {
        if (missingAccountFunds != 0) {
            // Transfer user missing account funds
            (bool success,) = payable(msg.sender).call{value: missingAccountFunds, gas: type(uint256).max}("");
            (success);
        }
    }

    /////////////////GETTERS///////////////

    // Get address of interface entry point
    function getEntryPoint() external view returns (address) {
        return address(i_entryPoint);
    }
}
