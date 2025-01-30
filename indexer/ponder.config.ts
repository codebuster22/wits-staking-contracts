import { createConfig } from "ponder";
import { erc721Abi, http } from "viem";

import { WitsStakingAbi } from "./abis/WitsStaking";
import { abstract, abstractTestnet } from "viem/chains";

const witsStakingAddress = process.env.PONDER_WITS_STAKING_ADDRESS;
const nftContractAddress = process.env.PONDER_NFT_CONTRACT_ADDRESS;
const witsStakingStartBlock = process.env.PONDER_WITS_STAKING_START_BLOCK;
const network = process.env.PONDER_NETWORK;

if (!witsStakingAddress) {
  throw new Error("PONDER_WITS_STAKING_ADDRESS is not set");
}

if (!nftContractAddress) {
  throw new Error("PONDER_NFT_CONTRACT_ADDRESS is not set");
}

if (!witsStakingStartBlock) {
  throw new Error("PONDER_WITS_STAKING_START_BLOCK is not set");
}

if (!network) {
  throw new Error("PONDER_NETWORK is not set");
}

export default createConfig({
  networks: {
    abstractTestnet: {
      chainId: abstractTestnet.id,
      transport: http(process.env.PONDER_RPC_URL_ABSTRACT_TESTNET),
    },
    abstractMainnet: {
      chainId: abstract.id,
      transport: http(process.env.PONDER_RPC_URL_ABSTRACT_MAINNET),
    },
    anvil: {
      chainId: 260,
      transport: http(process.env.PONDER_RPC_URL_ANVIL)
    },
  },
  contracts: {
    WitsStaking: {
      network: network as "abstractTestnet" | "abstractMainnet" | "anvil",
      abi: WitsStakingAbi,
      address: witsStakingAddress as `0x${string}`,
      startBlock: parseInt(witsStakingStartBlock),
    },
    NFTContract: {
      network: network as "abstractTestnet" | "abstractMainnet" | "anvil",
      abi: erc721Abi,
      address: nftContractAddress as `0x${string}`,
      startBlock: parseInt(witsStakingStartBlock),
    }
  }
});
