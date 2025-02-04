// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title GemstoneStaking
 * @notice A contract for staking NFTs with configurable durations
 * @dev Implements NFT staking functionality with admin controls and emergency features
 */
contract GemstoneStaking is Ownable, Pausable, ReentrancyGuard, IERC721Receiver {
    /* ========== STATE VARIABLES ========== */

    /// @notice Mapping of NFT contract address to their whitelist status
    address public gemstoneContract;

    /// @notice Mapping of stake ID to stake information
    mapping(uint256 => StakeInfo) public stakes;

    /// @notice Counter for generating unique stake IDs
    uint256 private seasonId;

    uint256 public nextStakeId;

    /* ========== STRUCTS ========== */

    struct StakeInfo {
        uint256 tokenId;        // ID of the staked NFT
        address staker;         // Address of the NFT staker
        uint256 startTime;      // Timestamp when staking started
        uint256 stakeSeasonId; // ID of the stake season
        bool isStaked;         // Current stake status
    }

    /* ========== EVENTS ========== */

    event GemstoneContractUpdated(address indexed nftContract);
    event NFTStaked(uint256 indexed tokenId, address indexed staker, uint256 seasonId, uint256 stakeId);
    event NFTUnstaked(uint256 indexed tokenId, address indexed staker, uint256 stakeId);
    event ContractPauseToggled(bool isPaused);
    event EthRecovered(address indexed recipient, uint256 amount);
    event ERC20TokensRecovered(address indexed token, address indexed recipient, uint256 amount);
    event ERC721TokensRecovered(address indexed token, address indexed recipient, uint256 tokenId);
    event NextSeasonStarted(uint256 seasonId);

    /* ========== ERRORS ========== */

    error ContractPaused();
    error NotOwnerOrStakingAlreadyExists();
    error StakeNotFound();
    error StakeStillLocked();
    error StakeAlreadyExists();
    error ZeroAddress();
    error UnauthorizedCaller();
    error InvalidTokenAmount();

    /* ========== CONSTRUCTOR ========== */

    constructor(address initialOwner, address initialGemstoneContract) Ownable(initialOwner) {
        nextStakeId = 1;
        seasonId = 1;
        gemstoneContract = initialGemstoneContract;
        emit NextSeasonStarted(1);
    }

    /* ========== ADMIN FUNCTIONS ========== */

    /// @notice Toggles the contract's pause state
    function togglePause() external onlyOwner {
        if (paused()) {
            _unpause();
        } else {
            _pause();
        }
        emit ContractPauseToggled(paused());
    }

    /// @notice Adds an NFT contract to the whitelist
    /// @param nftContract The address of the NFT contract to whitelist
    function updateGemstoneContract(address nftContract) external onlyOwner {
        if (nftContract == address(0)) revert ZeroAddress();
        gemstoneContract = nftContract;
        emit GemstoneContractUpdated(nftContract);
    }

    /// @notice Start new season of staking
    function startNewSeason() external onlyOwner {
        seasonId++;
        emit NextSeasonStarted(seasonId);
    }

    /// @notice Recovers stuck ETH from the contract
    /// @param recipient The address to receive the ETH
    /// @param amount The amount of ETH to recover
    function recoverETH(
        address recipient,
        uint256 amount
    ) external onlyOwner {
        if (recipient == address(0)) revert ZeroAddress();
        if (amount == 0) revert InvalidTokenAmount();
        if (amount > address(this).balance) revert InvalidTokenAmount();

        (bool success,) = recipient.call{value: amount}("");
        if (!success) revert();

        emit EthRecovered(recipient, amount);
    }

    /// @notice Recovers stuck ERC20 tokens from the contract
    /// @param token The ERC20 token contract address
    /// @param recipient The address to receive the tokens
    /// @param amount The amount of tokens to recover
    function recoverERC20(
        address token,
        address recipient,
        uint256 amount
    ) external onlyOwner {
        if (recipient == address(0)) revert ZeroAddress();
        if (amount == 0) revert InvalidTokenAmount();

        IERC20(token).transfer(recipient, amount);
        emit ERC20TokensRecovered(token, recipient, amount);
    }

    /// @notice Recovers stuck ERC721 tokens from the contract
    /// @param token The ERC721 token contract address
    /// @param recipient The address to receive the token
    /// @param tokenId The ID of the token to recover
    function recoverERC721(
        address token,
        address recipient,
        uint256 tokenId
    ) external onlyOwner {
        if (recipient == address(0)) revert ZeroAddress();

        IERC721(token).transferFrom(address(this), recipient, tokenId);
        emit ERC721TokensRecovered(token, recipient, tokenId);
    }

    /// @notice Emergency unstake function for admin
    /// @param stakeId The ID of the stake to unstake
    function emergencyUnstake(uint256 stakeId) external onlyOwner {
        StakeInfo storage stake = stakes[stakeId];
        if (!stake.isStaked) revert StakeNotFound();

        stake.isStaked = false;
        IERC721(gemstoneContract).transferFrom(address(this), stake.staker, stake.tokenId);

        emit NFTUnstaked(stake.tokenId, stake.staker, stakeId);
    }

    /* ========== USER FUNCTIONS ========== */

    /// @notice Stakes an NFT for a specified duration
    /// @param tokenId The token ID to stake
    function stakeNFT(
        uint256 tokenId
    ) external whenNotPaused nonReentrant {
        if (IERC721(gemstoneContract).ownerOf(tokenId) != msg.sender) revert NotOwnerOrStakingAlreadyExists();

        uint256 stakeId = nextStakeId++;

        stakes[stakeId] = StakeInfo({
            tokenId: tokenId,
            staker: msg.sender,
            startTime: block.timestamp,
            stakeSeasonId: seasonId,
            isStaked: true
        });

        IERC721(gemstoneContract).transferFrom(msg.sender, address(this), tokenId);
        emit NFTStaked(tokenId, msg.sender, seasonId, stakeId);
    }

    /// @notice Stakes multiple NFTs in a single transaction
    /// @param nftContract The NFT contract address
    /// @param tokenIds Array of token IDs to stake
    /// @param duration The staking duration in seconds
    function batchStakeNFTs(
        address nftContract,
        uint256[] calldata tokenIds,
        uint256 duration
    ) external whenNotPaused nonReentrant {
        uint256 length = tokenIds.length;
        for (uint256 i = 0; i < length;) {
            uint256 tokenId = tokenIds[i];
            if (IERC721(gemstoneContract).ownerOf(tokenId) != msg.sender) revert NotOwnerOrStakingAlreadyExists();

            uint256 stakeId = nextStakeId++;

            stakes[stakeId] = StakeInfo({
                tokenId: tokenId,
                staker: msg.sender,
                startTime: block.timestamp,
                stakeSeasonId: seasonId,
                isStaked: true
            });

            IERC721(gemstoneContract).transferFrom(msg.sender, address(this), tokenId);
            emit NFTStaked(tokenId, msg.sender, seasonId, stakeId);

            unchecked { ++i; }
        }
    }

    /// @notice Unstakes an NFT after the lock period
    /// @param stakeId The ID of the stake to unstake
    function unstakeNFT(uint256 stakeId) external nonReentrant {        
        StakeInfo storage stake = stakes[stakeId];
        if (!stake.isStaked) revert StakeNotFound();
        if (stake.staker != msg.sender) revert UnauthorizedCaller();
        if (seasonId <= stake.stakeSeasonId) revert StakeStillLocked();

        stake.isStaked = false;
        IERC721(gemstoneContract).transferFrom(address(this), msg.sender, stake.tokenId);

        emit NFTUnstaked(stake.tokenId, msg.sender, stakeId);
    }

    /// @notice Unstakes multiple NFTs in a single transaction
    /// @param stakeIds Array of stake IDs to unstake
    function batchUnstakeNFTs(uint256[] calldata stakeIds) external nonReentrant {
        uint256 length = stakeIds.length;
        for (uint256 i = 0; i < length;) {
            uint256 stakeId = stakeIds[i];
            StakeInfo storage stake = stakes[stakeId];
            
            if (!stake.isStaked) revert StakeNotFound();
            if (stake.staker != msg.sender) revert UnauthorizedCaller();
            if (seasonId <= stake.stakeSeasonId) revert StakeStillLocked();

            stake.isStaked = false;
            IERC721(gemstoneContract).transferFrom(address(this), msg.sender, stake.tokenId);

            emit NFTUnstaked(stake.tokenId, msg.sender, stakeId);

            unchecked { ++i; }
        }
    }

    /* ========== VIEW FUNCTIONS ========== */

    /// @notice Returns stake information for a given stake ID
    /// @param stakeId The stake ID to query
    function getStakeInfo(uint256 stakeId) external view returns (StakeInfo memory) {
        return stakes[stakeId];
    }

    /// @notice Checks if an NFT is currently staked
    /// @param stakeId The stake ID to check
    function isNFTStaked(
        uint256 stakeId
    ) external view returns (bool) {
        StakeInfo storage stake = stakes[stakeId];
        return stake.isStaked;
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    /// @notice Required for IERC721Receiver
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}
