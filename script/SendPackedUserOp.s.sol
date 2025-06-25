// SPDX-License-Identifier: MIT

pragma solidity 0.8.30;

import {Script} from "forge-std/Script.sol";
import {PackedUserOperation} from "lib/account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {IEntryPoint} from "lib/account-abstraction/contracts/interfaces/IEntryPoint.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol"; 
import {MinimalAccount} from "../src/MinimalAccount.sol";

contract SendPackedUserOp is Script {
    using MessageHashUtils for bytes32;

    // function run() public {
    //     HelperConfig helperConfig = new HelperConfig();
    //     address destination = 0x94a9D9AC8a22534E3FaCa9F4e7F2E2cf85d5E4C8; // sepolia testnet USDC address
    //     uint256 value = 0;
    //     bytes memory functionData = abi.encodeWithSelector(IERC20.approve.selector, 0x70207125F31bCCE6179896768aD362510698E679, 1e18);
    //     bytes memory executeCalldata = abi.encodeWithSelector(MinimalAccount.execute.selector, destination, value, functionData);
    //     PackedUserOperation memory userOp = generatedSignedUserOperation(executeCalldata, helperConfig.getConfig(), <ADRESS_MINIMAL_ACCOUNT>);

    //     PackedUserOperation[] memory ops = new PackedUserOperation[](1);

    //     ops[0] = userOp;
    //     vm.startBroadcast();
    //     IEntryPoint(helperConfig.getConfig().entryPoint.handleOps(ops, payable(helperConfig.getConfig().account));
    //     vm.stopBroadcast();

    // }

    function generatedSignedUserOperation(bytes memory callData, HelperConfig.NetworkConfig memory config, address minimalAccount) public view returns(PackedUserOperation memory) {
        // 1. Generate the unsigned data
        uint256 nonce = vm.getNonce(minimalAccount) - 1;
        PackedUserOperation memory userOp = _generateUnsignedUserOperation(callData, minimalAccount, nonce);

        // 2. Get the userOp hash
        bytes32 userOpHash = IEntryPoint(config.entryPoint).getUserOpHash(userOp);
        bytes32 digest = userOpHash.toEthSignedMessageHash();

        // 3. Sign
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint256 ANVIL_DEFAULT_KEY = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
    
        if (block.chainid == 31337) {
            (v, r, s) = vm.sign(ANVIL_DEFAULT_KEY, digest);
        } else {
            (v, r, s) = vm.sign(config.account, digest);
        }

        userOp.signature = abi.encodePacked(r, s, v); // Note the order
        return userOp;
    }

    function _generateUnsignedUserOperation(bytes memory callData, address _sender, uint256 _nonce) internal pure returns(PackedUserOperation memory) {
        uint128 verificationGasLimit = 16777216;
        uint128 callGasLimit = verificationGasLimit;
        uint128 maxPriorityFeePerGas = 256;
        uint128 maxFeePerGas = maxPriorityFeePerGas;

        return PackedUserOperation({
            sender: _sender,
            nonce: _nonce,
            initCode: hex"",
            callData: callData,
            accountGasLimits: bytes32(uint256(verificationGasLimit) << 128 | callGasLimit),
            preVerificationGas: verificationGasLimit,
            gasFees: bytes32(uint256(maxPriorityFeePerGas) << 128 | maxFeePerGas),
            paymasterAndData: hex"",
            signature: hex""
        });
    }
}