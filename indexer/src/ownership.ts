import { ponder } from "ponder:registry";
import { generateGlobalStateId, generateUserId } from "./utils";
import { globalState, user } from "ponder:schema";

ponder.on("WitsStaking:OwnershipTransferred", async ({event, context}) => {
    const { args, log, transaction, transactionReceipt, block } = event;
    const { db, network, client, contracts } = context;

    const globalStateId = generateGlobalStateId(contracts.WitsStaking.address);

    const ownerId = generateUserId(args.newOwner);

    await db.insert(user).values({
        id: ownerId,
        address: args.newOwner,
    }).onConflictDoNothing();

    await db.update(globalState, {id: globalStateId}).set({
        ownerId: ownerId,
    });

})