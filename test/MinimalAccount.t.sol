// SPDX-License-Identifier: MIT

pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {MinimalAccount} from "../src/MinimalAccount.sol";
import {DeployMinimal} from "../script/DeployMinimal.s.sol";
import {HelperConfig} from "../script/HelperConfig.s.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {SendPackedUserOp, PackedUserOperation} from "../script/SendPackedUserOp.s.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {IEntryPoint} from "lib/account-abstraction/contracts/interfaces/IEntryPoint.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

contract MinimalAccountTest is Test {
    using MessageHashUtils for bytes32;

    HelperConfig helperConfig;
    MinimalAccount minimalAccount;
    ERC20Mock usdc;
    SendPackedUserOp sendPackedUserOp;

    address user = makeAddr("user");
    uint256 public constant AMOUNT = 1e18; // 1 ether or 1000000000000000000 wei

    function setUp() public {
        DeployMinimal deployMinimal = new DeployMinimal();
        (helperConfig, minimalAccount) = deployMinimal.deployMinimalAccount();

        usdc = new ERC20Mock();
        sendPackedUserOp = new SendPackedUserOp();
    }

    // USDC Approval

    // msg.sender -> MinimalAccount
    // approve some amount
    // USDC contract
    // come from the entrypoint

    function testOwnerCanExecuteCommands() public {
        // Arrange
        assertEq(usdc.balanceOf(address(minimalAccount)), 0);

        address destination = address(usdc);
        uint256 value = 0;
        bytes memory functionData = abi.encodeWithSelector(
            ERC20Mock.mint.selector,
            address(minimalAccount),
            AMOUNT
        );

        // Act
        vm.prank(minimalAccount.owner());
        minimalAccount.execute(destination, value, functionData);

        // Assert
        assertEq(usdc.balanceOf(address(minimalAccount)), AMOUNT);
    }

    function testNonOwnerCannotExecuteCommands() public {
        // Arrange
        assertEq(usdc.balanceOf(address(minimalAccount)), 0);

        address destination = address(usdc);
        uint256 value = 0;
        bytes memory functionData = abi.encodeWithSelector(
            ERC20Mock.mint.selector,
            address(minimalAccount),
            AMOUNT
        );

        // Act
        vm.prank(user);
        vm.expectRevert(MinimalAccount.NotFromEntryPointOrOwner.selector);
        minimalAccount.execute(destination, value, functionData);

        // Assert
        assertEq(usdc.balanceOf(address(minimalAccount)), 0);
    }

    function testRecoverSignedOp() public {
        // arrange
        assertEq(usdc.balanceOf(address(minimalAccount)), 0);

        address destination = address(usdc);
        uint256 value = 0;
        bytes memory functionData = abi.encodeWithSelector(
            ERC20Mock.mint.selector,
            address(minimalAccount),
            AMOUNT
        );

        bytes memory executeCallData = abi.encodeWithSelector(
            MinimalAccount.execute.selector,
            destination,
            value,
            functionData
        );
        PackedUserOperation memory packedUserOp = sendPackedUserOp
            .generatedSignedUserOperation(
                executeCallData,
                helperConfig.getConfig(),
                address(minimalAccount)
            );
        bytes32 userOperationHash = IEntryPoint(
            helperConfig.getConfig().entryPoint
        ).getUserOpHash(packedUserOp);

        // act
        address actualSigner = ECDSA.recover(
            userOperationHash.toEthSignedMessageHash(),
            packedUserOp.signature
        );

        // assert
        assertEq(actualSigner, minimalAccount.owner());
    }

    function testValidationUserOp() public {
        // arrange
        assertEq(usdc.balanceOf(address(minimalAccount)), 0);

        address destination = address(usdc);
        uint256 value = 0;
        bytes memory functionData = abi.encodeWithSelector(
            ERC20Mock.mint.selector,
            address(minimalAccount),
            AMOUNT
        );

        bytes memory executeCallData = abi.encodeWithSelector(
            MinimalAccount.execute.selector,
            destination,
            value,
            functionData
        );
        PackedUserOperation memory packedUserOp = sendPackedUserOp
            .generatedSignedUserOperation(
                executeCallData,
                helperConfig.getConfig(),
                address(minimalAccount)
            );
        bytes32 userOperationHash = IEntryPoint(
            helperConfig.getConfig().entryPoint
        ).getUserOpHash(packedUserOp);
        uint256 missingAccountFunds = 1e18; // 1 ether

        // act
        vm.prank(helperConfig.getConfig().entryPoint);
        uint256 validationData = minimalAccount.validateUserOp(
            packedUserOp,
            userOperationHash,
            missingAccountFunds
        );

        assertEq(validationData, 0);
    }

    function testEntryPointCanExecuteCommands() public {
                // arrange
        assertEq(usdc.balanceOf(address(minimalAccount)), 0);

        address destination = address(usdc);
        uint256 value = 0;
        bytes memory functionData = abi.encodeWithSelector(
            ERC20Mock.mint.selector,
            address(minimalAccount),
            AMOUNT
        );

        bytes memory executeCallData = abi.encodeWithSelector(
            MinimalAccount.execute.selector,
            destination,
            value,
            functionData
        );
        PackedUserOperation memory packedUserOp = sendPackedUserOp
            .generatedSignedUserOperation(
                executeCallData,
                helperConfig.getConfig(),
                address(minimalAccount)
            );
        // bytes32 userOperationHash = IEntryPoint(
        //     helperConfig.getConfig().entryPoint
        // ).getUserOpHash(packedUserOp);

        vm.deal(address(minimalAccount), 1e18); // 1 ether
        PackedUserOperation[] memory ops = new PackedUserOperation[](1);
        ops[0] = packedUserOp;

        // act
        vm.prank(user);
        IEntryPoint(helperConfig.getConfig().entryPoint).handleOps(ops, payable(user));

        // assert
        assertEq(usdc.balanceOf(address(minimalAccount)), AMOUNT);
    }
}
