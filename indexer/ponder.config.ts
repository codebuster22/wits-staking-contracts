import { createConfig } from "ponder";
import { http } from "viem";

import { WitsStakingAbi } from "./abis/WitsStaking";
import { abstractTestnet } from "viem/chains";

const witsStakingAddress = process.env.PONDER_WITS_STAKING_ADDRESS;
const witsStakingStartBlock = process.env.PONDER_WITS_STAKING_START_BLOCK;

if (!witsStakingAddress) {
  throw new Error("PONDER_WITS_STAKING_ADDRESS is not set");
}

if (!witsStakingStartBlock) {
  throw new Error("PONDER_WITS_STAKING_START_BLOCK is not set");
}

export default createConfig({
  networks: {
    abstractTestnet: {
      chainId: abstractTestnet.id,
      transport: http(process.env.PONDER_RPC_URL_ABSTRACT_TESTNET),
    },
    anvil: {
      chainId: 260,
      transport: http(process.env.PONDER_RPC_URL_ANVIL),
    },
  },
  contracts: {
    WitsStaking: {
      network: "anvil",
      abi: WitsStakingAbi,
      address: witsStakingAddress as `0x${string}`,
      startBlock: parseInt(witsStakingStartBlock),
    },
  },
});
