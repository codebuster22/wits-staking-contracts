import { ponder } from "ponder:registry";
import { generateNftOwnershipId, generateUserId } from "./utils";
import { nftOwnership, user } from "ponder:schema";

ponder.on("NFTContract:Transfer", async ({event, context}) => {
    const { args, log, transaction, transactionReceipt, block } = event;
    const { db, network, client, contracts } = context;

    const nftOwnershipId = generateNftOwnershipId(args.tokenId);
    const newOwnerId = generateUserId(args.to);

    console.log("newOwnerId", newOwnerId);
    console.log("nftOwnershipId", nftOwnershipId);
    console.log("args.to", args.to);

    // create user if not exists
    await db.insert(user).values({
        id: newOwnerId,
        address: args.to,
    }).onConflictDoNothing();

    // create the nft ownership record
    await db.insert(nftOwnership).values({
        id: nftOwnershipId,
        nftTokenId: args.tokenId,
        ownerId: newOwnerId,
    }).onConflictDoUpdate((row) => {
        return {
            ownerId: newOwnerId
        }
    });
})