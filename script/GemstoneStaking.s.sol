// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/GemstoneStaking.sol";

contract DeployGemstoneStaking is Script {
    function run() external {
        // Fetch environment variables.
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address initialOwner = vm.envAddress("INITIAL_OWNER");
        address initialGemstoneContract = vm.envAddress("INITIAL_GEMSTONE_CONTRACT");

        vm.startBroadcast(deployerPrivateKey);
        // Deploy the GemstoneStaking contract with the provided env variables.
        GemstoneStaking staking = new GemstoneStaking(initialOwner, initialGemstoneContract);
        vm.stopBroadcast();

        // Logging the deployed contract address.
        console.log("Deployed GemstoneStaking at:", address(staking));
    }
} 