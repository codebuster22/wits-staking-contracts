# NFT Staking Smart Contract Technical Documentation

## Overview
This smart contract enables users to stake their NFTs for a specified duration and earn rewards. The contract supports multiple NFT collections and staking durations, with administrative controls for managing the staking ecosystem.

## Deployments:
1. Find the contract deployments in `deployments.json`
2. Indexer is deployed on railway. Indexer can be accessed at: https://abs-indexer-testnet-production.up.railway.app/
3. Find the ABIs in `exports/WitsStaking.json`.
4. Use viem to fetch erc721abi.

## Deployment

### Prerequisites
1. Install [Foundry](https://book.getfoundry.sh/getting-started/installation)
2. Clone this repository
3. Install dependencies: `forge install`

### Environment Setup
1. Copy the example environment file:
```bash
cp .env.example .env
```

2. Update the `.env` file with your configuration:
```env
# Required
OWNER=<address>              # Address that will be the owner of the contract
RPC_URL=<rpc-url>           # RPC URL of the network to deploy to
PRIVATE_KEY=<private-key>   # Private key of the deployer wallet

# Optional - Required only for contract verification
ETHERSCAN_API_KEY=<key>     # API key for Etherscan verification
```

### Deployment Commands

1. Deploy without verification:
```bash
forge script script/WitsStaking.s.sol:WitsStakingScript --zksync \
    --rpc-url ${RPC_URL} \
    --private-key ${PRIVATE_KEY} \
    --broadcast
```

```bash
# Deploy the paymaster
forge script script/WitsPaymaster.s.sol:WitsPaymasterScript --zksync \
    --rpc-url $RPC_URL \
    --private-key ${PRIVATE_KEY} \
    --broadcast
```

2. Deploy and verify on Etherscan:
```bash
forge script script/WitsStaking.s.sol:WitsStakingScript --zksync \
    --rpc-url ${RPC_URL} \
    --private-key ${PRIVATE_KEY} \
    --broadcast \
    --verify \
    --verifier zksync \
    --verifier-url https://api-explorer-verify.testnet.abs.xyz/contract_verification

```

```bash
# Deploy the paymaster
forge script script/WitsPaymaster.s.sol:WitsPaymasterScript --zksync \
    --rpc-url $RPC_URL \
    --private-key ${PRIVATE_KEY} \
    --broadcast \
    --verify \
    --verifier zksync \
    --verifier-url https://api-explorer-verify.testnet.abs.xyz/contract_verification
```

3. Deploy and verify on Sourcify:
```bash
forge script script/WitsStaking.s.sol:WitsStakingScript \
    --rpc-url ${RPC_URL} \
    --private-key ${PRIVATE_KEY} \
    --broadcast \
    --verify \
    --verifier sourcify
```

### Post Deployment Steps

#### Option 1: Using Individual Admin Scripts
After deployment, you can use individual scripts for each admin function. Update your `.env` file with the required variables for the function you want to execute:

1. Add Staking Duration:
```bash
# Set DURATION in .env
forge script script/WitsStakingAdminFunctions.s.sol:AddStakingDuration \
    --rpc-url ${RPC_URL} \
    --private-key ${PRIVATE_KEY} \
    --broadcast
```

2. Remove Staking Duration:
```bash
# Set DURATION in .env
forge script script/WitsStakingAdminFunctions.s.sol:RemoveStakingDuration \
    --rpc-url ${RPC_URL} \
    --private-key ${PRIVATE_KEY} \
    --broadcast
```

3. Add NFT Contract:
```bash
# Set NFT_CONTRACT in .env
forge script script/WitsStakingAdminFunctions.s.sol:AddNFTContract \
    --rpc-url ${RPC_URL} \
    --private-key ${PRIVATE_KEY} \
    --broadcast
```

4. Remove NFT Contract:
```bash
# Set NFT_CONTRACT in .env
forge script script/WitsStakingAdminFunctions.s.sol:RemoveNFTContract \
    --rpc-url ${RPC_URL} \
    --private-key ${PRIVATE_KEY} \
    --broadcast
```

5. Toggle Pause State:
```bash
forge script script/WitsStakingAdminFunctions.s.sol:PauseContract \
    --rpc-url ${RPC_URL} \
    --private-key ${PRIVATE_KEY} \
    --broadcast
```

6. Recover ETH:
```bash
# Set RECIPIENT and AMOUNT in .env
forge script script/WitsStakingAdminFunctions.s.sol:RecoverETH \
    --rpc-url ${RPC_URL} \
    --private-key ${PRIVATE_KEY} \
    --broadcast
```

7. Recover ERC20:
```bash
# Set TOKEN_ADDRESS, RECIPIENT, and AMOUNT in .env
forge script script/WitsStakingAdminFunctions.s.sol:RecoverERC20 \
    --rpc-url ${RPC_URL} \
    --private-key ${PRIVATE_KEY} \
    --broadcast
```

8. Recover ERC721:
```bash
# Set TOKEN_ADDRESS, RECIPIENT, and TOKEN_ID in .env
forge script script/WitsStakingAdminFunctions.s.sol:RecoverERC721 \
    --rpc-url ${RPC_URL} \
    --private-key ${PRIVATE_KEY} \
    --broadcast
```

```bash
# Deposit
forge script script/WitsPaymaster.s.sol:WitsPaymasterAdminScript --zksync \
    --sig "deposit()" \
    --rpc-url $RPC_URL \
    --private-key ${PRIVATE_KEY} \
    --broadcast \
    -vvvv

# Withdraw
forge script script/WitsPaymaster.s.sol:WitsPaymasterAdminScript --zksync \
    --sig "withdraw()" \
    --rpc-url $RPC_URL \
    --private-key ${PRIVATE_KEY} \
    --broadcast \
    -vvvv

# Add target contract
forge script script/WitsPaymaster.s.sol:WitsPaymasterAdminScript --zksync \
    --sig "addTarget()" \
    --rpc-url $RPC_URL \
    --private-key ${PRIVATE_KEY} \
    --broadcast \
    -vvvv

# Remove target contract
forge script script/WitsPaymaster.s.sol:WitsPaymasterAdminScript --zksync \
    --sig "removeTarget()" \
    --rpc-url $RPC_URL \
    --private-key ${PRIVATE_KEY} \
    --broadcast \
    -vvvv
```

#### Option 2: Using Bulk Setup Script
For initial setup, you can use the bulk script to configure multiple settings at once. Update your `.env` file with:
1. `STAKING_ADDRESS`: The address of your deployed WitsStaking contract
2. `NFT_ADDRESSES`: Comma-separated list of NFT contract addresses to whitelist
3. `STAKING_DURATIONS`: Comma-separated list of staking durations in seconds

Then run:
```bash
forge script script/WitsStakingAdmin.s.sol:WitsStakingAdmin \
    --rpc-url ${RPC_URL} \
    --private-key ${PRIVATE_KEY} \
    --broadcast
```

#### Option 3: Manual Setup
Alternatively, you can manually call the contract functions using your preferred method (e.g., etherscan, hardhat console, etc.):
1. Add allowed staking durations using `addStakingDuration`
2. Whitelist NFT contracts using `whitelistNFTContract`
3. Verify the contract is not paused using `paused`

## Admin Functions

After deploying the WitsStaking contract, you can use the following scripts to perform administrative functions. Each script requires specific environment variables to be set in your `.env` file.

### Common Environment Variables
All admin scripts require these base variables:
```
STAKING_ADDRESS=<deployed_contract_address>
OWNER=<admin_wallet_address>
RPC_URL=<network_rpc_url>
PRIVATE_KEY=<admin_private_key>
```

### Add Staking Duration
Adds a new valid staking duration to the contract.

Required Environment Variable:
```
DURATION=<duration_in_seconds>
```

Example:
```bash
# Add 30 days staking duration
forge script script/WitsStakingAdminFunctions.s.sol:AddStakingDuration --rpc-url $RPC_URL --broadcast
```

### Remove Staking Duration
Removes a staking duration from the valid durations list.

Required Environment Variable:
```
DURATION=<duration_in_seconds>
```

Example:
```bash
forge script script/WitsStakingAdminFunctions.s.sol:RemoveStakingDuration --rpc-url $RPC_URL --broadcast
```

### Add NFT Contract
Whitelists a new NFT contract for staking.

Required Environment Variable:
```
NFT_CONTRACT=<nft_contract_address>
```

Example:
```bash
forge script script/WitsStakingAdminFunctions.s.sol:AddNFTContract --rpc-url $RPC_URL --broadcast
```

### Remove NFT Contract
Removes an NFT contract from the whitelist.

Required Environment Variable:
```
NFT_CONTRACT=<nft_contract_address>
```

Example:
```bash
forge script script/WitsStakingAdminFunctions.s.sol:RemoveNFTContract --rpc-url $RPC_URL --broadcast
```

### Pause/Unpause Contract
Toggles the pause state of the contract. Running it when paused will unpause, and vice versa.

Example:
```bash
forge script script/WitsStakingAdminFunctions.s.sol:PauseContract --rpc-url $RPC_URL --broadcast
```

### Recover ETH
Recovers ETH accidentally sent to the contract.

Required Environment Variables:
```
RECIPIENT=<recipient_address>
AMOUNT=<amount_in_wei>
```

Example:
```bash
forge script script/WitsStakingAdminFunctions.s.sol:RecoverETH --rpc-url $RPC_URL --broadcast
```

### Recover ERC20 Tokens
Recovers ERC20 tokens accidentally sent to the contract.

Required Environment Variables:
```
TOKEN_ADDRESS=<token_contract_address>
RECIPIENT=<recipient_address>
AMOUNT=<amount_in_token_decimals>
```

Example:
```bash
forge script script/WitsStakingAdminFunctions.s.sol:RecoverERC20 --rpc-url $RPC_URL --broadcast
```

### Recover ERC721 Tokens
Recovers NFTs accidentally sent to the contract.

Required Environment Variables:
```
TOKEN_ADDRESS=<nft_contract_address>
RECIPIENT=<recipient_address>
TOKEN_ID=<nft_token_id>
```

Example:
```bash
forge script script/WitsStakingAdminFunctions.s.sol:RecoverERC721 --rpc-url $RPC_URL --broadcast
```

### Important Notes
1. All scripts require the caller to be the contract owner.
2. Make sure to verify all environment variables before running scripts.
3. For safety, test scripts on a testnet before using on mainnet.
4. Keep your private key secure and never commit it to version control.

## Contract Architecture

### State Variables
```solidity
/// @notice Mapping of NFT contract address to their whitelist status
mapping(address => bool) public whitelistedNFTs;

/// @notice Mapping of available staking durations (in seconds) to their status
mapping(uint256 => bool) public stakingDurations;

/// @notice Mapping of token ID to its stake information for each NFT contract
mapping(address => mapping(uint256 => StakeInfo)) public stakes;

/// @notice Contract pause status
bool public paused;

/// @notice Contract owner/admin address
address public owner;

/// @notice Minimum staking duration
uint256 public constant MIN_STAKE_DURATION = 1 hours;

/// @notice Maximum staking duration
uint256 public constant MAX_STAKE_DURATION = 365 days;
```

### Structs
```solidity
struct StakeInfo {
    address staker;           // Address of the NFT staker
    uint256 startTime;        // Timestamp when staking started
    uint256 endTime;          // Timestamp when staking ends
    bool isStaked;           // Current stake status
    uint256 stakeDuration;   // Duration selected for staking
}
```

### Events
```solidity
/// @notice Emitted when a new NFT contract is whitelisted
event NFTContractWhitelisted(address indexed nftContract);

/// @notice Emitted when an NFT contract is removed from whitelist
event NFTContractRemoved(address indexed nftContract);

/// @notice Emitted when a new staking duration is added
event StakingDurationAdded(uint256 duration);

/// @notice Emitted when a staking duration is removed
event StakingDurationRemoved(uint256 duration);

/// @notice Emitted when an NFT is staked
event NFTStaked(address indexed nftContract, uint256 indexed tokenId, address indexed staker, uint256 duration);

/// @notice Emitted when an NFT is unstaked
event NFTUnstaked(address indexed nftContract, uint256 indexed tokenId, address indexed staker);

/// @notice Emitted when contract is paused/unpaused
event ContractPauseToggled(bool isPaused);

/// @notice Emitted when stuck tokens are recovered
event TokensRecovered(address indexed token, address indexed recipient, uint256 amount);
```

### Custom Errors
```solidity
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
```

### Modifiers
```solidity
/// @notice Ensures caller is contract owner
modifier onlyOwner();

/// @notice Ensures contract is not paused
modifier whenNotPaused();

/// @notice Ensures NFT contract is whitelisted
modifier onlyWhitelistedNFT(address nftContract);

/// @notice Validates staking duration
modifier validStakingDuration(uint256 duration);
```

## Functions

### Administrative Functions

#### setOwner
```solidity
function setOwner(address newOwner) external onlyOwner
```
Updates contract owner address.
- Requirements:
  - Caller must be current owner
  - New owner address must not be zero
- Emits `OwnershipTransferred` event

#### togglePause
```solidity
function togglePause() external onlyOwner
```
Toggles contract pause status.
- Requirements:
  - Caller must be owner
- Emits `ContractPauseToggled` event

#### whitelistNFTContract
```solidity
function whitelistNFTContract(address nftContract) external onlyOwner
```
Adds NFT contract to whitelist.
- Requirements:
  - Caller must be owner
  - Contract must implement ERC721 interface
  - Contract must not be zero address
- Emits `NFTContractWhitelisted` event

#### removeNFTContract
```solidity
function removeNFTContract(address nftContract) external onlyOwner
```
Removes NFT contract from whitelist.
- Requirements:
  - Caller must be owner
  - Contract must be whitelisted
- Emits `NFTContractRemoved` event

#### addStakingDuration
```solidity
function addStakingDuration(uint256 duration) external onlyOwner
```
Adds new staking duration option.
- Requirements:
  - Caller must be owner
  - Duration must be between MIN_STAKE_DURATION and MAX_STAKE_DURATION
- Emits `StakingDurationAdded` event

#### removeStakingDuration
```solidity
function removeStakingDuration(uint256 duration) external onlyOwner
```
Removes staking duration option.
- Requirements:
  - Caller must be owner
  - Duration must exist
- Emits `StakingDurationRemoved` event

#### recoverTokens
```solidity
function recoverTokens(
    address token,
    address recipient,
    uint256 amount
) external onlyOwner
```
Recovers stuck tokens (ERC20/ERC721/ERC1155).
- Requirements:
  - Caller must be owner
  - Token must not be staked
  - Recipient must not be zero address
- Emits `TokensRecovered` event

### User Functions

#### stakeNFT
```solidity
function stakeNFT(
    address nftContract,
    uint256 tokenId,
    uint256 duration
) external whenNotPaused onlyWhitelistedNFT(nftContract) validStakingDuration(duration)
```
Stakes an NFT for specified duration.
- Requirements:
  - Contract must not be paused
  - NFT contract must be whitelisted
  - Duration must be valid
  - Caller must own the NFT
  - NFT must not be already staked
- Emits `NFTStaked` event

#### batchStakeNFTs
```solidity
function batchStakeNFTs(
    address nftContract,
    uint256[] calldata tokenIds,
    uint256 duration
) external whenNotPaused onlyWhitelistedNFT(nftContract) validStakingDuration(duration)
```
Stakes multiple NFTs in single transaction.
- Requirements:
  - Same as stakeNFT for each token
- Emits multiple `NFTStaked` events

#### unstakeNFT
```solidity
function unstakeNFT(
    address nftContract,
    uint256 tokenId
) external
```
Unstakes an NFT after lock period.
- Requirements:
  - Stake must exist
  - Caller must be stake owner
  - Lock period must be over
- Emits `NFTUnstaked` event

#### batchUnstakeNFTs
```solidity
function batchUnstakeNFTs(
    address nftContract,
    uint256[] calldata tokenIds
) external
```
Unstakes multiple NFTs in single transaction.
- Requirements:
  - Same as unstakeNFT for each token
- Emits multiple `NFTUnstaked` events

#### emergencyUnstake
```solidity
function emergencyUnstake(
    address nftContract,
    uint256 tokenId
) external onlyOwner
```
Emergency unstake function for admin.
- Requirements:
  - Caller must be owner
  - Stake must exist
- Emits `NFTUnstaked` event

### View Functions

#### getStakeInfo
```solidity
function getStakeInfo(
    address nftContract,
    uint256 tokenId
) external view returns (StakeInfo memory)
```
Returns stake information for given NFT.

#### isStakingDurationValid
```solidity
function isStakingDurationValid(uint256 duration) external view returns (bool)
```
Checks if staking duration is valid.

#### isNFTStaked
```solidity
function isNFTStaked(
    address nftContract,
    uint256 tokenId
) external view returns (bool)
```
Checks if NFT is currently staked.

## Security Considerations

1. **Access Control**
   - Owner-only functions protected by `onlyOwner` modifier
   - Clear separation between admin and user functions

2. **Reentrancy Protection**
   - All state changes before external calls
   - Use of OpenZeppelin's ReentrancyGuard

3. **Input Validation**
   - Comprehensive checks for zero addresses
   - Validation of staking durations
   - Whitelist verification for NFT contracts

4. **Emergency Measures**
   - Pause functionality for new stakes
   - Emergency unstake for admin
   - Token recovery for stuck assets

5. **Gas Optimization**
   - Batch functions for multiple NFTs
   - Efficient use of storage slots
   - Minimal storage reads and writes

## Dependencies
- OpenZeppelin Contracts v4.9.0
  - `@openzeppelin/contracts/token/ERC721/IERC721.sol`
  - `@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol`
  - `@openzeppelin/contracts/security/ReentrancyGuard.sol`
  - `@openzeppelin/contracts/security/Pausable.sol`
  - `@openzeppelin/contracts/access/Ownable.sol`
