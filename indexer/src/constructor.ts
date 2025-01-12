import { ponder } from "ponder:registry";
import { globalState, user } from "ponder:schema";
import { generateGlobalStateId, generateUserId } from "./utils";

ponder.on("WitsStaking:setup", async ({context}) => {
  const { db, network, client, contracts } = context;

  const results = await client.multicall({
    contracts: [
        {
            address: contracts.WitsStaking.address,
            abi: contracts.WitsStaking.abi,
            functionName: "MIN_STAKE_DURATION",
        },
        {
            address: contracts.WitsStaking.address,
            abi: contracts.WitsStaking.abi,
            functionName: "MAX_STAKE_DURATION",
        },
        {
            address: contracts.WitsStaking.address,
            abi: contracts.WitsStaking.abi,
            functionName: "owner",
        },
    ]
  });

  if (results[0].status === "failure" || results[1].status === "failure" || results[2].status === "failure") {
    throw new Error("Failed to fetch global state");
    return;
  }

  const minDuration = results[0].result;
  const maxDuration = results[1].result;
  const owner = results[2].result;

  const ownerId = generateUserId(owner);

  const globalStateId = generateGlobalStateId(contracts.WitsStaking.address);

  await db.insert(user).values({
    id: ownerId,
    address: owner,
  });

  await db.insert(globalState).values({
    id: globalStateId,
    isPaused: false,
    minStakeDuration: minDuration,
    maxStakeDuration: maxDuration,
    ownerId: ownerId,
  })
})