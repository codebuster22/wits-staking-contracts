// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script, console} from "forge-std/Script.sol";
import {WitsPaymaster} from "../src/WitsPaymaster.sol";

contract WitsPaymasterScript is Script {
    WitsPaymaster public paymaster;

    function setUp() public {}

    function run() public {
        // Get deployment parameters from environment
        address owner = vm.envAddress("OWNER");

        // Start broadcast
        vm.startBroadcast();

        // Deploy WitsPaymaster
        paymaster = new WitsPaymaster(
            owner
        );

        // Fund the paymaster with initial deposit
        uint256 initialDeposit = vm.envUint("INITIAL_DEPOSIT");
        if (initialDeposit > 0) {
            paymaster.deposit{value: initialDeposit}();
            console.log("Deposited initial amount:", initialDeposit);
        }

        console.log("WitsPaymaster deployed at:", address(paymaster));
        console.log("Owner:", owner);

        vm.stopBroadcast();

        // Save deployment information
        saveDeployment(address(paymaster));
    }

    function saveDeployment(address paymasterAddress) internal {
        string memory deployData = string(abi.encodePacked(
            "PAYMASTER_ADDRESS=", vm.toString(paymasterAddress), "\n"
        ));
        vm.writeFile(".env.paymaster", deployData);
    }
}

contract WitsPaymasterAdminScript is Script {
    WitsPaymaster public paymaster;

    function setUp() public {
        paymaster = WitsPaymaster(payable(vm.envAddress("PAYMASTER_ADDRESS")));
    }

    function deposit() public {
        address owner = vm.envAddress("OWNER");
        uint256 amount = vm.envUint("DEPOSIT_AMOUNT");

        vm.startBroadcast(owner);
        paymaster.deposit{value: amount}();
        console.log("Deposited", amount, "to paymaster");
        vm.stopBroadcast();
    }

    function withdraw() public {
        address owner = vm.envAddress("OWNER");
        address recipient = vm.envAddress("WITHDRAW_RECIPIENT");
        uint256 amount = vm.envUint("WITHDRAW_AMOUNT");

        vm.startBroadcast(owner);
        paymaster.withdraw(payable(recipient), amount);
        console.log("Withdrawn", amount, "to", recipient);
        vm.stopBroadcast();
    }

    function addTarget() public {
        address owner = vm.envAddress("OWNER");
        address targetContract = vm.envAddress("TARGET_CONTRACT");

        vm.startBroadcast(owner);
        paymaster.addAllowedTarget(targetContract);
        console.log("Added target contract:", targetContract);
        vm.stopBroadcast();
    }

    function removeTarget() public {
        address owner = vm.envAddress("OWNER");
        address targetContract = vm.envAddress("TARGET_CONTRACT");

        vm.startBroadcast(owner);
        paymaster.removeAllowedTarget(targetContract);
        console.log("Removed target contract:", targetContract);
        vm.stopBroadcast();
    }
} 