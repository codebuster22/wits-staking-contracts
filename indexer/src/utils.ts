import { keccak256, toHex } from "viem";


export const generateGlobalStateId = (address: `0x${string}`) => {
    return keccak256(toHex(`global_state_${address.toLowerCase()}`));
  }
  
  export const generateUserId = (address: `0x${string}`) => {
    return keccak256(toHex(`user_${address.toLowerCase()}`));
  }
  
  export const generateNftId = (address: `0x${string}`, tokenId: bigint) => {
    return keccak256(toHex(`nft_${address.toLowerCase()}_${tokenId}`));
  }

  export const generateDurationId = (duration: bigint) => {
    return keccak256(toHex(`duration_${duration}`));
  }

  export const generateContractPauseToggleId = (logId: string) => {
    return keccak256(toHex(`contract_pause_toggle_${logId.toLowerCase()}`));
  }

  export const generateNftContractId = (address: `0x${string}`) => {
    return keccak256(toHex(`nft_contract_${address.toLowerCase()}`));
  }

  export const generateErc20TokensRecoveredId = (token: `0x${string}`, amount: bigint, logId: string) => {
    return keccak256(toHex(`erc20_tokens_recovered_${token.toLowerCase()}_${amount}_${logId.toLowerCase()}`));
  }

  export const generateErc721TokensRecoveredId = (token: `0x${string}`, tokenId: bigint, logId: string) => {
    return keccak256(toHex(`erc721_tokens_recovered_${token.toLowerCase()}_${tokenId}_${logId.toLowerCase()}`));
  }

  export const generateEthRecoveredId = (token: `0x${string}`, amount: bigint, logId: string) => {
    return keccak256(toHex(`eth_recovered_${token.toLowerCase()}_${amount}_${logId.toLowerCase()}`));
  }

  export const generateDurationRemovalId = (duration: bigint, logId: string) => {
    return keccak256(toHex(`duration_removal_${duration}_${logId.toLowerCase()}`));
  }

  export const generateDurationAdditionId = (duration: bigint, logId: string) => {
    return keccak256(toHex(`duration_addition_${duration}_${logId.toLowerCase()}`));
  }

  export const generateNftContractAdditionId = (nftContract: `0x${string}`, logId: string) => {
    return keccak256(toHex(`nft_contract_addition_${nftContract.toLowerCase()}_${logId.toLowerCase()}`));
  }

  export const generateNftContractRemovalId = (nftContract: `0x${string}`, logId: string) => {
    return keccak256(toHex(`nft_contract_removal_${nftContract.toLowerCase()}_${logId.toLowerCase()}`));
  }

  export const generateNftStakedId = (stakeId: bigint, logId: string) => {
    return keccak256(toHex(`nft_staked_${stakeId}_${logId.toLowerCase()}`));
  }

  export const generateNftUnstakedId = (stakeId: bigint, logId: string) => {
    return keccak256(toHex(`nft_unstaked_${stakeId}_${logId.toLowerCase()}`));
  }
  
  export const generateStakeId = (stakeId: bigint) => {
    return keccak256(toHex(`stake_${stakeId}`));
  }
