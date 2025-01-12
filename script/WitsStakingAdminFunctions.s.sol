// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script, console} from "forge-std/Script.sol";
import {WitsStaking} from "../src/WitsStaking.sol";

abstract contract BaseScript is Script {
    WitsStaking public staking;

    function setUp() public virtual {
        address stakingAddress = vm.envAddress("STAKING_ADDRESS");
        staking = WitsStaking(stakingAddress);
    }
}

contract AddStakingDuration is BaseScript {
    function run() public {
        address owner = vm.envAddress("OWNER");
        uint256 duration = vm.envUint("DURATION");

        vm.startBroadcast(owner);
        staking.addStakingDuration(duration);
        console.log("Added staking duration: %s seconds", duration);
        vm.stopBroadcast();
    }
}

contract RemoveStakingDuration is BaseScript {
    function run() public {
        address owner = vm.envAddress("OWNER");
        uint256 duration = vm.envUint("DURATION");

        vm.startBroadcast(owner);
        staking.removeStakingDuration(duration);
        console.log("Removed staking duration: %s seconds", duration);
        vm.stopBroadcast();
    }
}

contract AddNFTContract is BaseScript {
    function run() public {
        address owner = vm.envAddress("OWNER");
        address nftContract = vm.envAddress("NFT_CONTRACT");

        vm.startBroadcast(owner);
        staking.whitelistNFTContract(nftContract);
        console.log("Whitelisted NFT contract: %s", nftContract);
        vm.stopBroadcast();
    }
}

contract RemoveNFTContract is BaseScript {
    function run() public {
        address owner = vm.envAddress("OWNER");
        address nftContract = vm.envAddress("NFT_CONTRACT");

        vm.startBroadcast(owner);
        staking.removeNFTContract(nftContract);
        console.log("Removed NFT contract: %s", nftContract);
        vm.stopBroadcast();
    }
}

contract PauseContract is BaseScript {
    function run() public {
        address owner = vm.envAddress("OWNER");

        vm.startBroadcast(owner);
        staking.togglePause();
        bool isPaused = staking.paused();
        console.log("Contract is now %s", isPaused ? "paused" : "unpaused");
        vm.stopBroadcast();
    }
}

contract RecoverETH is BaseScript {
    function run() public {
        address owner = vm.envAddress("OWNER");
        address recipient = vm.envAddress("RECIPIENT");
        uint256 amount = vm.envUint("AMOUNT");

        vm.startBroadcast(owner);
        staking.recoverETH(recipient, amount);
        console.log("Recovered %s wei to %s", amount, recipient);
        vm.stopBroadcast();
    }
}

contract RecoverERC20 is BaseScript {
    function run() public {
        address owner = vm.envAddress("OWNER");
        address token = vm.envAddress("TOKEN_ADDRESS");
        address recipient = vm.envAddress("RECIPIENT");
        uint256 amount = vm.envUint("AMOUNT");

        vm.startBroadcast(owner);
        staking.recoverERC20(token, recipient, amount);
        console.log("Recovered %s tokens from %s to %s", amount, token, recipient);
        vm.stopBroadcast();
    }
}

contract RecoverERC721 is BaseScript {
    function run() public {
        address owner = vm.envAddress("OWNER");
        address token = vm.envAddress("TOKEN_ADDRESS");
        address recipient = vm.envAddress("RECIPIENT");
        uint256 tokenId = vm.envUint("TOKEN_ID");

        vm.startBroadcast(owner);
        staking.recoverERC721(token, recipient, tokenId);
        console.log("Recovered NFT %s from %s to %s", tokenId, token, recipient);
        vm.stopBroadcast();
    }
}

contract EmergencyUnstake is BaseScript {
    function run() public {
        address owner = vm.envAddress("OWNER");
        uint256 stakeId = vm.envUint("STAKE_ID");

        vm.startBroadcast(owner);
        staking.emergencyUnstake(stakeId);
        console.log("Emergency unstaked NFT with stake ID: %s", stakeId);
        vm.stopBroadcast();
    }
} 