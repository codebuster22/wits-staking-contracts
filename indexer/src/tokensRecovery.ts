import { ponder } from "ponder:registry";
import { erc20TokenRecovered, erc721TokenRecovered, ethRecovered, nft, nftContract, user } from "ponder:schema";
import { generateErc20TokensRecoveredId, generateErc721TokensRecoveredId, generateEthRecoveredId, generateNftContractId, generateNftId, generateUserId } from "./utils";
import { zeroAddress } from "viem";

ponder.on("WitsStaking:ERC20TokensRecovered", async ({event, context}) => {
    const { args, log, transaction, transactionReceipt, block } = event;
    const { db, network, client, contracts } = context;

    // generate ID for ERC20TokensRecovered
    const erc20TokensRecoveredId = generateErc20TokensRecoveredId(args.token, args.amount, log.id);
    const recipientId = generateUserId(args.recipient);
    
    // insert the recipient
    await db.insert(user).values({
        id: recipientId,
        address: args.recipient,
    }).onConflictDoNothing();

    // insert the ERC20TokensRecovered event
    await db.insert(erc20TokenRecovered).values({
        id: erc20TokensRecoveredId,
        tokenContractAddress: args.token,
        recipientId: recipientId,
        amount: args.amount,
        blockNumber: block.number,
        blockTimestamp: block.timestamp,
        transactionHash: transaction.hash
    });
})

ponder.on("WitsStaking:ERC721TokensRecovered", async ({event, context}) => {
    const { args, log, transaction, transactionReceipt, block } = event;
    const { db, network, client, contracts } = context;

    // generate id for ERC721TokensRecovered
    const erc721TokensRecoveredId = generateErc721TokensRecoveredId(args.token, args.tokenId, log.id);
    const recipientId = generateUserId(args.recipient);
    const nftContractId = generateNftContractId(args.token);
    const nftId = generateNftId(args.token, args.tokenId);

    // insert the recipient
    await db.insert(user).values({
        id: recipientId,
        address: args.recipient,
    }).onConflictDoNothing();

    // insert the nftContract
    await db.insert(nftContract).values({
        id: nftContractId,
        contract: args.token,
        isWhitelisted: false,
    }).onConflictDoNothing();

    await db.insert(nft).values({
        id: nftId,
        nftContractId: nftContractId,
        tokenId: args.tokenId,
    }).onConflictDoNothing();

    // insert the ERC721TokensRecovered event
    await db.insert(erc721TokenRecovered).values({
        id: erc721TokensRecoveredId,
        nftContractId: nftContractId,
        recipientId: recipientId,
        nftId: nftId,
        blockNumber: block.number,
        blockTimestamp: block.timestamp,
        transactionHash: transaction.hash,
    });
})

ponder.on("WitsStaking:EthRecovered", async ({event, context}) => {
    const { args, log, transaction, transactionReceipt, block } = event;
    const { db, network, client, contracts } = context;

    // generate id for EthRecovered
    const ethRecoveredId = generateEthRecoveredId(zeroAddress, args.amount, log.id);
    const recipientId = generateUserId(args.recipient);

    // insert the recipient
    await db.insert(user).values({
        id: recipientId,
        address: args.recipient,
    }).onConflictDoNothing();

    // insert the EthRecovered event
    await db.insert(ethRecovered).values({
        id: ethRecoveredId,
        recipientId: recipientId,
        amount: args.amount,
        blockNumber: block.number,
        blockTimestamp: block.timestamp,
        transactionHash: transaction.hash,
    });
})