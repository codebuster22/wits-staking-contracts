import { ponder } from "ponder:registry";
import { generateContractPauseToggleId, generateGlobalStateId } from "./utils";
import { contractPauseToggle, globalState } from "ponder:schema";

ponder.on("WitsStaking:Paused", async ({event, context}) => {
    const { args, log, transaction, transactionReceipt, block } = event;
    const { db, network, client, contracts } = context;

    // generate id for global state and contract pause toggle
    const globalStateId = generateGlobalStateId(contracts.WitsStaking.address);
    const contractPauseToggleId = generateContractPauseToggleId(log.id);

    // update the pause state in the global state
    await db.update(globalState, {id: globalStateId}).set({
        isPaused: true,
    });

    // insert the contract pause toggle event
    await db.insert(contractPauseToggle).values({
        id: contractPauseToggleId,
        isPaused: true,
        blockNumber: block.number,
        blockTimestamp: block.timestamp,
        transactionHash: transaction.hash,
    });

})

ponder.on("WitsStaking:Unpaused", async ({event, context}) => {
    const { args, log, transaction, transactionReceipt, block } = event;
    const { db, network, client, contracts } = context;

    const globalStateId = generateGlobalStateId(contracts.WitsStaking.address);
    const contractPauseToggleId = generateContractPauseToggleId(log.id);

    await db.update(globalState, {id: globalStateId}).set({
        isPaused: false,
    });

    await db.insert(contractPauseToggle).values({
        id: contractPauseToggleId,
        isPaused: false,
        blockNumber: block.number,
        blockTimestamp: block.timestamp,
        transactionHash: transaction.hash,
    });
})