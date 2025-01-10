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
 * @title WitsStaking
 * @notice A contract for staking NFTs with configurable durations
 * @dev Implements NFT staking functionality with admin controls and emergency features
 */
contract WitsStaking is Ownable, Pausable, ReentrancyGuard, IERC721Receiver {
    /* ========== STATE VARIABLES ========== */

    /// @notice Mapping of NFT contract address to their whitelist status
    mapping(address => bool) public whitelistedNFTs;

    /// @notice Mapping of available staking durations (in seconds) to their status
    mapping(uint256 => bool) public stakingDurations;

    /// @notice Mapping of token ID to its stake information for each NFT contract
    mapping(address => mapping(uint256 => StakeInfo)) public stakes;

    /// @notice Minimum staking duration
    uint256 public constant MIN_STAKE_DURATION = 1 hours;

    /// @notice Maximum staking duration
    uint256 public constant MAX_STAKE_DURATION = 365 days;

    /* ========== STRUCTS ========== */

    struct StakeInfo {
        address staker;           // Address of the NFT staker
        uint256 startTime;        // Timestamp when staking started
        uint256 endTime;          // Timestamp when staking ends
        bool isStaked;           // Current stake status
        uint256 stakeDuration;   // Duration selected for staking
    }

    /* ========== EVENTS ========== */

    event NFTContractWhitelisted(address indexed nftContract);
    event NFTContractRemoved(address indexed nftContract);
    event StakingDurationAdded(uint256 duration);
    event StakingDurationRemoved(uint256 duration);
    event NFTStaked(address indexed nftContract, uint256 indexed tokenId, address indexed staker, uint256 duration);
    event NFTUnstaked(address indexed nftContract, uint256 indexed tokenId, address indexed staker);
    event ContractPauseToggled(bool isPaused);
    event TokensRecovered(address indexed token, address indexed recipient, uint256 amount);

    /* ========== ERRORS ========== */

    error InvalidNFTContract();
    error NFTNotWhitelisted();
    error InvalidStakingDuration();
    error ContractPaused();
    error NotTokenOwner();
    error StakeNotFound();
    error StakeStillLocked();
    error StakeAlreadyExists();
    error ZeroAddress();
    error UnauthorizedCaller();
    error InvalidTokenAmount();

    /* ========== CONSTRUCTOR ========== */

    constructor(address initialOwner) Ownable(initialOwner) {}

    /* ========== MODIFIERS ========== */

    /// @notice Ensures NFT contract is whitelisted
    modifier onlyWhitelistedNFT(address nftContract) {
        if (!whitelistedNFTs[nftContract]) revert NFTNotWhitelisted();
        _;
    }

    /// @notice Validates staking duration
    modifier validStakingDuration(uint256 duration) {
        if (!stakingDurations[duration]) revert InvalidStakingDuration();
        _;
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
    function whitelistNFTContract(address nftContract) external onlyOwner {
        if (nftContract == address(0)) revert ZeroAddress();
        whitelistedNFTs[nftContract] = true;
        emit NFTContractWhitelisted(nftContract);
    }

    /// @notice Removes an NFT contract from the whitelist
    /// @param nftContract The address of the NFT contract to remove
    function removeNFTContract(address nftContract) external onlyOwner {
        if (!whitelistedNFTs[nftContract]) revert NFTNotWhitelisted();
        whitelistedNFTs[nftContract] = false;
        emit NFTContractRemoved(nftContract);
    }

    /// @notice Adds a new staking duration option
    /// @param duration The duration to add in seconds
    function addStakingDuration(uint256 duration) external onlyOwner {
        if (duration < MIN_STAKE_DURATION || duration > MAX_STAKE_DURATION) revert InvalidStakingDuration();
        stakingDurations[duration] = true;
        emit StakingDurationAdded(duration);
    }

    /// @notice Removes a staking duration option
    /// @param duration The duration to remove
    function removeStakingDuration(uint256 duration) external onlyOwner {
        if (!stakingDurations[duration]) revert InvalidStakingDuration();
        stakingDurations[duration] = false;
        emit StakingDurationRemoved(duration);
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

        emit TokensRecovered(address(0), recipient, amount);
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
        emit TokensRecovered(token, recipient, amount);
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
        emit TokensRecovered(token, recipient, tokenId);
    }

    /// @notice Emergency unstake function for admin
    /// @param nftContract The NFT contract address
    /// @param tokenId The token ID to unstake
    function emergencyUnstake(
        address nftContract,
        uint256 tokenId
    ) external onlyOwner {
        StakeInfo storage stake = stakes[nftContract][tokenId];
        if (!stake.isStaked) revert StakeNotFound();

        stake.isStaked = false;
        IERC721(nftContract).transferFrom(address(this), stake.staker, tokenId);

        emit NFTUnstaked(nftContract, tokenId, stake.staker);
    }

    /* ========== USER FUNCTIONS ========== */

    /// @notice Stakes an NFT for a specified duration
    /// @param nftContract The NFT contract address
    /// @param tokenId The token ID to stake
    /// @param duration The staking duration in seconds
    function stakeNFT(
        address nftContract,
        uint256 tokenId,
        uint256 duration
    ) external whenNotPaused onlyWhitelistedNFT(nftContract) validStakingDuration(duration) nonReentrant {
        if (stakes[nftContract][tokenId].isStaked) revert StakeAlreadyExists();
        if (IERC721(nftContract).ownerOf(tokenId) != msg.sender) revert NotTokenOwner();

        stakes[nftContract][tokenId] = StakeInfo({
            staker: msg.sender,
            startTime: block.timestamp,
            endTime: block.timestamp + duration,
            isStaked: true,
            stakeDuration: duration
        });

        IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);
        emit NFTStaked(nftContract, tokenId, msg.sender, duration);
    }

    /// @notice Stakes multiple NFTs in a single transaction
    /// @param nftContract The NFT contract address
    /// @param tokenIds Array of token IDs to stake
    /// @param duration The staking duration in seconds
    function batchStakeNFTs(
        address nftContract,
        uint256[] calldata tokenIds,
        uint256 duration
    ) external whenNotPaused onlyWhitelistedNFT(nftContract) validStakingDuration(duration) nonReentrant {
        uint256 length = tokenIds.length;
        for (uint256 i = 0; i < length;) {
            uint256 tokenId = tokenIds[i];
            if (stakes[nftContract][tokenId].isStaked) revert StakeAlreadyExists();
            if (IERC721(nftContract).ownerOf(tokenId) != msg.sender) revert NotTokenOwner();

            stakes[nftContract][tokenId] = StakeInfo({
                staker: msg.sender,
                startTime: block.timestamp,
                endTime: block.timestamp + duration,
                isStaked: true,
                stakeDuration: duration
            });

            IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);
            emit NFTStaked(nftContract, tokenId, msg.sender, duration);

            unchecked { ++i; }
        }
    }

    /// @notice Unstakes an NFT after the lock period
    /// @param nftContract The NFT contract address
    /// @param tokenId The token ID to unstake
    function unstakeNFT(
        address nftContract,
        uint256 tokenId
    ) external nonReentrant {
        StakeInfo storage stake = stakes[nftContract][tokenId];
        if (!stake.isStaked) revert StakeNotFound();
        if (stake.staker != msg.sender) revert UnauthorizedCaller();
        if (block.timestamp < stake.endTime) revert StakeStillLocked();

        stake.isStaked = false;
        IERC721(nftContract).transferFrom(address(this), msg.sender, tokenId);

        emit NFTUnstaked(nftContract, tokenId, msg.sender);
    }

    /// @notice Unstakes multiple NFTs in a single transaction
    /// @param nftContract The NFT contract address
    /// @param tokenIds Array of token IDs to unstake
    function batchUnstakeNFTs(
        address nftContract,
        uint256[] calldata tokenIds
    ) external nonReentrant {
        uint256 length = tokenIds.length;
        for (uint256 i = 0; i < length;) {
            uint256 tokenId = tokenIds[i];
            StakeInfo storage stake = stakes[nftContract][tokenId];
            
            if (!stake.isStaked) revert StakeNotFound();
            if (stake.staker != msg.sender) revert UnauthorizedCaller();
            if (block.timestamp < stake.endTime) revert StakeStillLocked();

            stake.isStaked = false;
            IERC721(nftContract).transferFrom(address(this), msg.sender, tokenId);

            emit NFTUnstaked(nftContract, tokenId, msg.sender);

            unchecked { ++i; }
        }
    }

    /* ========== VIEW FUNCTIONS ========== */

    /// @notice Returns stake information for a given NFT
    /// @param nftContract The NFT contract address
    /// @param tokenId The token ID to query
    function getStakeInfo(
        address nftContract,
        uint256 tokenId
    ) external view returns (StakeInfo memory) {
        return stakes[nftContract][tokenId];
    }

    /// @notice Checks if a staking duration is valid
    /// @param duration The duration to check
    function isStakingDurationValid(uint256 duration) external view returns (bool) {
        return stakingDurations[duration];
    }

    /// @notice Checks if an NFT is currently staked
    /// @param nftContract The NFT contract address
    /// @param tokenId The token ID to check
    function isNFTStaked(
        address nftContract,
        uint256 tokenId
    ) external view returns (bool) {
        return stakes[nftContract][tokenId].isStaked;
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
