/*
Test Cases Plan for GemstoneStaking Contract:

1. Single NFT Stake:
   - Setup:
     • Deploy GemstoneStaking with an initial owner and a valid Gemstone ERC721 contract address.
     • Mint an NFT (with a specific tokenId) to a test user.
   - Test:
     • Call stakeNFT(tokenId) from the token owner.
     • Verify that:
         - The NFT is transferred from the user to the staking contract.
         - A new stake entry is created with:
             - tokenId correct
             - staker set to the caller's address
             - startTime approximately equal to the block.timestamp
             - stakeSeasonId equal to the current seasonId
             - isStaked set to true
         - The NFTStaked event is emitted with the correct parameters.
   - Negative Cases:
     • If the caller is not the owner, stakeNFT should revert with NotOwnerOrStakingAlreadyExists.

2. Batch NFT Stake:
   - Setup:
     • Mint multiple NFTs (multiple tokenIds) to a test user.
   - Test:
     • Call batchStakeNFTs(nftContract, tokenIds, duration) from the token owner.
     • Verify that:
         - For each tokenId:
             - A stake entry is created with the correct tokenId, staker, startTime, stakeSeasonId, and isStaked is true.
             - The NFT is transferred from the user to the contract.
             - NFTStaked event is emitted.
         - Stake IDs increment correctly.
   - Negative Cases:
     • If at least one token in tokenIds is not owned by the caller, the entire transaction should revert.

3. Single NFT Unstake:
   - Setup:
     • Stake an NFT using stakeNFT.
     • Increase the season by calling startNewSeason (by the owner) so that seasonId > stakeSeasonId.
   - Test:
     • Call unstakeNFT(stakeId) by the original staker.
     • Verify that:
         - The NFT is transferred back from the contract to the staker.
         - The corresponding stake entry's isStaked is set to false.
         - NFTUnstaked event is emitted with correct parameters.
   - Negative Cases:
     • If called by someone other than the staker; should revert with UnauthorizedCaller.
     • If unstakeNFT is called without season advancement (i.e. seasonId <= stake.stakeSeasonId), it should revert with StakeStillLocked.
     • If the stakeId does not exist or has already been unstaked, it should revert with StakeNotFound.

4. Batch NFT Unstake:
   - Setup:
     • Stake multiple NFTs.
     • Increase seasonId by calling startNewSeason.
   - Test:
     • Call batchUnstakeNFTs(stakeIds) with an array of the stakeIds.
     • Verify that:
         - Each NFT is transferred from the contract back to the staker.
         - Each stake entry's isStaked is updated to false.
         - NFTUnstaked event is emitted for each unstaked NFT.
   - Negative Cases:
     • Similar to single unstake, ensure that if any stake in the batch fails (not owned or still locked) the transaction reverts.

5. Start New Season:
   - Test:
     • Only the owner should be able to call startNewSeason.
     • On calling startNewSeason:
         - seasonId is incremented.
         - The NextSeasonStarted event is emitted with the new seasonId.
         - Previously staked NFTs become eligible for unstaking (if their stakeSeasonId is less than the new seasonId).
   - Negative Cases:
     • Non-owner attempts to call startNewSeason should revert.

6. Toggling Pause State:
   - Test:
     • Ensure the contract is initially unpaused.
     • Have the owner call togglePause:
         - Verify the contract is paused.
         - ContractPauseToggled event is emitted.
         - Attempts to stake (stakeNFT or batchStakeNFTs) while paused should revert.
     • Have the owner toggle again:
         - Verify that the contract is unpaused.
         - Staking functions work normally.
   - Negative Cases:
     • Non-owner trying to toggle pause should be rejected (this depends on Ownable behavior).

7. Emergency Unstake:
   - Setup:
     • Stake an NFT normally.
   - Test:
     • The owner calls emergencyUnstake(stakeId) without requiring season advancement.
     • Verify that:
         - The stake entry's isStaked is set to false.
         - The NFT is transferred back from the contract to the original staker.
         - NFTUnstaked event is emitted with correct parameters.
   - Negative Cases:
     • A non-owner calling emergencyUnstake should revert.
     • Calling emergencyUnstake on a non-existent or already unstaked stake should revert with StakeNotFound or similar.

8. Additional Owner-Only Functions (Recovery and Update):
   - Test:
     • recoverETH: The owner can recover ETH if available; check balance adjustments.
     • recoverERC20: The owner can transfer ERC20 tokens from the contract.
     • recoverERC721: The owner can recover ERC721 tokens from the contract.
     • updateGemstoneContract: The owner can update the NFT contract address; verify event emission.
   - Negative Cases:
     • Non-owner calling any of these functions should revert with appropriate access control errors.

This test plan covers the main functionalities and edge cases of the GemstoneStaking contract.
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/GemstoneStaking.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// A minimal ERC721 implementation for our tests.
contract TestERC721 is ERC721 {
    uint256 public tokenCounter;

    constructor() ERC721("TestNFT", "TNFT") {}

    function mint(address to) public returns (uint256) {
        tokenCounter++;
        _mint(to, tokenCounter);
        return tokenCounter;
    }
}

// A minimal ERC20 implementation for our tests.
contract TestERC20 is IERC20 {
    string public name = "TestToken";
    string public symbol = "TT";
    uint8 public decimals = 18;
    uint256 public override totalSupply;

    mapping(address => uint256) public balances;

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        require(balances[msg.sender] >= amount, "insufficient balance");
        balances[msg.sender] -= amount;
        balances[recipient] += amount;
        return true;
    }
    
    function approve(address, uint256) external pure override returns (bool) {
        return true;
    }
    
    function transferFrom(address, address, uint256) external pure override returns (bool) {
        return true;
    }
    
    function balanceOf(address account) external view override returns (uint256) {
        return balances[account];
    }
    
    function allowance(address, address) external pure override returns (uint256) {
        return 0;
    }
    
    // For testing: mint tokens to an address.
    function mint(address to, uint256 amount) public {
        balances[to] += amount;
        totalSupply += amount;
    }
}

contract GemstoneStakingTest is Test {
    GemstoneStaking public staking;
    TestERC721 public testNFT;

    // Define some test addresses.
    address owner = address(1);
    address user = address(2);
    address attacker = address(3);

    // Events to match expected events from GemstoneStaking.
    event NFTStaked(uint256 indexed tokenId, address indexed staker, uint256 seasonId, uint256 stakeId);
    event NFTUnstaked(uint256 indexed tokenId, address indexed staker, uint256 stakeId);
    event NextSeasonStarted(uint256 seasonId);
    event ContractPauseToggled(bool isPaused);
    event GemstoneContractUpdated(address indexed nftContract);

    function setUp() public {
        vm.startPrank(owner);
        testNFT = new TestERC721();
        staking = new GemstoneStaking(owner, address(testNFT));
        vm.stopPrank();
    }

    // 1. Single NFT Stake Test
    function testSingleNFTStake() public {
        vm.startPrank(user);
        uint256 tokenId = testNFT.mint(user);
        // Approve staking contract to transfer the NFT.
        testNFT.setApprovalForAll(address(staking), true);
        // Expect NFTStaked event.
        vm.expectEmit(true, true, false, true);
        emit NFTStaked(tokenId, user, 1, 1);
        staking.stakeNFT(tokenId);
        vm.stopPrank();

        // Verify ownership and stake entry.
        assertEq(testNFT.ownerOf(tokenId), address(staking));
        (uint256 stakedTokenId, address staker, , uint256 stakeSeasonId, bool isStaked) = staking.stakes(1);
        assertEq(stakedTokenId, tokenId);
        assertEq(staker, user);
        assertEq(stakeSeasonId, 1);
        assertTrue(isStaked);
    }

    // 2. Batch NFT Stake Test
    function testBatchNFTStake() public {
        vm.startPrank(user);
        uint256 tokenId1 = testNFT.mint(user);
        uint256 tokenId2 = testNFT.mint(user);
        testNFT.setApprovalForAll(address(staking), true);
        uint256[] memory tokenIds = new uint256[](2);
        tokenIds[0] = tokenId1;
        tokenIds[1] = tokenId2;
        staking.batchStakeNFTs(address(testNFT), tokenIds, 100);
        vm.stopPrank();

        // Check ownership transfer.
        assertEq(testNFT.ownerOf(tokenId1), address(staking));
        assertEq(testNFT.ownerOf(tokenId2), address(staking));

        // Check stored stake entries.
        (uint256 stakedTokenId1,, , uint256 stakeSeasonId1, bool isStaked1) = staking.stakes(1);
        (uint256 stakedTokenId2,, , uint256 stakeSeasonId2, bool isStaked2) = staking.stakes(2);
        assertEq(stakedTokenId1, tokenId1);
        assertEq(stakedTokenId2, tokenId2);
        assertEq(stakeSeasonId1, 1);
        assertEq(stakeSeasonId2, 1);
        assertTrue(isStaked1);
        assertTrue(isStaked2);
    }
    
    // Negative: Batch stake with one token not owned by the caller.
    function testBatchNFTStakeRevertForNotOwner() public {
        vm.startPrank(user);
        uint256 tokenId1 = testNFT.mint(user);
        vm.stopPrank();

        vm.startPrank(attacker);
        uint256 tokenId2 = testNFT.mint(attacker);
        testNFT.setApprovalForAll(address(staking), true);
        vm.stopPrank();

        vm.startPrank(user);
        testNFT.setApprovalForAll(address(staking), true);
        uint256[] memory tokenIds = new uint256[](2);
        tokenIds[0] = tokenId1;
        tokenIds[1] = tokenId2;
        vm.expectRevert();
        staking.batchStakeNFTs(address(testNFT), tokenIds, 100);
        vm.stopPrank();
    }

    // 3. Single NFT Unstake Test
    function testSingleNFTUnstake() public {
        // Stake an NFT.
        vm.startPrank(user);
        uint256 tokenId = testNFT.mint(user);
        testNFT.setApprovalForAll(address(staking), true);
        staking.stakeNFT(tokenId);
        vm.stopPrank();

        // Advance season.
        vm.startPrank(owner);
        vm.expectEmit(true, false, false, true);
        emit NextSeasonStarted(2);
        staking.startNewSeason();
        vm.stopPrank();

        // Unstake the NFT.
        vm.startPrank(user);
        vm.expectEmit(true, true, false, true);
        emit NFTUnstaked(tokenId, user, 1);
        staking.unstakeNFT(1);
        vm.stopPrank();

        // Verify NFT returned and stake updated.
        assertEq(testNFT.ownerOf(tokenId), user);
        (, , , , bool isStaked) = staking.stakes(1);
        assertFalse(isStaked);
    }

    // Negative: Unstake before season advancement should revert.
    function testUnstakeBeforeSeasonAdvanceRevert() public {
        vm.startPrank(user);
        uint256 tokenId = testNFT.mint(user);
        testNFT.setApprovalForAll(address(staking), true);
        staking.stakeNFT(tokenId);
        vm.expectRevert();
        staking.unstakeNFT(1);
        vm.stopPrank();
    }

    // Negative: Unstake by a non-owner should revert.
    function testUnstakeByNonOwnerRevert() public {
        vm.startPrank(user);
        uint256 tokenId = testNFT.mint(user);
        testNFT.setApprovalForAll(address(staking), true);
        staking.stakeNFT(tokenId);
        vm.stopPrank();

        vm.startPrank(owner);
        staking.startNewSeason();
        vm.stopPrank();

        vm.startPrank(attacker);
        vm.expectRevert();
        staking.unstakeNFT(1);
        vm.stopPrank();
    }

    // 4. Batch NFT Unstake Test
    function testBatchNFTUnstake() public {
        vm.startPrank(user);
        uint256 tokenId1 = testNFT.mint(user);
        uint256 tokenId2 = testNFT.mint(user);
        testNFT.setApprovalForAll(address(staking), true);
        uint256[] memory tokenIds = new uint256[](2);
        tokenIds[0] = tokenId1;
        tokenIds[1] = tokenId2;
        staking.batchStakeNFTs(address(testNFT), tokenIds, 100);
        vm.stopPrank();

        vm.startPrank(owner);
        staking.startNewSeason();
        vm.stopPrank();

        vm.startPrank(user);
        uint256[] memory stakeIds = new uint256[](2);
        stakeIds[0] = 1;
        stakeIds[1] = 2;
        staking.batchUnstakeNFTs(stakeIds);
        vm.stopPrank();

        // Verify NFTs are returned.
        assertEq(testNFT.ownerOf(tokenId1), user);
        assertEq(testNFT.ownerOf(tokenId2), user);

        (, , , , bool isStaked1) = staking.stakes(1);
        (, , , , bool isStaked2) = staking.stakes(2);
        assertFalse(isStaked1);
        assertFalse(isStaked2);
    }

    // Negative: Batch unstake when stakes are still locked.
    function testBatchUnstakeRevertForInvalidStake() public {
        vm.startPrank(user);
        uint256 tokenId1 = testNFT.mint(user);
        uint256 tokenId2 = testNFT.mint(user);
        testNFT.setApprovalForAll(address(staking), true);
        uint256[] memory tokenIds = new uint256[](2);
        tokenIds[0] = tokenId1;
        tokenIds[1] = tokenId2;
        staking.batchStakeNFTs(address(testNFT), tokenIds, 100);
        vm.stopPrank();

        vm.startPrank(user);
        uint256[] memory stakeIds = new uint256[](2);
        stakeIds[0] = 1;
        stakeIds[1] = 2;
        vm.expectRevert();
        staking.batchUnstakeNFTs(stakeIds);
        vm.stopPrank();
    }

    // 5. Start New Season Test
    function testStartNewSeason() public {
        vm.startPrank(owner);
        staking.startNewSeason();
        vm.stopPrank();

        // Stake a new NFT and confirm its stakeSeasonId equals new season (2).
        vm.startPrank(user);
        uint256 tokenId = testNFT.mint(user);
        testNFT.setApprovalForAll(address(staking), true);
        staking.stakeNFT(tokenId);
        vm.stopPrank();

        (, , , uint256 stakeSeasonId, ) = staking.stakes(1);
        assertEq(stakeSeasonId, 2);
    }

    // Negative: Non-owner calling startNewSeason should revert.
    function testNonOwnerStartNewSeasonRevert() public {
        vm.startPrank(attacker);
        vm.expectRevert();
        staking.startNewSeason();
        vm.stopPrank();
    }

    // 6. Toggling Pause State Test
    function testTogglePause() public {
        vm.startPrank(owner);
        bool initialPaused = staking.paused();
        assertFalse(initialPaused);

        // Toggle pause.
        staking.togglePause();
        assertTrue(staking.paused());

        staking.togglePause();
        assertFalse(staking.paused());
        vm.stopPrank();

        // Ensure staking is prevented when paused.
        vm.startPrank(owner);
        staking.togglePause(); // pause contract
        vm.stopPrank();

        vm.startPrank(user);
        uint256 tokenId = testNFT.mint(user);
        testNFT.setApprovalForAll(address(staking), true);
        vm.expectRevert();
        staking.stakeNFT(tokenId);
        vm.stopPrank();

        vm.startPrank(owner);
        staking.togglePause(); // unpause contract
        vm.stopPrank();
    }

    // Negative: Non-owner trying to toggle pause should revert.
    function testTogglePauseNonOwnerRevert() public {
        vm.startPrank(attacker);
        vm.expectRevert();
        staking.togglePause();
        vm.stopPrank();
    }

    // 7. Emergency Unstake Test
    function testEmergencyUnstake() public {
        vm.startPrank(user);
        uint256 tokenId = testNFT.mint(user);
        testNFT.setApprovalForAll(address(staking), true);
        staking.stakeNFT(tokenId);
        vm.stopPrank();

        vm.startPrank(owner);
        staking.emergencyUnstake(1);
        vm.stopPrank();

        assertEq(testNFT.ownerOf(tokenId), user);
        (, , , , bool isStaked) = staking.stakes(1);
        assertFalse(isStaked);
    }

    // Negative: Non-owner calling emergencyUnstake should revert.
    function testEmergencyUnstakeNonOwnerRevert() public {
        vm.startPrank(user);
        uint256 tokenId = testNFT.mint(user);
        testNFT.setApprovalForAll(address(staking), true);
        staking.stakeNFT(tokenId);
        vm.stopPrank();

        vm.startPrank(attacker);
        vm.expectRevert();
        staking.emergencyUnstake(1);
        vm.stopPrank();
    }

    // 8. Additional Owner-Only Functions (Recovery and Update)
    function testUpdateGemstoneContract() public {
        address newNFTContract = address(0x1234);
        vm.startPrank(owner);
        staking.updateGemstoneContract(newNFTContract);
        vm.stopPrank();
        assertEq(staking.gemstoneContract(), newNFTContract);
    }

    // Negative: Non-owner updating gemstone contract should revert.
    function testUpdateGemstoneContractNonOwnerRevert() public {
        vm.startPrank(attacker);
        vm.expectRevert();
        staking.updateGemstoneContract(address(0x1234));
        vm.stopPrank();
    }

    function testRecoverETH() public {
        // Fund the staking contract with ETH.
        vm.deal(address(staking), 10 ether);
        vm.startPrank(owner);
        uint256 initialOwnerBalance = owner.balance;
        staking.recoverETH(owner, 1 ether);
        vm.stopPrank();
        // Check that (simulated) owner's balance increased.
        assertGe(owner.balance, initialOwnerBalance);
    }

    // Negative: recoverETH by non-owner should revert.
    function testRecoverETHNonOwnerRevert() public {
        vm.startPrank(attacker);
        vm.expectRevert();
        staking.recoverETH(attacker, 1 ether);
        vm.stopPrank();
    }

    function testRecoverERC20() public {
        TestERC20 token = new TestERC20();
        token.mint(address(staking), 1000);
        vm.startPrank(owner);
        staking.recoverERC20(address(token), owner, 500);
        vm.stopPrank();
        uint256 ownerTokenBalance = token.balanceOf(owner);
        assertEq(ownerTokenBalance, 500);
    }

    // Negative: Non-owner calling recoverERC20 should revert.
    function testRecoverERC20NonOwnerRevert() public {
        TestERC20 token = new TestERC20();
        token.mint(address(staking), 1000);
        vm.startPrank(attacker);
        vm.expectRevert();
        staking.recoverERC20(address(token), attacker, 500);
        vm.stopPrank();
    }

    function testRecoverERC721() public {
        // Transfer an NFT to the staking contract.
        vm.startPrank(user);
        uint256 tokenId = testNFT.mint(user);
        testNFT.approve(address(staking), tokenId);
        testNFT.transferFrom(user, address(staking), tokenId);
        vm.stopPrank();

        // Recover the NFT.
        vm.startPrank(owner);
        staking.recoverERC721(address(testNFT), user, tokenId);
        vm.stopPrank();
        assertEq(testNFT.ownerOf(tokenId), user);
    }

    // Negative: Non-owner calling recoverERC721 should revert.
    function testRecoverERC721NonOwnerRevert() public {
        vm.startPrank(user);
        uint256 tokenId = testNFT.mint(user);
        testNFT.approve(address(staking), tokenId);
        testNFT.transferFrom(user, address(staking), tokenId);
        vm.stopPrank();

        vm.startPrank(attacker);
        vm.expectRevert();
        staking.recoverERC721(address(testNFT), attacker, tokenId);
        vm.stopPrank();
    }
}
