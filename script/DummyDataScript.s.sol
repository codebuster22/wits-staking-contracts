// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script, console} from "forge-std/Script.sol";
import {WitsStaking} from "../src/WitsStaking.sol";
import {MockERC721} from "../test/mocks/MockERC721.sol";
import {MockERC20} from "../test/mocks/MockERC20.sol";
import {Multicall3} from "./Multicall3.sol";

contract DummyDataScript is Script {
    WitsStaking public staking;
    MockERC721 public nft1;
    MockERC721 public nft2;
    MockERC721 public nft3;
    MockERC20 public token1;
    MockERC20 public token2;

    address public owner;
    address[] public users;
    uint256[] public stakingDurations;
    mapping(address => uint256) public userPrivateKeys;

    function setUp() public {
        vm.startBroadcast();
        Multicall3 multicall = new Multicall3();
        console.log("Multicall3 deployed at:", address(multicall));
        vm.stopBroadcast();
        owner = vm.envAddress("OWNER");
        uint256 ownerKey = vm.envUint("PRIVATE_KEY");
        staking = WitsStaking(vm.envAddress("STAKING_ADDRESS"));

        // Setup staking durations
        stakingDurations = [1 days, 7 days, 30 days, 90 days];

        // Create test users with private keys and fund them
        users = new address[](5);
        for (uint256 i = 0; i < 5; i++) {
            uint256 privateKey = 0xBEEF00 + i; // Generate unique private key for each user
            address user = vm.addr(privateKey);
            users[i] = user;
            userPrivateKeys[user] = privateKey;
            
            // Fund user with 1 ETH from owner
            vm.startBroadcast(ownerKey);
            payable(user).call{value: 1 ether}("");
            vm.stopBroadcast();
        }
    }

    function run() public {
        // Check if we're running setup or unstake
        bool isUnstake = vm.envOr("UNSTAKE", false);
        
        if (isUnstake) {
            runUnstake();
        } else {
            runSetup();
        }
    }

    function runSetup() public {
        vm.startBroadcast();

        // Deploy mock contracts
        nft1 = new MockERC721("Dummy NFT 1", "DNFT1");
        nft2 = new MockERC721("Dummy NFT 2", "DNFT2");
        nft3 = new MockERC721("Dummy NFT 3", "DNFT3");
        token1 = new MockERC20("Dummy Token 1", "DT1");
        token2 = new MockERC20("Dummy Token 2", "DT2");

        vm.stopBroadcast();

        console.log("Deployed mock contracts:");
        console.log("NFT1:", address(nft1));
        console.log("NFT2:", address(nft2));
        console.log("NFT3:", address(nft3));
        console.log("Token1:", address(token1));
        console.log("Token2:", address(token2));

        // Save addresses for unstaking
        saveDeployment();

        // Setup admin functions
        setupAdminFunctions();

        // Generate staking data
        generateStakingData();

        // Generate token recovery data
        generateTokenRecoveryData();
    }

    function runUnstake() public {
        // Load deployed contract addresses
        loadDeployment();
        
        console.log("Current block timestamp:", block.timestamp);
        
        // Unstake some NFTs
        for (uint256 i = 0; i < users.length; i++) {
            address user = users[i];

            // Get stake IDs for user's NFTs
            uint256[] memory nft1Ids = new uint256[](3);
            for (uint256 j = 0; j < 3; j++) {
                nft1Ids[j] = i * 3 + j;
            }

            // Try to unstake some NFTs
            for (uint256 j = 0; j < nft1Ids.length; j++) {
                uint256 stakeId = staking.currentStakeIds(address(nft1), nft1Ids[j]);
                if (stakeId > 0) {
                    WitsStaking.StakeInfo memory stake = staking.getStakeInfo(stakeId);
                    console.log("");
                    console.log("Stake ID:", stakeId);
                    console.log("NFT Contract:", stake.nftContract);
                    console.log("Token ID:", stake.tokenId);
                    console.log("Staker:", stake.staker);
                    console.log("Start Time:", stake.startTime);
                    console.log("End Time:", stake.endTime);
                    console.log("Is Staked:", stake.isStaked);
                    console.log("Stake Duration:", stake.stakeDuration);
                    vm.startBroadcast(userPrivateKeys[stake.staker]);
                    
                    try staking.unstakeNFT(stakeId) {
                        console.log("User", i, "unstaked NFT1 ID:", nft1Ids[j]);
                    } catch {
                        console.log("Failed to unstake NFT1 ID:", nft1Ids[j]);
                    }
                    console.log("");
                    vm.stopBroadcast();
                }
            }

        }
    }

    function setupAdminFunctions() internal {
        console.log("Setting up admin functions");
        vm.startBroadcast(owner);
        // Add staking durations
        for (uint256 i = 0; i < stakingDurations.length; i++) {
            try staking.addStakingDuration(stakingDurations[i]) {
                console.log("Added staking duration:", stakingDurations[i]);
            } catch {
                console.log("Staking duration already exists:", stakingDurations[i]);
            }
        }

        // Whitelist NFT contracts
        address[] memory nftContracts = new address[](3);
        nftContracts[0] = address(nft1);
        nftContracts[1] = address(nft2);
        nftContracts[2] = address(nft3);

        for (uint256 i = 0; i < nftContracts.length; i++) {
            try staking.whitelistNFTContract(nftContracts[i]) {
                console.log("Whitelisted NFT contract:", nftContracts[i]);
            } catch {
                console.log("NFT contract already whitelisted:", nftContracts[i]);
            }
        }

        // Toggle pause a few times
        staking.togglePause();
        console.log("Contract paused");
        staking.togglePause();
        console.log("Contract unpaused");
        vm.stopBroadcast();
    }

    function generateStakingData() internal {
        console.log("Generating staking data");
        // Mint NFTs to users and perform staking
        for (uint256 i = 0; i < users.length; i++) {
            address user = users[i];
            
            // Mint NFTs from each collection
            uint256[] memory nft1Ids = mintNFTs(nft1, user, 3, i * 3);
            uint256[] memory nft2Ids = mintNFTs(nft2, user, 2, i * 2);
            uint256[] memory nft3Ids = mintNFTs(nft3, user, 4, i * 4);

            vm.startBroadcast(userPrivateKeys[user]);

            // Stake NFTs individually
            for (uint256 j = 0; j < nft1Ids.length; j++) {
                try nft1.approve(address(staking), nft1Ids[j]) {
                    try staking.stakeNFT(address(nft1), nft1Ids[j], stakingDurations[j % stakingDurations.length]) {
                        console.log("User", i, "staked NFT1 ID:", nft1Ids[j]);
                    } catch {
                        console.log("Failed to stake NFT1 ID:", nft1Ids[j]);
                    }
                } catch {
                    console.log("Failed to approve NFT1 ID:", nft1Ids[j]);
                }
            }

            // Batch stake NFTs
            for (uint256 j = 0; j < nft2Ids.length; j++) {
                try nft2.approve(address(staking), nft2Ids[j]) {} catch {}
            }
            try staking.batchStakeNFTs(address(nft2), nft2Ids, stakingDurations[i % stakingDurations.length]) {
                console.log("User", i, "batch staked NFT2 IDs");
            } catch {
                console.log("Failed to batch stake NFT2 IDs for user", i);
            }

            vm.stopBroadcast();
        }
    }

    function generateTokenRecoveryData() internal {
        console.log("Generating token recovery data");
        vm.startBroadcast(owner);
        // Send some tokens to the staking contract
        token1.mint(address(staking), 1000 ether);
        token2.mint(address(staking), 500 ether);

        // Recover tokens
        try staking.recoverERC20(address(token1), owner, 500 ether) {
            console.log("Recovered 500 token1");
        } catch {
            console.log("Failed to recover token1");
        }

        try staking.recoverERC20(address(token2), owner, 250 ether) {
            console.log("Recovered 250 token2");
        } catch {
            console.log("Failed to recover token2");
        }

        vm.stopBroadcast();
    }

    function mintNFTs(
        MockERC721 nft,
        address to,
        uint256 count,
        uint256 startId
    ) internal returns (uint256[] memory) {
        console.log("Minting NFTs");
        uint256[] memory tokenIds = new uint256[](count);
        vm.startBroadcast(owner);
        for (uint256 i = 0; i < count; i++) {
            uint256 tokenId = startId + i + 1;
            nft.mint(tokenId);
            nft.transferFrom(owner, to, tokenId);
            tokenIds[i] = tokenId;
        }
        vm.stopBroadcast();
        return tokenIds;
    }

    function saveDeployment() internal {
        string memory deploymentData = string(abi.encodePacked(
            "NFT1_ADDRESS=", vm.toString(address(nft1)), "\n",
            "NFT2_ADDRESS=", vm.toString(address(nft2)), "\n",
            "NFT3_ADDRESS=", vm.toString(address(nft3)), "\n",
            "TOKEN1_ADDRESS=", vm.toString(address(token1)), "\n",
            "TOKEN2_ADDRESS=", vm.toString(address(token2)), "\n"
        ));
        vm.writeFile(".env.dummy", deploymentData);
    }

    function loadDeployment() internal {
        nft1 = MockERC721(vm.envAddress("NFT1_ADDRESS"));
        nft2 = MockERC721(vm.envAddress("NFT2_ADDRESS"));
        nft3 = MockERC721(vm.envAddress("NFT3_ADDRESS"));
        token1 = MockERC20(vm.envAddress("TOKEN1_ADDRESS"));
        token2 = MockERC20(vm.envAddress("TOKEN2_ADDRESS"));
    }
} 
