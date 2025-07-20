// SPDX-License-Identifier: MIT

pragma solidity 0.8.30;

import {Script} from "forge-std/Script.sol";
import {MinimalAccount} from "../src/MinimalAccount.sol";
import {HelperConfig} from "../script/HelperConfig.s.sol";

contract DeployMinimal is Script {
    function run() public {}

    function deployMinimalAccount() public returns (HelperConfig, MinimalAccount) {
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

        // Anvil first address private key
        uint256 PRIVATE_KEY = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
        address deployer = vm.addr(PRIVATE_KEY);

        vm.startBroadcast(PRIVATE_KEY);
        MinimalAccount minimalAccount = new MinimalAccount(config.entryPoint, deployer);
        vm.stopBroadcast();
        return (helperConfig, minimalAccount);
    }
}
