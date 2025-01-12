import { ponder } from "ponder:registry";
import { generateDurationId, generateDurationRemovalId, generateDurationAdditionId } from "./utils";
import { stakeDuration, stakingDurationAddition, stakingDurationRemoval } from "ponder:schema";

ponder.on("WitsStaking:StakingDurationAdded", async ({event, context}) => {
    const { args, log, transaction, transactionReceipt, block } = event;
    const { db, network, client, contracts } = context;

    const durationId = generateDurationId(args.duration);
    const durationAdditionId = generateDurationAdditionId(args.duration, log.id);
    await db.insert(stakeDuration).values({
        id: durationId,
        duration: args.duration,
        isActive: true,
    }).onConflictDoNothing();

    await db.insert(stakingDurationAddition).values({
        id: durationAdditionId,
        durationId: durationId,
        blockNumber: block.number,
        blockTimestamp: block.timestamp,
        transactionHash: transaction.hash,
    });
})

ponder.on("WitsStaking:StakingDurationRemoved", async ({event, context}) => {
    const { args, log, transaction, transactionReceipt, block } = event;
    const { db, network, client, contracts } = context;

    const durationId = generateDurationId(args.duration);
    const durationRemovalId = generateDurationRemovalId(args.duration, log.id);

    await db.update(stakeDuration, {
        id: durationId,
    }).set({
        isActive: false,
    });

    await db.insert(stakingDurationRemoval).values({
        id: durationRemovalId,
        durationId: durationId,
        blockNumber: block.number,
        blockTimestamp: block.timestamp,
        transactionHash: transaction.hash,
    });
})