import { onchainTable } from "ponder";

// Main Entities representing core data

// Stores the global state of the staking contract
export const globalState = onchainTable("global_state", (t) => ({
  id: t.hex().primaryKey(), // Unique identifier for the global state
  isPaused: t.boolean().notNull(), // Whether the contract is paused
  minStakeDuration: t.bigint().notNull(), // Minimum duration allowed for staking
  maxStakeDuration: t.bigint().notNull(), // Maximum duration allowed for staking
  ownerId: t.hex().notNull(), // Address of the contract owner
}));

// Stores information about individual NFT stakes
export const stake = onchainTable("stake", (t) => ({
  id: t.hex().primaryKey(), // Unique identifier for the stake
  nftContractId: t.hex().notNull(), // Address of the NFT contract
  tokenId: t.text().notNull(), // ID of the staked NFT token
  stakerId: t.hex().notNull(), // Address of the staker
  durationId: t.hex().notNull(), // ID of the chosen stake duration
  startTime: t.bigint().notNull(), // Timestamp when stake started
  endTime: t.bigint().notNull(), // Timestamp when stake ends
  stakeDuration: t.bigint().notNull(), // Duration of the stake in seconds
  isStaked: t.boolean().notNull(), // Whether the NFT is currently staked
  stakeTxId: t.hex().notNull(), // Transaction hash of the stake
  unstakeTxId: t.hex().notNull(), // Transaction hash of the unstake
}));

// Stores user information
export const user = onchainTable("user", (t) => ({
  id: t.hex().primaryKey(), // Unique identifier for the user
  address: t.hex().notNull(), // Ethereum address of the user
}));

// Stores information about whitelisted NFT contracts
export const nftContract = onchainTable("nft_contract", (t) => ({
  id: t.hex().primaryKey(), // Unique identifier for the NFT contract
  contract: t.hex().notNull(), // Address of the NFT contract
  isWhitelisted: t.boolean().notNull(), // Whether the contract is whitelisted for staking
}));

// Stores available staking duration options
export const stakeDuration = onchainTable("stake_duration", (t) => ({
  id: t.hex().primaryKey(), // Unique identifier for the duration option
  duration: t.bigint().notNull(), // Duration in seconds
  isActive: t.boolean().notNull(), // Whether this duration option is currently active
}));


// Entities representing events and log of change in data

// Records when NFT contracts are whitelisted
export const nftContractWhitelist = onchainTable('nft_contract_whitelist', (t) => ({
  id: t.hex().primaryKey(), // Unique identifier for the whitelist event
  nftContractId: t.hex().notNull(), // Address of the whitelisted NFT contract
  blockNumber: t.bigint().notNull(), // Block number when whitelisting occurred
  blockTimestamp: t.bigint().notNull(), // Timestamp of the block
  transactionHash: t.hex().notNull(), // Transaction hash of the whitelist event
}));

// Records when NFT contracts are removed from whitelist
export const nftContractRemoval = onchainTable('nft_contract_removal', (t) => ({
  id: t.hex().primaryKey(), // Unique identifier for the removal event
  nftContractId: t.hex().notNull(), // Address of the removed NFT contract
  blockNumber: t.bigint().notNull(), // Block number when removal occurred
  blockTimestamp: t.bigint().notNull(), // Timestamp of the block
  transactionHash: t.hex().notNull(), // Transaction hash of the removal event
}));

// Records when new staking durations are added
export const stakingDurationAddition = onchainTable('staking_duration_addition', (t) => ({
  id: t.hex().primaryKey(), // Unique identifier for the duration addition event
  durationId: t.hex().notNull(), // ID of the added duration
  blockNumber: t.bigint().notNull(), // Block number when addition occurred
  blockTimestamp: t.bigint().notNull(), // Timestamp of the block
  transactionHash: t.hex().notNull(), // Transaction hash of the addition event
}));

