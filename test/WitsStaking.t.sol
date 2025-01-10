// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {WitsStaking} from "../src/WitsStaking.sol";
import {MockERC721} from "./mocks/MockERC721.sol";
import {MockERC20} from "./mocks/MockERC20.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract WitsStakingTest is Test {
    WitsStaking public staking;
    MockERC721 public nft;
    MockERC721 public nft2;
    MockERC20 public token;

    address public owner;
    address public alice;
    address public bob;

    uint256 public constant ONE_DAY = 1 days;
    uint256 public constant ONE_WEEK = 7 days;
    uint256 public constant ONE_MONTH = 30 days;

    event NFTContractWhitelisted(address indexed nftContract);
    event NFTContractRemoved(address indexed nftContract);
    event StakingDurationAdded(uint256 duration);
    event StakingDurationRemoved(uint256 duration);
    event NFTStaked(address indexed nftContract, uint256 indexed tokenId, address indexed staker, uint256 duration);
    event NFTUnstaked(address indexed nftContract, uint256 indexed tokenId, address indexed staker);
    event ContractPauseToggled(bool isPaused);
    event TokensRecovered(address indexed token, address indexed recipient, uint256 amount);

    function setUp() public {
        owner = makeAddr("owner");
        alice = makeAddr("alice");
        bob = makeAddr("bob");

        vm.startPrank(owner);
        
        // Deploy contracts
        staking = new WitsStaking(owner);
        nft = new MockERC721("Test NFT", "TNFT");
        nft2 = new MockERC721("Test NFT 2", "TNFT2");
        token = new MockERC20("Test Token", "TT");

        // Setup staking durations
        staking.addStakingDuration(ONE_DAY);
        staking.addStakingDuration(ONE_WEEK);
        staking.addStakingDuration(ONE_MONTH);

        // Whitelist NFT
        staking.whitelistNFTContract(address(nft));

        vm.stopPrank();

        // Mint NFTs to alice
        vm.startPrank(alice);
        for(uint256 i = 1; i <= 5; i++) {
            nft.mint(i);
        }
        vm.stopPrank();

        // Mint NFTs to bob
        vm.startPrank(bob);
        for(uint256 i = 6; i <= 10; i++) {
            nft.mint(i);
        }
        vm.stopPrank();
    }

    /* ========== ADMIN FUNCTIONS TESTS ========== */

    /// @notice Test admin functions access control
    /// Test case: Non-owner tries to call admin functions
    /// Expected: All calls should revert with Unauthorized error
    function testAdminFunctionsAccessControl() public {
        vm.startPrank(alice);
        
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, alice));
        staking.togglePause();

        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, alice));
        staking.whitelistNFTContract(address(nft2));

        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, alice));
        staking.removeNFTContract(address(nft));

        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, alice));
        staking.addStakingDuration(2 days);

        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, alice));
        staking.removeStakingDuration(ONE_DAY);

        vm.stopPrank();
    }

    /// @notice Test whitelisting NFT contract
    /// Test case: Owner whitelists a valid NFT contract
    /// Expected: Contract should be whitelisted and event emitted
    function testWhitelistNFTContract() public {
        vm.startPrank(owner);
        
        vm.expectEmit(true, false, false, false);
        emit NFTContractWhitelisted(address(nft2));
        staking.whitelistNFTContract(address(nft2));
        
        assertTrue(staking.whitelistedNFTs(address(nft2)));
        vm.stopPrank();
    }

    /// @notice Test removing NFT contract from whitelist
    /// Test case: Owner removes a whitelisted NFT contract
    /// Expected: Contract should be removed and event emitted
    function testRemoveNFTContract() public {
        vm.startPrank(owner);
        
        vm.expectEmit(true, false, false, false);
        emit NFTContractRemoved(address(nft));
        staking.removeNFTContract(address(nft));
        
        assertFalse(staking.whitelistedNFTs(address(nft)));
        vm.stopPrank();
    }

    /// @notice Test adding staking duration
    /// Test case: Owner adds a valid staking duration
    /// Expected: Duration should be added and event emitted
    function testAddStakingDuration() public {
        vm.startPrank(owner);
        
        uint256 newDuration = 14 days;
        vm.expectEmit(false, false, false, true);
        emit StakingDurationAdded(newDuration);
        staking.addStakingDuration(newDuration);
        
        assertTrue(staking.isStakingDurationValid(newDuration));
        vm.stopPrank();
    }

    /// @notice Test removing staking duration
    /// Test case: Owner removes an existing staking duration
    /// Expected: Duration should be removed and event emitted
    function testRemoveStakingDuration() public {
        vm.startPrank(owner);
        
        vm.expectEmit(false, false, false, true);
        emit StakingDurationRemoved(ONE_DAY);
        staking.removeStakingDuration(ONE_DAY);
        
        assertFalse(staking.isStakingDurationValid(ONE_DAY));
        vm.stopPrank();
    }

    /// @notice Test contract pause functionality
    /// Test case: Owner toggles pause state
    /// Expected: Contract should be paused and event emitted
    function testTogglePause() public {
        vm.startPrank(owner);
        
        vm.expectEmit(false, false, false, true);
        emit ContractPauseToggled(true);
        staking.togglePause();
        
        assertTrue(staking.paused());
        
        vm.expectEmit(false, false, false, true);
        emit ContractPauseToggled(false);
        staking.togglePause();
        
        assertFalse(staking.paused());
        vm.stopPrank();
    }

    /* ========== STAKING FUNCTIONS TESTS ========== */

    /// @notice Test single NFT staking
    /// Test case: User stakes a single NFT for valid duration
    /// Expected: NFT should be staked and event emitted
    function testStakeNFT() public {
        uint256 tokenId = 1;
        vm.startPrank(alice);
        nft.approve(address(staking), tokenId);
        
        vm.expectEmit(true, true, true, true);
        emit NFTStaked(address(nft), tokenId, alice, ONE_DAY);
        staking.stakeNFT(address(nft), tokenId, ONE_DAY);
        
        WitsStaking.StakeInfo memory stakeInfo = staking.getStakeInfo(address(nft), tokenId);
        assertEq(stakeInfo.staker, alice);
        assertEq(stakeInfo.endTime, stakeInfo.startTime + ONE_DAY);
        assertTrue(stakeInfo.isStaked);
        assertEq(stakeInfo.stakeDuration, ONE_DAY);
        assertEq(nft.ownerOf(tokenId), address(staking));
        vm.stopPrank();
    }

    /// @notice Test batch NFT staking
    /// Test case: User stakes multiple NFTs in one transaction
    /// Expected: All NFTs should be staked and events emitted
    function testBatchStakeNFTs() public {
        uint256[] memory tokenIds = new uint256[](3);
        tokenIds[0] = 1;
        tokenIds[1] = 2;
        tokenIds[2] = 3;

        vm.startPrank(alice);
        for(uint256 i = 0; i < tokenIds.length; i++) {
            nft.approve(address(staking), tokenIds[i]);
        }
        
        staking.batchStakeNFTs(address(nft), tokenIds, ONE_WEEK);
        
        for(uint256 i = 0; i < tokenIds.length; i++) {
            assertTrue(staking.isNFTStaked(address(nft), tokenIds[i]));
            assertEq(nft.ownerOf(tokenIds[i]), address(staking));
        }
        vm.stopPrank();
    }

    /// @notice Test NFT unstaking
    /// Test case: User unstakes NFT after lock period
    /// Expected: NFT should be unstaked and event emitted
    function testUnstakeNFT() public {
        uint256 tokenId = 1;
        vm.startPrank(alice);
        nft.approve(address(staking), tokenId);
        staking.stakeNFT(address(nft), tokenId, ONE_DAY);
        
        // Fast forward past lock period
        vm.warp(block.timestamp + ONE_DAY + 1);
        
        vm.expectEmit(true, true, true, false);
        emit NFTUnstaked(address(nft), tokenId, alice);
        staking.unstakeNFT(address(nft), tokenId);
        
        assertFalse(staking.isNFTStaked(address(nft), tokenId));
        assertEq(nft.ownerOf(tokenId), alice);
        vm.stopPrank();
    }

    /// @notice Test batch NFT unstaking
    /// Test case: User unstakes multiple NFTs after lock period
    /// Expected: All NFTs should be unstaked and events emitted
    function testBatchUnstakeNFTs() public {
        uint256[] memory tokenIds = new uint256[](3);
        tokenIds[0] = 1;
        tokenIds[1] = 2;
        tokenIds[2] = 3;

        vm.startPrank(alice);
        for(uint256 i = 0; i < tokenIds.length; i++) {
            nft.approve(address(staking), tokenIds[i]);
        }
        staking.batchStakeNFTs(address(nft), tokenIds, ONE_DAY);
        
        // Fast forward past lock period
        vm.warp(block.timestamp + ONE_DAY + 1);
        
        staking.batchUnstakeNFTs(address(nft), tokenIds);
        
        for(uint256 i = 0; i < tokenIds.length; i++) {
            assertFalse(staking.isNFTStaked(address(nft), tokenIds[i]));
            assertEq(nft.ownerOf(tokenIds[i]), alice);
        }
        vm.stopPrank();
    }

    /* ========== FAILURE CASES ========== */

    /// @notice Test staking failures
    /// Test case: Various invalid staking attempts
    /// Expected: All should revert with appropriate errors
    function testStakingFailures() public {
        uint256 tokenId = 1;
        
        // Try staking non-whitelisted NFT
        vm.startPrank(alice);
        nft2.mint(tokenId);
        nft2.approve(address(staking), tokenId);
        vm.expectRevert(WitsStaking.NFTNotWhitelisted.selector);
        staking.stakeNFT(address(nft2), tokenId, ONE_DAY);
        vm.stopPrank();

        // Try staking with invalid duration
        vm.startPrank(alice);
        nft.approve(address(staking), tokenId);
        vm.expectRevert(WitsStaking.InvalidStakingDuration.selector);
        staking.stakeNFT(address(nft), tokenId, 5 days);
        vm.stopPrank();

        // Try staking someone else's NFT
        vm.startPrank(bob);
        vm.expectRevert(WitsStaking.NotTokenOwner.selector);
        staking.stakeNFT(address(nft), tokenId, ONE_DAY);
        vm.stopPrank();

        // Try staking when contract is paused
        vm.prank(owner);
        staking.togglePause();
        
        vm.startPrank(alice);
        vm.expectRevert(Pausable.EnforcedPause.selector);
        staking.stakeNFT(address(nft), tokenId, ONE_DAY);
        vm.stopPrank();
    }

    /// @notice Test unstaking failures
    /// Test case: Various invalid unstaking attempts
    /// Expected: All should revert with appropriate errors
    function testUnstakingFailures() public {
        uint256 tokenId = 1;
        
        // Setup stake
        vm.startPrank(alice);
        nft.approve(address(staking), tokenId);
        staking.stakeNFT(address(nft), tokenId, ONE_DAY);
        vm.stopPrank();

        // Try unstaking before lock period
        vm.startPrank(alice);
        vm.expectRevert(WitsStaking.StakeStillLocked.selector);
        staking.unstakeNFT(address(nft), tokenId);
        vm.stopPrank();

        // Try unstaking someone else's stake
        vm.startPrank(bob);
        vm.expectRevert(WitsStaking.UnauthorizedCaller.selector);
        staking.unstakeNFT(address(nft), tokenId);
        vm.stopPrank();

        // Try unstaking non-existent stake
        vm.startPrank(alice);
        vm.expectRevert(WitsStaking.StakeNotFound.selector);
        staking.unstakeNFT(address(nft), 999);
        vm.stopPrank();
    }

    /// @notice Test emergency unstake
    /// Test case: Admin performs emergency unstake
    /// Expected: NFT should be unstaked regardless of lock period
    function testEmergencyUnstake() public {
        uint256 tokenId = 1;
        
        vm.startPrank(alice);
        nft.approve(address(staking), tokenId);
        staking.stakeNFT(address(nft), tokenId, ONE_MONTH);
        vm.stopPrank();

        vm.startPrank(owner);
        vm.expectEmit(true, true, true, false);
        emit NFTUnstaked(address(nft), tokenId, alice);
        staking.emergencyUnstake(address(nft), tokenId);
        
        assertFalse(staking.isNFTStaked(address(nft), tokenId));
        assertEq(nft.ownerOf(tokenId), alice);
        vm.stopPrank();
    }

    /// @notice Test token recovery
    /// Test case: Admin recovers stuck tokens
    /// Expected: Tokens should be recovered successfully
    function testRecoverTokens() public {
        // Test ETH recovery
        vm.deal(address(staking), 1 ether);
        vm.startPrank(owner);
        vm.expectEmit(true, true, false, true);
        emit TokensRecovered(address(0), owner, 1 ether);
        staking.recoverETH(owner, 1 ether);
        assertEq(address(owner).balance, 1 ether);
        vm.stopPrank();

        // Test ERC20 recovery
        token.mint(address(staking), 1000);
        vm.startPrank(owner);
        vm.expectEmit(true, true, false, true);
        emit TokensRecovered(address(token), owner, 1000);
        staking.recoverERC20(address(token), owner, 1000);
        assertEq(token.balanceOf(owner), 1000);
        vm.stopPrank();

        // Test ERC721 recovery
        uint256 tokenId = 100;
        vm.startPrank(alice);
        nft2.mint(tokenId);
        nft2.transferFrom(alice, address(staking), tokenId);
        vm.stopPrank();

        vm.startPrank(owner);
        vm.expectEmit(true, true, false, true);
        emit TokensRecovered(address(nft2), owner, tokenId);
        staking.recoverERC721(address(nft2), owner, tokenId);
        assertEq(nft2.ownerOf(tokenId), owner);
        vm.stopPrank();
    }

    /// @notice Test token recovery failures
    /// Test case: Various invalid recovery attempts
    /// Expected: All should revert with appropriate errors
    function testRecoverTokenFailures() public {
        vm.startPrank(owner);
        
        // Test ETH recovery failures
        vm.expectRevert(WitsStaking.ZeroAddress.selector);
        staking.recoverETH(address(0), 1 ether);

        vm.expectRevert(WitsStaking.InvalidTokenAmount.selector);
        staking.recoverETH(owner, 0);

        vm.expectRevert(WitsStaking.InvalidTokenAmount.selector);
        staking.recoverETH(owner, 1 ether);

        // Test ERC20 recovery failures
        vm.expectRevert(WitsStaking.ZeroAddress.selector);
        staking.recoverERC20(address(token), address(0), 1000);

        vm.expectRevert(WitsStaking.InvalidTokenAmount.selector);
        staking.recoverERC20(address(token), owner, 0);

        // Test ERC721 recovery failures
        vm.expectRevert(WitsStaking.ZeroAddress.selector);
        staking.recoverERC721(address(nft2), address(0), 1);

        vm.stopPrank();
    }

    /* ========== ADDITIONAL COVERAGE TESTS ========== */

    /// @notice Test ERC721 receiver implementation
    /// Test case: Direct transfer of NFT to contract
    /// Expected: Contract should accept the transfer
    function testOnERC721Received() public {
        uint256 tokenId = 1;
        vm.startPrank(alice);
        nft.safeTransferFrom(alice, address(staking), tokenId);
        assertEq(nft.ownerOf(tokenId), address(staking));
        vm.stopPrank();
    }

    /// @notice Test staking already staked NFT
    /// Test case: Try to stake an NFT that's already staked
    /// Expected: Should revert with StakeAlreadyExists
    function testStakeAlreadyStakedNFT() public {
        uint256 tokenId = 1;
        vm.startPrank(alice);
        nft.approve(address(staking), tokenId);
        staking.stakeNFT(address(nft), tokenId, ONE_DAY);
        
        vm.expectRevert(WitsStaking.StakeAlreadyExists.selector);
        staking.stakeNFT(address(nft), tokenId, ONE_DAY);
        vm.stopPrank();
    }

    /// @notice Test batch staking with already staked NFT
    /// Test case: Try to batch stake when one NFT is already staked
    /// Expected: Should revert with StakeAlreadyExists
    function testBatchStakeWithExistingStake() public {
        uint256[] memory tokenIds = new uint256[](3);
        tokenIds[0] = 1;
        tokenIds[1] = 2;
        tokenIds[2] = 3;

        vm.startPrank(alice);
        for(uint256 i = 0; i < tokenIds.length; i++) {
            nft.approve(address(staking), tokenIds[i]);
        }
        
        // First stake one NFT
        staking.stakeNFT(address(nft), tokenIds[0], ONE_DAY);
        
        // Try to batch stake including the already staked NFT
        vm.expectRevert(WitsStaking.StakeAlreadyExists.selector);
        staking.batchStakeNFTs(address(nft), tokenIds, ONE_DAY);
        vm.stopPrank();
    }

    /// @notice Test batch unstaking failures
    /// Test case: Various invalid batch unstaking attempts
    /// Expected: All should revert with appropriate errors
    function testBatchUnstakingFailures() public {
        uint256[] memory tokenIds = new uint256[](3);
        tokenIds[0] = 1;
        tokenIds[1] = 2;
        tokenIds[2] = 3;

        // Setup stakes
        vm.startPrank(alice);
        for(uint256 i = 0; i < tokenIds.length; i++) {
            nft.approve(address(staking), tokenIds[i]);
        }
        staking.batchStakeNFTs(address(nft), tokenIds, ONE_DAY);
        vm.stopPrank();

        // Try unstaking before lock period
        vm.startPrank(alice);
        vm.expectRevert(WitsStaking.StakeStillLocked.selector);
        staking.batchUnstakeNFTs(address(nft), tokenIds);
        vm.stopPrank();

        // Try unstaking someone else's stakes
        vm.startPrank(bob);
        vm.expectRevert(WitsStaking.UnauthorizedCaller.selector);
        staking.batchUnstakeNFTs(address(nft), tokenIds);
        vm.stopPrank();

        // Try unstaking with non-existent stake in batch
        uint256[] memory invalidTokenIds = new uint256[](2);
        invalidTokenIds[0] = 11;
        invalidTokenIds[1] = 999;
        
        vm.startPrank(alice);
        vm.expectRevert(WitsStaking.StakeNotFound.selector);
        staking.batchUnstakeNFTs(address(nft), invalidTokenIds);
        vm.stopPrank();
    }

    /// @notice Test emergency unstake with non-existent stake
    /// Test case: Admin tries to emergency unstake non-existent stake
    /// Expected: Should revert with StakeNotFound
    function testEmergencyUnstakeNonExistent() public {
        vm.startPrank(owner);
        vm.expectRevert(WitsStaking.StakeNotFound.selector);
        staking.emergencyUnstake(address(nft), 999);
        vm.stopPrank();
    }

    /// @notice Test ETH recovery with failed transfer
    /// Test case: Try to recover ETH to a contract that rejects ETH
    /// Expected: Should revert
    function testRecoverETHFailedTransfer() public {
        // Deploy a contract that rejects ETH
        ETHRejecter rejecter = new ETHRejecter();
        
        // Send ETH to staking contract
        vm.deal(address(staking), 1 ether);
        
        // Try to recover ETH to the rejecting contract
        vm.startPrank(owner);
        vm.expectRevert();
        staking.recoverETH(address(rejecter), 1 ether);
        vm.stopPrank();
    }

    /* ========== ADDITIONAL FAILURE TESTS ========== */

    /// @notice Test whitelisting zero address
    /// Test case: Admin tries to whitelist zero address
    /// Expected: Should revert with ZeroAddress error
    function testWhitelistZeroAddress() public {
        vm.startPrank(owner);
        vm.expectRevert(WitsStaking.ZeroAddress.selector);
        staking.whitelistNFTContract(address(0));
        vm.stopPrank();
    }

    /// @notice Test removing non-whitelisted NFT
    /// Test case: Admin tries to remove NFT that's not whitelisted
    /// Expected: Should revert with NFTNotWhitelisted error
    function testRemoveNonWhitelistedNFT() public {
        vm.startPrank(owner);
        vm.expectRevert(WitsStaking.NFTNotWhitelisted.selector);
        staking.removeNFTContract(address(nft2));
        vm.stopPrank();
    }

    /// @notice Test invalid staking durations
    /// Test case: Admin tries to add invalid staking durations
    /// Expected: Should revert with InvalidStakingDuration error
    function testInvalidStakingDurations() public {
        vm.startPrank(owner);
        
        // Test duration less than minimum
        vm.expectRevert(WitsStaking.InvalidStakingDuration.selector);
        staking.addStakingDuration(30 minutes); // MIN_STAKE_DURATION is 1 hour

        // Test duration more than maximum
        vm.expectRevert(WitsStaking.InvalidStakingDuration.selector);
        staking.addStakingDuration(366 days); // MAX_STAKE_DURATION is 365 days

        vm.stopPrank();
    }

    /// @notice Test removing non-existent staking duration
    /// Test case: Admin tries to remove duration that wasn't added
    /// Expected: Should revert with InvalidStakingDuration error
    function testRemoveNonExistentDuration() public {
        vm.startPrank(owner);
        vm.expectRevert(WitsStaking.InvalidStakingDuration.selector);
        staking.removeStakingDuration(2 days); // 2 days was never added
        vm.stopPrank();
    }

    /// @notice Test batch staking with non-owned NFTs
    /// Test case: User tries to batch stake NFTs they don't own
    /// Expected: Should revert with NotTokenOwner error
    function testBatchStakeNonOwnedNFTs() public {
        uint256[] memory tokenIds = new uint256[](3);
        tokenIds[0] = 1; // owned by alice
        tokenIds[1] = 2; // owned by alice
        tokenIds[2] = 6; // owned by bob

        vm.startPrank(alice);
        for(uint256 i = 0; i < tokenIds.length; i++) {
            try nft.approve(address(staking), tokenIds[i]) {
                continue;
            } catch {
                continue;
            }
        }
        
        vm.expectRevert(WitsStaking.NotTokenOwner.selector);
        staking.batchStakeNFTs(address(nft), tokenIds, ONE_DAY);
        vm.stopPrank();
    }
}

/// @notice Helper contract that rejects ETH transfers
contract ETHRejecter {
    receive() external payable {
        revert("ETH not accepted");
    }
}
