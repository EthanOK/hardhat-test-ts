// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {MockERC721A} from "./MockERC721A.sol";

contract ERC721ATest is Test {
    address public owner = makeAddr("owner");
    address public alice = makeAddr("alice");
    address public bob = makeAddr("bob");
    address public carol = makeAddr("carol");

    MockERC721A public mockERC721A;

    function setUp() public {
        mockERC721A = new MockERC721A();
        mockERC721A.mint(alice, 10);
        mockERC721A.mint(bob, 10);
        mockERC721A.mint(carol, 10);
    }

    function test_Bob_Transfer_Owner_AscOrder() public {
        vm.startPrank(bob);
        for (uint256 i = 11; i <= 20; i++) {
            mockERC721A.transferFrom(bob, owner, i);
        }

        vm.stopPrank();
    }

    function test_Bob_Transfer_Owner_DescOrder() public {
        vm.startPrank(bob);
        for (uint256 i = 20; i >= 11; i--) {
            mockERC721A.transferFrom(bob, owner, i);
        }
        vm.stopPrank();
    }
}

// forge test --match-contract ERC721ATest -vvv
