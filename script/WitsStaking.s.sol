// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script, console} from "forge-std/Script.sol";
import {WitsStaking} from "../src/WitsStaking.sol";

contract WitsStakingScript is Script {
    WitsStaking public staking;

    function setUp() public {}

    function run() public {
        address owner = vm.envAddress("OWNER");
        vm.startBroadcast();
        staking = new WitsStaking(owner);
        vm.stopBroadcast();
    }
}
