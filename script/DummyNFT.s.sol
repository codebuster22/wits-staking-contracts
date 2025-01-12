// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../test/mocks/MockERC721.sol";
import "../src/WitsStaking.sol";

contract DummyNFTScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address stakingAddress = vm.envAddress("STAKING_ADDRESS");
        
        vm.startBroadcast(deployerPrivateKey);

        // Deploy NFT contract
        MockERC721 nft = new MockERC721("DummyNFT", "DNFT");

        // Add NFT to staking whitelist
        WitsStaking staking = WitsStaking(stakingAddress);
        staking.whitelistNFTContract(address(nft));

        vm.stopBroadcast();
    }
}
