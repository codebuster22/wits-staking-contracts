import { ponder } from "ponder:registry";
import { nftStaked, nftUnstaked, stake, user } from "ponder:schema";
import { generateDurationId, generateNftContractId, generateNftId, generateNftStakedId, generateNftUnstakedId, generateStakeId, generateUserId } from "./utils";

ponder.on("WitsStaking:NFTStaked", async ({event, context}) => {
    const { args, log, transaction, transactionReceipt, block } = event;
    const { db, network, client, contracts } = context;
    
    // generate nftContractId, nftId, stakerId, durationId, stakeTxId
    const nftContractId = generateNftContractId(args.nftContract);
    const nftId = generateNftId(args.nftContract, args.tokenId);
    const stakerId = generateUserId(args.staker);
    const durationId = generateDurationId(args.duration);
    const stakeTxId = generateNftStakedId(args.stakeId, log.id);
    const stakeId = generateStakeId(args.stakeId);

    const endTime = block.timestamp + args.duration;

    // insert user
    await db.insert(user).values({
        id: stakerId,
        address: args.staker,
    }).onConflictDoNothing();

    // insert stake
    await db.insert(stake).values({
        id: stakeId,
        nftContractId: nftContractId,
        contractStakeId: args.stakeId,
        nftId: nftId,
        stakerId: stakerId,
        durationId: durationId,
        startTime: block.timestamp,
        endTime: endTime,
        stakeDuration: args.duration,
        isStaked: true,
        stakeTxId: stakeTxId,
    });

    // insert nftStaked
    await db.insert(nftStaked).values({
        id: stakeTxId,
        stakeId: stakeId,
        blockNumber: block.number,
        blockTimestamp: block.timestamp,
        transactionHash: transaction.hash,
    });

})

ponder.on("WitsStaking:NFTUnstaked", async ({event, context}) => {
    const { args, log, transaction, transactionReceipt, block } = event;
    const { db, network, client, contracts } = context;

    // generate stakeId, unstakeTxId
    const unstakeTxId = generateNftUnstakedId(args.stakeId, log.id);
    const stakeId = generateStakeId(args.stakeId);

    // update stake
    await db.update(stake, {id: stakeId}).set({
        isStaked: false,
        unstakeTxId: unstakeTxId,
    });

    // insert nftUnstaked
    await db.insert(nftUnstaked).values({
        id: unstakeTxId,
        stakeId: stakeId,
        blockNumber: block.number,
        blockTimestamp: block.timestamp,
        transactionHash: transaction.hash,
    });

})