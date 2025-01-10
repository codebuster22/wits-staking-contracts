// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {WitsStaking} from "../src/WitsStaking.sol";
import {MockERC721} from "./mocks/MockERC721.sol";
import {MockERC20} from "./mocks/MockERC20.sol";
import {console} from "forge-std/console.sol";
import {AddStakingDuration, RemoveStakingDuration, AddNFTContract, RemoveNFTContract, PauseContract, RecoverETH, RecoverERC20, RecoverERC721} from "../script/WitsStakingAdminFunctions.s.sol";

contract WitsStakingAdminScriptsTest is Test {
    WitsStaking public staking;
    MockERC721 public nft;
    MockERC20 public token;

    address public owner;
    address public recipient;
    string public constant RPC_URL = "https://example.com";
    uint256 public constant PRIVATE_KEY = 123;

    function setUp() public {
        owner = makeAddr("owner");
        recipient = makeAddr("recipient");
        
        // Deploy contracts
        vm.startPrank(owner);
        staking = new WitsStaking(owner);
        nft = new MockERC721("Test NFT", "TNFT");
        token = new MockERC20("Test Token", "TT");
        vm.stopPrank();

    }

    function addressToString(address addr) internal pure returns (string memory) {
        bytes memory s = new bytes(42);
        s[0] = "0";
        s[1] = "x";
        for (uint256 i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint160(addr) / (2**(8*(19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2*i + 2] = char(hi);
            s[2*i + 3] = char(lo);
        }
        return string(s);
    }

    function char(bytes1 b) internal pure returns (bytes1) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }

    function numberToString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    function testAddStakingDurationScript() public {
        uint256 duration = 1 days;
        vm.setEnv("DURATION", numberToString(duration));
        
        // Setup environment variables
        vm.setEnv("STAKING_ADDRESS", addressToString(address(staking)));
        vm.setEnv("OWNER", addressToString(owner));
        vm.setEnv("RPC_URL", RPC_URL);
        vm.setEnv("PRIVATE_KEY", numberToString(PRIVATE_KEY));

        AddStakingDuration script = new AddStakingDuration();
        script.setUp();
        script.run();

        assertTrue(staking.isStakingDurationValid(duration));
    }

    function testRemoveStakingDurationScript() public {
        uint256 duration = 1 days;
        
        // First add the duration
        vm.prank(owner);
        staking.addStakingDuration(duration);
        
        vm.setEnv("DURATION", numberToString(duration));
        
        // Setup environment variables
        vm.setEnv("STAKING_ADDRESS", addressToString(address(staking)));
        vm.setEnv("OWNER", addressToString(owner));
        vm.setEnv("RPC_URL", RPC_URL);
        vm.setEnv("PRIVATE_KEY", numberToString(PRIVATE_KEY));

        RemoveStakingDuration script = new RemoveStakingDuration();
        script.setUp();
        script.run();

        assertFalse(staking.isStakingDurationValid(duration));
    }

    function testAddNFTContractScript() public {
        vm.setEnv("NFT_CONTRACT", addressToString(address(nft)));
        
        // Setup environment variables
        vm.setEnv("STAKING_ADDRESS", addressToString(address(staking)));
        vm.setEnv("OWNER", addressToString(owner));
        vm.setEnv("RPC_URL", RPC_URL);
        vm.setEnv("PRIVATE_KEY", numberToString(PRIVATE_KEY));

        AddNFTContract script = new AddNFTContract();
        script.setUp();
        script.run();

        assertTrue(staking.whitelistedNFTs(address(nft)));
    }

    function testRemoveNFTContractScript() public {
        // First whitelist the NFT
        vm.prank(owner);
        staking.whitelistNFTContract(address(nft));
        
        vm.setEnv("NFT_CONTRACT", addressToString(address(nft)));
        
        // Setup environment variables
        vm.setEnv("STAKING_ADDRESS", addressToString(address(staking)));
        vm.setEnv("OWNER", addressToString(owner));
        vm.setEnv("RPC_URL", RPC_URL);
        vm.setEnv("PRIVATE_KEY", numberToString(PRIVATE_KEY));
        console.log(vm.envAddress("OWNER"));

        RemoveNFTContract script = new RemoveNFTContract();
        script.setUp();
        script.run();

        assertFalse(staking.whitelistedNFTs(address(nft)));
    }

    function testPauseContractScript() public {
        
        // Setup environment variables
        vm.setEnv("STAKING_ADDRESS", addressToString(address(staking)));
        vm.setEnv("OWNER", addressToString(owner));
        vm.setEnv("RPC_URL", RPC_URL);
        vm.setEnv("PRIVATE_KEY", numberToString(PRIVATE_KEY));
        PauseContract script = new PauseContract();
        script.setUp();
        
        // Test pausing
        script.run();
        assertTrue(staking.paused());
        
        // Test unpausing
        script.run();
        assertFalse(staking.paused());
    }

    function testRecoverETHScript() public {
        // Send ETH to staking contract
        vm.deal(address(staking), 1 ether);
        
        vm.setEnv("RECIPIENT", addressToString(recipient));
        vm.setEnv("AMOUNT", "1000000000000000000"); // 1 ether
        
        // Setup environment variables
        vm.setEnv("STAKING_ADDRESS", addressToString(address(staking)));
        vm.setEnv("OWNER", addressToString(owner));
        vm.setEnv("RPC_URL", RPC_URL);
        vm.setEnv("PRIVATE_KEY", numberToString(PRIVATE_KEY));

        RecoverETH script = new RecoverETH();
        script.setUp();
        script.run();

        assertEq(recipient.balance, 1 ether);
        assertEq(address(staking).balance, 0);
    }

    function testRecoverERC20Script() public {
        // Mint tokens to staking contract
        token.mint(address(staking), 1000);
        
        vm.setEnv("TOKEN_ADDRESS", addressToString(address(token)));
        vm.setEnv("RECIPIENT", addressToString(recipient));
        vm.setEnv("AMOUNT", "1000");
        
        // Setup environment variables
        vm.setEnv("STAKING_ADDRESS", addressToString(address(staking)));
        vm.setEnv("OWNER", addressToString(owner));
        vm.setEnv("RPC_URL", RPC_URL);
        vm.setEnv("PRIVATE_KEY", numberToString(PRIVATE_KEY));

        RecoverERC20 script = new RecoverERC20();
        script.setUp();
        script.run();

        assertEq(token.balanceOf(recipient), 1000);
        assertEq(token.balanceOf(address(staking)), 0);
    }

    function testRecoverERC721Script() public {
        // Mint NFT to staking contract
        uint256 tokenId = 1;
        vm.startPrank(owner);
        nft.mint(tokenId);
        nft.transferFrom(owner, address(staking), tokenId);
        vm.stopPrank();
        
        vm.setEnv("TOKEN_ADDRESS", addressToString(address(nft)));
        vm.setEnv("RECIPIENT", addressToString(recipient));
        vm.setEnv("TOKEN_ID", numberToString(tokenId));
        
        // Setup environment variables
        vm.setEnv("STAKING_ADDRESS", addressToString(address(staking)));
        vm.setEnv("OWNER", addressToString(owner));
        vm.setEnv("RPC_URL", RPC_URL);
        vm.setEnv("PRIVATE_KEY", numberToString(PRIVATE_KEY));

        RecoverERC721 script = new RecoverERC721();
        script.setUp();
        script.run();

        assertEq(nft.ownerOf(tokenId), recipient);
    }

    function testScriptFailuresWithInvalidOwner() public {
        address invalidOwner = makeAddr("invalid");
        vm.setEnv("OWNER", addressToString(invalidOwner));
        vm.setEnv("DURATION", "86400");
        
        // Setup environment variables
        vm.setEnv("STAKING_ADDRESS", addressToString(address(staking)));
        vm.setEnv("OWNER", addressToString(owner));
        vm.setEnv("RPC_URL", RPC_URL);
        vm.setEnv("PRIVATE_KEY", numberToString(PRIVATE_KEY));

        AddStakingDuration script = new AddStakingDuration();
        script.setUp();
        
        vm.expectRevert();
        script.run();
    }

    function testScriptFailuresWithInvalidInputs() public {
        // Test with invalid duration
        vm.setEnv("DURATION", numberToString(30 minutes)); // Less than minimum
        
        // Setup environment variables
        vm.setEnv("STAKING_ADDRESS", addressToString(address(staking)));
        vm.setEnv("OWNER", addressToString(owner));
        vm.setEnv("RPC_URL", RPC_URL);
        vm.setEnv("PRIVATE_KEY", numberToString(PRIVATE_KEY));

        AddStakingDuration script = new AddStakingDuration();
        script.setUp();
        
        vm.expectRevert();
        script.run();

        // Test with zero address for NFT contract
        vm.setEnv("NFT_CONTRACT", addressToString(address(0)));

        AddNFTContract script2 = new AddNFTContract();
        script2.setUp();
        
        vm.expectRevert();
        script2.run();
    }
} 