// Records when staking durations are removed
export const stakingDurationRemoval = onchainTable('staking_duration_removal', (t) => ({
  id: t.hex().primaryKey(), // Unique identifier for the duration removal event
  durationId: t.hex().notNull(), // ID of the removed duration
  blockNumber: t.bigint().notNull(), // Block number when removal occurred
  blockTimestamp: t.bigint().notNull(), // Timestamp of the block
  transactionHash: t.hex().notNull(), // Transaction hash of the removal event
}));

// Records NFT staking events
export const nftStake = onchainTable('nft_stake', (t) => ({
  id: t.hex().primaryKey(), // Unique identifier for the stake event
  nftContractId: t.hex().notNull(), // Address of the NFT contract
  tokenId: t.text().notNull(), // ID of the staked NFT token
  stakerId: t.hex().notNull(), // Address of the staker
  durationId: t.hex().notNull(), // ID of the chosen stake duration
  blockNumber: t.bigint().notNull(), // Block number when stake occurred
  blockTimestamp: t.bigint().notNull(), // Timestamp of the block
  transactionHash: t.hex().notNull(), // Transaction hash of the stake event
}));

// Records NFT unstaking events
export const nftUnstake = onchainTable('nft_unstake', (t) => ({
  id: t.hex().primaryKey(), // Unique identifier for the unstake event
  nftContractId: t.hex().notNull(), // Address of the NFT contract
  tokenId: t.text().notNull(), // ID of the unstaked NFT token
  stakerId: t.hex().notNull(), // Address of the staker
  durationId: t.hex().notNull(), // ID of the stake duration
  blockNumber: t.bigint().notNull(), // Block number when unstake occurred
  blockTimestamp: t.bigint().notNull(), // Timestamp of the block
  transactionHash: t.hex().notNull(), // Transaction hash of the unstake event
}));

// Records contract pause/unpause events
export const contractPauseToggle = onchainTable('contract_pause_toggle', (t) => ({
  id: t.hex().primaryKey(), // Unique identifier for the pause toggle event
  isPaused: t.boolean().notNull(), // New pause state
  blockNumber: t.bigint().notNull(), // Block number when toggle occurred
  blockTimestamp: t.bigint().notNull(), // Timestamp of the block
  transactionHash: t.hex().notNull(), // Transaction hash of the toggle event
}));

// Records ETH recovery events
export const ethRecovered = onchainTable('eth_recovered', (t) => ({
  id: t.hex().primaryKey(), // Unique identifier for the ETH recovery event
  recipientId: t.hex().notNull(), // Address of the recipient
  amount: t.bigint().notNull(), // Amount of ETH recovered
  blockNumber: t.bigint().notNull(), // Block number when recovery occurred
  blockTimestamp: t.bigint().notNull(), // Timestamp of the block
  transactionHash: t.hex().notNull(), // Transaction hash of the recovery event
}));

// Records ERC20 token recovery events
export const erc20TokenRecovered = onchainTable('erc20_token_recovered', (t) => ({
  id: t.hex().primaryKey(), // Unique identifier for the ERC20 recovery event
  tokenId: t.hex().notNull(), // Address of the ERC20 token contract
  recipientId: t.hex().notNull(), // Address of the recipient
  amount: t.bigint().notNull(), // Amount of tokens recovered
  blockNumber: t.bigint().notNull(), // Block number when recovery occurred
  blockTimestamp: t.bigint().notNull(), // Timestamp of the block
  transactionHash: t.hex().notNull(), // Transaction hash of the recovery event
}));

// Records ERC721 token recovery events
export const erc721TokenRecovered = onchainTable('erc721_token_recovered', (t) => ({
  id: t.hex().primaryKey(), // Unique identifier for the ERC721 recovery event
  nftContractId: t.hex().notNull(), // Address of the NFT contract
  recipientId: t.hex().notNull(), // Address of the recipient
  tokenId: t.hex().notNull(), // ID of the recovered NFT token
  blockNumber: t.bigint().notNull(), // Block number when recovery occurred
  blockTimestamp: t.bigint().notNull(), // Timestamp of the block
  transactionHash: t.hex().notNull(), // Transaction hash of the recovery event
}));
