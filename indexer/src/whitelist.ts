import { ponder } from "ponder:registry";
import { generateNftContractId, generateNftContractAdditionId, generateNftContractRemovalId } from "./utils";
import { nftContract, nftContractAddition, nftContractRemoval } from "ponder:schema";


ponder.on("WitsStaking:NFTContractWhitelisted", async ({event, context}) => {
    const { args, log, transaction, transactionReceipt, block } = event;
    const { db, network, client, contracts } = context;

    // generate id for nftContract
    const nftContractId = generateNftContractId(args.nftContract);
    const nftContractAdditionId = generateNftContractAdditionId(args.nftContract, log.id);

    // insert the nftContract
    await db.insert(nftContract).values({
        id: nftContractId,
        contract: args.nftContract,
        isWhitelisted: true,
    }).onConflictDoNothing();

    // insert the nftContractWhitelisted event
    await db.insert(nftContractAddition).values({
        id: nftContractAdditionId,
        nftContractId: nftContractId,
        blockNumber: block.number,
        blockTimestamp: block.timestamp,
        transactionHash: transaction.hash,
    });
})

ponder.on("WitsStaking:NFTContractRemoved", async ({event, context}) => {
    const { args, log, transaction, transactionReceipt, block } = event;
    const { db, network, client, contracts } = context;

    // generate id for nftContract
    const nftContractId = generateNftContractId(args.nftContract);
    const nftContractRemovalId = generateNftContractRemovalId(args.nftContract, log.id);
    // update the nftContract
    await db.update(nftContract, {id: nftContractId}).set({
        isWhitelisted: false,
    });

    // insert the nftContractRemoved event
    await db.insert(nftContractRemoval).values({
        id: nftContractRemovalId,
        nftContractId: nftContractId,
        blockNumber: block.number,
        blockTimestamp: block.timestamp,
        transactionHash: transaction.hash,
    });
})